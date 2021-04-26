import 'dart:async';

import 'package:disposebag/disposebag.dart';
import 'package:distinct_value_connectable_stream/distinct_value_connectable_stream.dart';
import 'package:fetch_json_bloc_rxdart/api.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';

///
/// Home state
///
class HomeState {
  final bool isLoading;
  final List<User> users;
  final Object? error;

  const HomeState({
    required this.isLoading,
    required this.users,
    required this.error,
  });

  factory HomeState.initial() => const HomeState(
        isLoading: true,
        users: [],
        error: null,
      );

  HomeState copyWith({bool? isLoading, List<User>? users, Object? error}) {
    return HomeState(
      error: error,
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
    );
  }

  @override
  String toString() =>
      'HomeState{ users.length=${users.length}, isLoading=$isLoading, error=$error }';

  @override
  int get hashCode {
    return isLoading.hashCode ^
        const ListEquality<User>().hash(users) ^
        error.hashCode;
  }

  @override
  bool operator ==(other) {
    return identical(this, other) ||
        other is HomeState &&
            other.isLoading == this.isLoading &&
            const ListEquality<User>().equals(other.users, this.users) &&
            other.error == this.error;
  }
}

///
/// Partial change
///
abstract class PartialStateChange {}

class GetUsersSuccessChange implements PartialStateChange {
  final List<User> users;

  GetUsersSuccessChange(this.users);
}

class LoadingChange implements PartialStateChange {
  const LoadingChange();
}

class GetUsersErrorChange implements PartialStateChange {
  final error;

  const GetUsersErrorChange(this.error);
}

///
/// Single event message
///
abstract class HomeMessage {}

class RefreshSuccessMessage implements HomeMessage {
  const RefreshSuccessMessage();
}

class RefreshFailureMessage implements HomeMessage {
  final error;

  const RefreshFailureMessage(this.error);
}

class GetUsersErrorMessage implements HomeMessage {
  final error;

  GetUsersErrorMessage(this.error);
}

///
/// Home BLoC
///
class HomeBloc extends DisposeCallbackBaseBloc {
  ///
  /// Output
  ///
  final DistinctValueStream<HomeState> state$;
  final Stream<HomeMessage> message$;

  ///
  /// Input
  ///
  final void Function() fetch;
  final Future<void> Function() refresh;

  HomeBloc._({
    required void Function() dispose,
    required this.state$,
    required this.fetch,
    required this.refresh,
    required this.message$,
  }) : super(dispose);

  factory HomeBloc(Api api) {
    // ignore_for_file: close_sinks

    ///
    /// Subjects
    ///
    final fetchSubject = PublishSubject<void>();
    final refreshSubject = PublishSubject<Completer<void>>();
    final messageSubject = PublishSubject<HomeMessage>();

    ///
    /// Input actions to state
    ///
    final fetchChanges = fetchSubject.exhaustMap(
      (_) {
        return Rx.fromCallable(() => api.getUsers())
            .map<PartialStateChange>((users) => GetUsersSuccessChange(users))
            .startWith(const LoadingChange())
            .doOnError((e, s) => messageSubject.add(GetUsersErrorMessage(e)))
            .onErrorReturnWith((e) => GetUsersErrorChange(e));
      },
    );
    final refreshChanges = refreshSubject
        .throttleTime(const Duration(milliseconds: 600))
        .exhaustMap(
      (completer) {
        return Rx.fromCallable(() => api.getUsers())
            .map<PartialStateChange>((users) => GetUsersSuccessChange(users))
            .doOnError((e, s) => messageSubject.add(RefreshFailureMessage(e)))
            .doOnData((_) => messageSubject.add(const RefreshSuccessMessage()))
            .onErrorResumeNext(Stream.empty())
            .doOnDone(() => completer.complete());
      },
    );
    final state$ = Rx.merge([fetchChanges, refreshChanges])
        .scan(_reduce, HomeState.initial())
        .publishValueDistinct(HomeState.initial());

    ///
    /// Subscriptions & stream controllers
    ///
    final bag = DisposeBag([
      //subscriptions
      state$.listen((state) => print('[HOME_BLOC] state=$state')),
      messageSubject.listen((message) => print('[HOME_BLOC] message=$message')),
      state$.connect(),
      //controllers
      fetchSubject,
      refreshSubject,
      messageSubject,
    ]);

    return HomeBloc._(
      dispose: bag.dispose,
      state$: state$,
      fetch: () => fetchSubject.add(null),
      refresh: () {
        final completer = Completer<void>.sync();
        refreshSubject.add(completer);
        return completer.future;
      },
      message$: messageSubject,
    );
  }

  ///
  /// Reduce
  ///
  static HomeState _reduce(
    HomeState? state,
    PartialStateChange change,
    int _,
  ) {
    state!;

    if (change is LoadingChange) {
      return state.copyWith(isLoading: true);
    }
    if (change is GetUsersErrorChange) {
      return state.copyWith(
        isLoading: false,
        error: change.error,
      );
    }
    if (change is GetUsersSuccessChange) {
      return state.copyWith(
        isLoading: false,
        error: null,
        users: change.users,
      );
    }
    return state;
  }
}
