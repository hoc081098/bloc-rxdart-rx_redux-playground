import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fetch_json_rx_redux/api.dart';
import 'package:meta/meta.dart';

///
/// Home state
///
class HomeState {
  final bool isLoading;
  final List<User> users;
  final error;

  const HomeState({
    @required this.isLoading,
    @required this.users,
    @required this.error,
  });

  factory HomeState.initial() => const HomeState(
        isLoading: true,
        users: [],
        error: null,
      );

  HomeState copyWith({bool isLoading, List<User> users, error}) {
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
            other.runtimeType == this.runtimeType &&
            other.isLoading == this.isLoading &&
            const ListEquality<User>().equals(other.users, this.users) &&
            other.error == this.error;
  }
}

///
/// Actions
///
abstract class HomeAction {
  HomeState reduce(HomeState state);
}

class FetchUsersAction implements HomeAction {
  const FetchUsersAction();

  @override
  HomeState reduce(HomeState state) => state;
}

class RefreshAction implements HomeAction {
  final Completer<void> completer;

  const RefreshAction(this.completer);

  @override
  HomeState reduce(HomeState state) => state;
}

class GetUsersSuccessChange implements HomeAction {
  final List<User> users;

  GetUsersSuccessChange(this.users);

  @override
  HomeState reduce(HomeState state) {
    return state.copyWith(
      isLoading: false,
      error: null,
      users: users,
    );
  }
}

class LoadingChange implements HomeAction {
  const LoadingChange();

  @override
  HomeState reduce(HomeState state) => state.copyWith(isLoading: true);
}

class GetUsersErrorChange implements HomeAction {
  final error;

  const GetUsersErrorChange(this.error);

  @override
  HomeState reduce(HomeState state) {
    return state.copyWith(
      isLoading: false,
      error: error,
    );
  }
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
