import 'package:fetch_json_rx_redux/api.dart';
import 'package:fetch_json_rx_redux/home/home_state_action.dart';
import 'package:rx_redux/rx_redux.dart';
import 'package:rxdart/rxdart.dart';

class HomeEffects {
  final SideEffect<HomeAction, HomeState> fetchEffect;
  final SideEffect<HomeAction, HomeState> refreshEffect;

  HomeEffects._(
    this.fetchEffect,
    this.refreshEffect,
  );

  factory HomeEffects(final Api api) {
    final SideEffect<HomeAction, HomeState> refreshEffect = (action$, _) =>
        action$
            .whereType<RefreshAction>()
            .throttleTime(const Duration(milliseconds: 600))
            .exhaustMap((action) => Rx.fromCallable(api.getUsers)
                .map<HomeAction>((users) => GetUsersSuccessChange(users, true))
                .onErrorReturnWith((e) => GetUsersErrorChange(e, true))
                .doOnCancel(() => action.completer.complete()));

    final SideEffect<HomeAction, HomeState> fetchEffect = (action$, _) =>
        action$.whereType<FetchUsersAction>().exhaustMap((_) =>
            Rx.fromCallable(api.getUsers)
                .map<HomeAction>((users) => GetUsersSuccessChange(users, false))
                .startWith(const LoadingChange())
                .onErrorReturnWith((e) => GetUsersErrorChange(e, false)));

    return HomeEffects._(fetchEffect, refreshEffect);
  }
}
