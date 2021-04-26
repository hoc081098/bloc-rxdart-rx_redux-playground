import 'dart:async';

import 'package:distinct_value_connectable_stream/distinct_value_connectable_stream.dart';
import 'package:fetch_json_rx_redux/home/home_effects.dart';
import 'package:fetch_json_rx_redux/home/home_state_action.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:rx_redux/rx_redux.dart';
import 'package:rxdart_ext/rxdart_ext.dart';

/// Home BLoC
class HomeBloc extends DisposeCallbackBaseBloc {
  /// Output
  final DistinctValueStream<HomeState> state$;
  final Stream<HomeMessage> message$;

  /// Input
  final void Function() fetch;
  final Future<void> Function() refresh;

  HomeBloc._({
    required VoidAction dispose,
    required this.state$,
    required this.fetch,
    required this.refresh,
    required this.message$,
  }) : super(dispose);

  factory HomeBloc(final HomeEffects effects) {
    final store = RxReduxStore<HomeAction, HomeState>(
      initialState: HomeState.initial(),
      reducer: (state, action) => action.reduce(state),
      sideEffects: [
        effects.fetchEffect,
        effects.refreshEffect,
      ],
      logger: rxReduxDefaultLogger,
    );

    final message$ = store.actionStream.mapNotNull((a) {
      if (a is GetUsersSuccessChange && a.refresh) {
        return const RefreshSuccessMessage();
      }
      if (a is GetUsersErrorChange) {
        return a.refresh
            ? RefreshFailureMessage(a.error)
            : GetUsersErrorMessage(a.error);
      }
      return null;
    });

    return HomeBloc._(
      dispose: store.dispose,
      state$: store.stateStream,
      fetch: () => store.dispatch(const FetchUsersAction()),
      refresh: () {
        final completer = Completer<void>.sync();
        store.dispatch(RefreshAction(completer));
        return completer.future;
      },
      message$: message$,
    );
  }
}
