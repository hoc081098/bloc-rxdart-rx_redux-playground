import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:distinct_value_connectable_observable/distinct_value_connectable_observable.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:simple_todo/domain/todo.dart';
import 'package:simple_todo/domain/todo_repo.dart';
import 'package:tuple/tuple.dart';

// ignore_for_file: close_sinks

enum Filter { onlyCompleted, onlyIncomplete, all }

class HomeBloc implements BaseBloc {
  ///
  /// Output streams
  ///
  final ValueObservable<BuiltList<Todo>> todos$;
  final ValueObservable<Filter> filter$;

  ///
  /// Input functions
  ///
  final void Function(Todo, bool) toggleCompleted;
  final void Function(Todo) delete;
  final void Function(Filter) changeFilter;

  ///
  /// Dispose
  ///
  final void Function() _dispose;

  HomeBloc._(
    this._dispose, {
    @required this.todos$,
    @required this.toggleCompleted,
    @required this.delete,
    @required this.filter$,
    @required this.changeFilter,
  });

  @override
  void dispose() => _dispose();

  factory HomeBloc(TodoRepo todoRepo) {
    final toggleCompletedSubject = PublishSubject<Tuple2<Todo, bool>>();
    final deleteSubject = PublishSubject<Todo>();
    final filterSubject = BehaviorSubject.seeded(Filter.all);

    /// Output state stream
    final todos$ = publishValueSeededDistinct(
      Observable.combineLatest2(
        todoRepo.allTodo(),
        filterSubject,
        (BuiltList<Todo> todos, Filter filter) {
          switch (filter) {
            case Filter.onlyCompleted:
              return BuiltList<Todo>.of(todos.where((todo) => todo.completed));
            case Filter.onlyIncomplete:
              return BuiltList<Todo>.of(todos.where((todo) => !todo.completed));
              break;
            case Filter.all:
              return BuiltList<Todo>.of(todos);
          }
          return BuiltList<Todo>.of(todos);
        },
      ),
      seedValue: null, // loading state
    );

    ///
    /// Throttle time
    ///
    final toggleCompleted$ = toggleCompletedSubject
        .groupBy((tuple) => tuple.item1.id)
        .map((g) => g.throttleTime(const Duration(milliseconds: 600)))
        .flatMap((g) => g);

    final subscriptions = <StreamSubscription>[
      /// Listen toggle
      (toggleCompleted$.switchMap(
        (tuple) async* {
          final updated = tuple.item1.rebuild((b) => b.completed = tuple.item2);
          yield await todoRepo.update(updated);
        },
      ).listen((result) => print('[HOME_BLOC] toggle=$result'))),

      /// Listen delete
      deleteSubject.flatMap(
        (todo) {
          return Observable.defer(
            () => Stream.fromFuture(todoRepo.delete(todo)),
          );
        },
      ).listen((result) => print('[HOME_BLOC] delete=$result')),

      /// Listen todos
      todos$.listen(
          (todos) => print('[HOME_BLOC] todos.length=${todos?.length}')),
      todos$.connect(),
    ];

    final controllers = <StreamController>{
      toggleCompletedSubject,
      deleteSubject,
      filterSubject
    };

    return HomeBloc._(
      () async {
        await Future.wait(subscriptions.map((s) => s.cancel()));
        await Future.wait(controllers.map((c) => c.close()));
      },

      /// Outputs
      todos$: todos$,
      filter$: filterSubject,

      /// Inputs
      changeFilter: filterSubject.add,
      toggleCompleted: (todo, newValue) =>
          toggleCompletedSubject.add(Tuple2(todo, newValue)),
      delete: deleteSubject.add,
    );
  }
}
