import 'dart:async';
import 'dart:ui';

import 'package:distinct_value_connectable_observable/distinct_value_connectable_observable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:flutter_change_theme/theme_model.dart';
import 'package:flutter_change_theme/theme_locale_provider.dart';
import 'package:meta/meta.dart';
import 'package:rx_shared_preference/rx_shared_preference.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

///
/// Change theme message
///
abstract class ChangeThemeMessage {}

class ChangeThemeSuccess implements ChangeThemeMessage {
  const ChangeThemeSuccess();
}

class ChangeThemeFailure implements ChangeThemeMessage {
  /// Nullable
  final error;

  const ChangeThemeFailure([this.error]);
}

///
/// Theme locale bloc
///
class ThemeLocaleBloc implements BaseBloc {
  static const _themeKey = 'com.hoc.flutter_change_theme.theme';
  static const _localeKey = 'com.hoc.flutter_change_theme.locale';

  ///
  /// Input
  ///
  final void Function(ThemeModel) changeTheme;
  final void Function(Locale) changeLocale;

  ///
  /// Output
  ///
  final ValueObservable<Tuple2<ThemeModel, Locale>> themeAndLocale$;

  ///
  /// Dispose
  ///
  final void Function() _dispose;

  @override
  void dispose() => _dispose();

  ThemeLocaleBloc._(
    this._dispose, {
    @required this.changeTheme,
    @required this.changeLocale,
    @required this.themeAndLocale$,
  });

  factory ThemeLocaleBloc(
    ThemesLocalesProvider provider,
    RxSharedPreferences rxSharedPrefs,
  ) {
    // ignore_for_file: close_sinks
    ///
    /// Subjects
    ///
    final changeThemeSubject = PublishSubject<ThemeModel>();
    final changeLocaleSubject = PublishSubject<Locale>();

    ///
    /// Combine stream
    ///
    final Observable<ThemeModel> theme$ =
        rxSharedPrefs.getStringObservable(_themeKey).map(
      (title) {
        return title != null
            ? provider.findThemeByTitle(title)
            : provider.themes[0];
      },
    );
    final Observable<Locale> locale$ =
        rxSharedPrefs.getStringObservable(_localeKey).map(
      (code) {
        return code != null
            ? provider.findLocaleByLanguageCode(code)
            : provider.supportedLocales[0];
      },
    );
    final themeAndLocale$ = publishValueDistinct(
      Observable.combineLatest2(
        theme$,
        locale$,
        (ThemeModel theme, Locale locale) => Tuple2(theme, locale),
      ),
    );

    ///
    /// Persist theme and locale to shared pref
    ///
    Stream<ChangeThemeMessage> changeTheme(ThemeModel theme) async* {
      try {
        final result = await rxSharedPrefs.setString(
          _themeKey,
          theme.themeId,
        );
        if (result) {
          yield const ChangeThemeSuccess();
        } else {
          yield const ChangeThemeFailure();
        }
      } catch (e) {
        yield ChangeThemeFailure(e);
      }
    }

    changeLocale(Locale locale) async* {
      try {
        yield await rxSharedPrefs.setString(
          _localeKey,
          locale.languageCode,
        );
      } catch (e) {
        yield false;
      }
    }

    final message$ =
        changeThemeSubject.distinct().switchMap(changeTheme).publish();

    ///
    /// Stream subscriptions
    ///
    final subscriptions = [
      ///
      /// Listen streams
      ///
      message$.listen((message) => print('[THEME_BLOC] message=$message')),
      themeAndLocale$.listen(
        (tuple) => print(
          '[THEME_BLOC] theme=${tuple.item1.themeId}, locale=${tuple.item2}',
        ),
      ),
      changeLocaleSubject
          .distinct()
          .switchMap(changeLocale)
          .listen((result) => print('[THEME_BLOC] change locale=$result')),

      ///
      /// Connect [ConnectableObservable]
      ///
      message$.connect(),
      themeAndLocale$.connect(),
    ];

    return ThemeLocaleBloc._(
      () async {
        await Future.wait(subscriptions.map((s) => s.cancel()));
        await Future.wait([
          changeLocaleSubject,
          changeThemeSubject,
        ].map((c) => c.close()));
      },
      changeLocale: changeLocaleSubject.add,
      changeTheme: changeThemeSubject.add,
      themeAndLocale$: themeAndLocale$,
    );
  }
}