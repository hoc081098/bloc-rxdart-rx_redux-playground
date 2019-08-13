import 'dart:async';

import 'package:disposebag/disposebag.dart';
import 'package:distinct_value_connectable_observable/distinct_value_connectable_observable.dart';
import 'package:fetch_json_rx_redux/home/home_effects.dart';
import 'package:fetch_json_rx_redux/home/home_state_action.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:meta/meta.dart';
import 'package:rx_redux/rx_redux.dart';
import 'package:rxdart/rxdart.dart';

/// Home BLoC
class HomeBloc implements BaseBloc {
  /// Output
  final ValueObservable<HomeState> state$;
  final Stream<HomeMessage> message$;

  /// Input
  final void Function() fetch;
  final Future<void> Function() refresh;

  /// Dispose
  final void Function() _dispose;

  @override
  void dispose() => _dispose();

  HomeBloc._(
    this._dispose, {
    @required this.state$,
    @required this.fetch,
    @required this.refresh,
    @required this.message$,
  });

  factory HomeBloc(final HomeEffects effects) {
    // ignore_for_file: close_sinks
    final actionS = PublishSubject<HomeAction>();

    final state$ = actionS.transform(
      ReduxStoreStreamTransformer<HomeAction, HomeState>(
        initialStateSupplier: () => HomeState.initial(),
        reducer: (state, action) => action.reduce(state),
        sideEffects: [
          effects.fetchEffect,
          effects.refreshEffect,
        ],
      ),
    );
    final stateDistinct$ = publishValueSeededDistinct(
      state$,
      seedValue: HomeState.initial(),
    );

    /// Subscriptions & sinks
    final bag = DisposeBag([
      //subscriptions
      stateDistinct$.listen((state) => print('[HOME_BLOC] state=$state')),
      effects.message$
          .listen((message) => print('[HOME_BLOC] message=$message')),
      stateDistinct$.connect(),
      //sinks
      actionS,
      effects.messageSink,
    ]);

    return HomeBloc._(
      bag.dispose,
      state$: stateDistinct$,
      fetch: () => actionS.add(const FetchUsersAction()),
      refresh: () {
        final completer = Completer<void>();
        actionS.add(RefreshAction(completer));
        return completer.future;
      },
      message$: effects.message$,
    );
  }
}
