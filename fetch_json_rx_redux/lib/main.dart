import 'package:fetch_json_rx_redux/api.dart';
import 'package:fetch_json_rx_redux/home/home_bloc.dart';
import 'package:fetch_json_rx_redux/home/home_effects.dart';
import 'package:fetch_json_rx_redux/home/home_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:http/http.dart' as http;

void main() {
  final api = Api(http.Client());
  final homeBloc = HomeBloc(HomeEffects(api))..fetch();

  runApp(
    BlocProvider<HomeBloc>(
      child: MyApp(),
      initBloc: () => homeBloc,
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fetch json BLoC RxDart',
      theme: ThemeData.dark(),
      home: const MyHomePage(),
    );
  }
}
