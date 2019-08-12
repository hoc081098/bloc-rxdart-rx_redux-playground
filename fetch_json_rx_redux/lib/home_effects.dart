import 'package:fetch_json_rx_redux/api.dart';
import 'package:fetch_json_rx_redux/home_state_action.dart';
import 'package:rx_redux/rx_redux.dart';
import 'package:rxdart/rxdart.dart';

class HomeEffects {
  final Sink<HomeMessage> messageSink;
  final Stream<HomeMessage> message$;
  final SideEffect<HomeState, HomeAction> fetchEffect;
  final SideEffect<HomeState, HomeAction> refreshEffect;

  HomeEffects._(
    this.message$,
    this.fetchEffect,
    this.refreshEffect,
    this.messageSink,
  );

  factory HomeEffects(final Api api) {
    // ignore_for_file: close_sinks
    final messageS = PublishSubject<HomeMessage>();

    final SideEffect<HomeState, HomeAction> refreshEffect = (action$, _) {
      return action$
          .ofType(TypeToken<RefreshAction>())
          .throttleTime(const Duration(milliseconds: 600))
          .exhaustMap((action) {
        return Observable.defer(() => Observable.fromFuture(api.getUsers()))
            .map<HomeAction>((users) => GetUsersSuccessChange(users))
            .doOnError((e, s) => messageS.add(RefreshFailureMessage(e)))
            .doOnData((_) => messageS.add(const RefreshSuccessMessage()))
            .onErrorResumeNext(Stream.empty())
            .doOnDone(() => action.completer.complete());
      });
    };
    final SideEffect<HomeState, HomeAction> fetchEffect = (action$, _) {
      return action$.ofType(TypeToken<FetchUsersAction>()).exhaustMap((_) {
        return Observable.defer(() => Stream.fromFuture(api.getUsers()))
            .map<HomeAction>((users) => GetUsersSuccessChange(users))
            .startWith(const LoadingChange())
            .doOnError((e, s) => messageS.add(GetUsersErrorMessage(e)))
            .onErrorReturnWith((e) => GetUsersErrorChange(e));
      });
    };

    return HomeEffects._(
      messageS,
      fetchEffect,
      refreshEffect,
      messageS.sink,
    );
  }
}
