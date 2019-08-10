import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:flutter_change_theme/generated/i18n.dart';
import 'package:flutter_change_theme/theme_locale_bloc.dart';
import 'package:flutter_change_theme/theme_model.dart';
import 'package:flutter_change_theme/theme_locale_provider.dart';
import 'package:flutter_provider/flutter_provider.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  print("Running...");

  // Dependencies
  final themesProvider = ThemesLocalesProvider();
  final rxSharedPrefs = RxSharedPreferences(SharedPreferences.getInstance());
  final themeLocaleBloc = ThemeLocaleBloc(themesProvider, rxSharedPrefs);

  runApp(
    Provider<ThemesLocalesProvider>(
      value: themesProvider,
      child: BlocProvider<ThemeLocaleBloc>(
        child: MyApp(),
        initBloc: () => themeLocaleBloc,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<ThemeLocaleBloc>(context);

    return RxStreamBuilder<Tuple2<ThemeModel, Locale>>(
      stream: bloc.themeAndLocale$,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: double.infinity,
            height: double.infinity,
          );
        }

        final enLocale = Provider.of<ThemesLocalesProvider>(context)
            .findLocaleByLanguageCode('en');

        return MaterialApp(
          title: 'Flutter change theme',
          theme: snapshot.data.item1.themeData,
          locale: snapshot.data.item2,
          supportedLocales: S.delegate.supportedLocales,
          localeResolutionCallback: S.delegate.resolution(fallback: enLocale),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          home: const MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<String> _subscription;

  showSnackBar(String message) {
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _subscription ??=
        BlocProvider.of<ThemeLocaleBloc>(context).message$.map((message) {
      final s = S.of(context);
      if (message is ChangeThemeSuccess) {
        return s.change_theme_success;
      }
      if (message is ChangeThemeFailure) {
        if (message.error != null) {
          return s.change_theme_failure_cause_by(message.error.toString());
        } else {
          return s.change_theme_failure;
        }
      }
      if (message is ChangeLocaleSuccess) {
        return s.change_language_success;
      }
      if (message is ChangeLocaleFailure) {
        if (message.error != null) {
          return s.change_language_failure_cause_by(message.error.toString());
        } else {
          return s.change_language_failure;
        }
      }
      return null;
    }).listen(showSnackBar);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<ThemeLocaleBloc>(context);
    final s = S.of(context);
    final provider = Provider.of<ThemesLocalesProvider>(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Home page'),
      ),
      body: RxStreamBuilder<Tuple2<ThemeModel, Locale>>(
        stream: bloc.themeAndLocale$,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final theme = data.item1;
          final locale = data.item2;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).canvasColor,
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(0, 8),
                      blurRadius: 16,
                      spreadRadius: 0,
                      color: Theme.of(context).backgroundColor,
                    )
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    Center(
                      child: LocalePopupMenu(
                        locale: locale,
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: ThemePopupMenu(
                        themeModel: theme,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).canvasColor,
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(0, 8),
                      blurRadius: 16,
                      spreadRadius: 0,
                      color: Theme.of(context).backgroundColor,
                    )
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      s.current_theme_is(
                        theme.themeTitle(s),
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .title
                          .copyWith(fontSize: 15),
                    ),
                    SizedBox(height: 12),
                    Text(
                      s.current_language_is(
                        provider.getLanguageNameStringByLanguageCode(
                          locale.languageCode,
                        ),
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .title
                          .copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ThemePopupMenu extends StatelessWidget {
  const ThemePopupMenu({
    Key key,
    @required this.themeModel,
  }) : super(key: key);

  final ThemeModel themeModel;

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<ThemeLocaleBloc>(context);
    final s = S.of(context);
    final provider = Provider.of<ThemesLocalesProvider>(context);

    return PopupMenuButton<ThemeModel>(
      initialValue: themeModel,
      onSelected: bloc.changeTheme,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              themeModel.themeTitle(s),
              style: Theme.of(context).textTheme.title,
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return provider.themes.map((theme) {
          return PopupMenuItem<ThemeModel>(
            child: Text(theme.themeTitle(s)),
            value: theme,
          );
        }).toList(growable: false);
      },
    );
  }
}

class LocalePopupMenu extends StatelessWidget {
  const LocalePopupMenu({
    Key key,
    @required this.locale,
  }) : super(key: key);

  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<ThemeLocaleBloc>(context);
    final provider = Provider.of<ThemesLocalesProvider>(context);

    return PopupMenuButton<Locale>(
      initialValue: locale,
      onSelected: bloc.changeLocale,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              provider.getLanguageNameStringByLanguageCode(locale.languageCode),
              style: Theme.of(context).textTheme.title,
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return provider.supportedLocales.map((locale) {
          return PopupMenuItem<Locale>(
            child: Text(
              provider.getLanguageNameStringByLanguageCode(locale.languageCode),
            ),
            value: locale,
          );
        }).toList(growable: false);
      },
    );
  }
}
