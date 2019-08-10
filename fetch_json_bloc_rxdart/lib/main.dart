import 'dart:async';
import 'dart:io';

import 'package:fetch_json_bloc_rxdart/api.dart';
import 'package:fetch_json_bloc_rxdart/home_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';

void main() {
  final api = Api(http.Client());
  final homeBloc = HomeBloc(api)..fetch();

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

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<HomeMessage> _subscription;

  _showSnackBar(String msg) {
    _scaffoldKey.currentState.showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _subscription ??=
        BlocProvider.of<HomeBloc>(context).message$.listen((message) {
      if (message is RefreshSuccessMessage) {
        _showSnackBar('Refresh success');
      }
      if (message is RefreshFailureMessage) {
        _showSnackBar('Refresh not success');
      }
      if (message is GetUsersErrorMessage) {
        _showSnackBar('Get users error');
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<HomeBloc>(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Fetch json BLoC RxDart'),
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        child: RxStreamBuilder<HomeState>(
          stream: bloc.state$,
          builder: (context, snapshot) {
            final child = () {
              final state = snapshot.data;
              if (state.isLoading) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (state.error != null) {
                return ErrorMessageWidget(
                  error: state.error,
                );
              }
              return RefreshIndicator(
                child: ListView.builder(
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount: state.users.length,
                  itemBuilder: (context, index) =>
                      ListItemWidget(user: state.users[index]),
                ),
                onRefresh: bloc.refresh,
              );
            }();

            return AnimatedSwitcher(
              duration: const Duration(seconds: 2),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class ErrorMessageWidget extends StatelessWidget {
  const ErrorMessageWidget({
    Key key,
    @required this.error,
  })  : assert(error != null),
        super(key: key);

  final error;

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<HomeBloc>(context);
    final message = () {
      if (error is SocketException) {
        return 'Network error';
      }
      if (error is HttpException) {
        return error.message;
      }
      return error.toString();
    }();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Error: $message',
              maxLines: 2,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.title.copyWith(fontSize: 18),
            ),
            SizedBox(height: 16),
            RaisedButton(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(24),
              child: Text('Retry get users'),
              onPressed: bloc.fetch,
            ),
          ],
        ),
      ),
    );
  }
}

class ListItemWidget extends StatelessWidget {
  const ListItemWidget({
    Key key,
    @required this.user,
  }) : super(key: key);

  final User user;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: Offset(0, 4),
            color: Colors.grey.shade600,
          )
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
              BoxShadow(
                  blurRadius: 10,
                  offset: Offset(2, 2),
                  color: Colors.grey.shade500,
                  spreadRadius: 1)
            ]),
            child: ClipOval(
              child: Image.network(
                user.avatar,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(
            width: 16,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '${user.firstName} ${user.lastName}',
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.title,
                ),
                SizedBox(
                  height: 8,
                ),
                Text(
                  user.email,
                  textAlign: TextAlign.left,
                  style: Theme.of(context).textTheme.subtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
