import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:flutter_provider/flutter_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rx_shared_preference/rx_shared_preference.dart';
import 'package:distinct_value_connectable_observable/distinct_value_connectable_observable.dart';
import 'package:tuple/tuple.dart';
import 'package:shared_preferences/shared_preferences.dart';

const themeKey = 'com.hoc.flutter_change_theme.theme';

void main() {
  final themesProvider = ThemesProvider();
  final rxSharedPrefs = RxSharedPreferences(SharedPreferences.getInstance());
  final themeBloc = ThemeBloc(themesProvider, rxSharedPrefs);

  runApp(
    Provider<ThemesProvider>(
      value: themesProvider,
      child: BlocProvider<ThemeBloc>(
        child: MyApp(),
        initBloc: () => themeBloc,
      ),
    ),
  );
}

class ThemeModel {
  final ThemeData themeData;
  final String themeTitle;

  const ThemeModel(this.themeData, this.themeTitle);

  @override
  String toString() => 'ThemeModel(themeTitle=$themeTitle)';
}

class ThemesProvider {
  final List<ThemeModel> themes;
  final ThemeModel Function(String) findThemeByTitle;

  ThemesProvider._(this.themes, this.findThemeByTitle);

  factory ThemesProvider() {
    final themes = <ThemeModel>[
      ThemeModel(ThemeData.dark(), 'Dark theme'),
      ThemeModel(ThemeData.light(), 'Light theme'),
    ];
    return ThemesProvider._(
      themes,
      (title) => themes.firstWhere((theme) => theme.themeTitle == title),
    );
  }
}

class ThemeBloc implements BaseBloc {
  final Future<bool> Function(ThemeModel) changeTheme;
  final ValueObservable<ThemeModel> theme$;
  final void Function() _dispose;

  ThemeBloc._(
    this.changeTheme,
    this.theme$,
    this._dispose,
  );

  @override
  void dispose() => _dispose();

  factory ThemeBloc(
    ThemesProvider themesProvider,
    RxSharedPreferences rxSharedPrefs,
  ) {
    final changeThemeSubject =
        PublishSubject<Tuple2<Completer<bool>, ThemeModel>>();

    final theme$ = rxSharedPrefs.getStringObservable(themeKey).map((title) {
      return title != null
          ? themesProvider.findThemeByTitle(title)
          : themesProvider.themes[0];
    });

    final themeEquals = (ThemeModel prev, ThemeModel next) =>
        prev?.themeTitle == next?.themeTitle;

    final themeDistinct$ = publishValueDistinct<ThemeModel>(
      theme$,
      equals: themeEquals,
    );

    changeTheme(Tuple2<Completer<bool>, ThemeModel> tuple2) async* {
      final result =
          await rxSharedPrefs.setString(themeKey, tuple2.item2.themeTitle);
      tuple2.item1.complete(result);
      yield result;
    }

    final subscriptions = [
      changeThemeSubject
          .distinct((prev, next) => themeEquals(prev.item2, next.item2))
          .switchMap(changeTheme)
          .listen((result) => print('[CHANGE_THEME] $result')),
      themeDistinct$.listen((theme) => print('[THEME] $theme')),
      themeDistinct$.connect(),
    ];

    return ThemeBloc._(
      (theme) {
        final completer = Completer<bool>();
        changeThemeSubject.add(Tuple2(completer, theme));
        return completer.future;
      },
      themeDistinct$,
      () async {
        await Future.wait(subscriptions.map((s) => s.cancel()));
        await changeThemeSubject.close();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<ThemeBloc>(context);

    return StreamBuilder<ThemeModel>(
      stream: bloc.theme$,
      initialData: bloc.theme$.value,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: double.infinity,
            height: double.infinity,
          );
        }
        return MaterialApp(
          title: 'Flutter change theme',
          theme: snapshot.data.themeData,
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
  int _counter = 0;

  void _incrementCounter() {
    setState(() => _counter++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
            Consumer<ThemesProvider>(
              builder: (BuildContext context, ThemesProvider t) {
                final bloc = BlocProvider.of<ThemeBloc>(context);

                return Column(
                  children: <Widget>[
                    Text(
                      t.themes.toString(),
                      textAlign: TextAlign.center,
                    ),
                    FlatButton(
                      child: Text('Dark theme'),
                      onPressed: () => bloc.changeTheme(t.themes[0]),
                    ),
                    FlatButton(
                      child: Text('Light theme'),
                      onPressed: () => bloc.changeTheme(t.themes[1]),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
