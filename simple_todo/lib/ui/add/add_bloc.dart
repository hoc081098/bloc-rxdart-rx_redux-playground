import 'dart:async';

import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:meta/meta.dart';
import 'package:rxdart/rxdart.dart';
import 'package:simple_todo/domain/todo.dart';
import 'package:simple_todo/domain/todo_repo.dart';
import 'package:tuple/tuple.dart';

// ignore_for_file: close_sinks

abstract class AddMessage {}

class MissingTitleOrDueDate implements AddMessage {
  const MissingTitleOrDueDate();
}

class AddSuccess implements AddMessage {
  const AddSuccess();
}

class AddFailure implements AddMessage {
  final error;
  const AddFailure([this.error]);
}

class AddBloc implements BaseBloc {
  ///
  /// Ouputs
  ///
  final Stream<AddMessage> message$;

  ///
  /// Input
  ///
  final void Function(String) titleChanged;
  final void Function(DateTime) dueDateChanged;
  final void Function() submitAdd;

  ///
  /// Dispose
  ///
  final void Function() _dispose;

  AddBloc._(
    this._dispose, {
    @required this.message$,
    @required this.titleChanged,
    @required this.dueDateChanged,
    @required this.submitAdd,
  });

  @override
  void dispose() => _dispose();

  factory AddBloc(final TodoRepo todoRepo) {
    final titleSubject = BehaviorSubject<String>.seeded(null);
    final dueDateSubject = BehaviorSubject<DateTime>.seeded(null);
    final submitSubject = PublishSubject<void>();

    final both$ = Observable.combineLatest2(
      titleSubject,
      dueDateSubject,
      (String title, DateTime date) => Tuple2(title, date),
    );

    final submit$ = submitSubject
        .withLatestFrom(both$, (_, Tuple2<String, DateTime> tuple) => tuple)
        .share();

    add(Todo todo) {
      print('[ADD_BLOC] add $todo');

      return Observable.defer(() => Stream.fromFuture(todoRepo.insert(todo)))
          .map((result) => result ? const AddSuccess() : const AddFailure())
          .onErrorReturnWith((e) => AddFailure(e));
    }

    isValid(Tuple2<String, DateTime> tuple) {
      return tuple.item1 != null &&
          tuple.item2 != null &&
          tuple.item1.isNotEmpty;
    }

    final message$ = Observable.merge(
      [
        submit$
            .where(isValid)
            .map(
              (tuple) => Todo(
                (b) => b
                  ..dueDate = tuple.item2
                  ..title = tuple.item1
                  ..completed = false,
              ),
            )
            .flatMap(add),
        submit$
            .where((tuple) => !isValid(tuple))
            .map((_) => const MissingTitleOrDueDate()),
      ],
    ).publish();

    final subscriptions = <StreamSubscription>[
      message$.listen((message) => print('[ADD_BLOC] message=$message')),
      message$.connect(),
    ];
    final subjects = <StreamController>{
      titleSubject,
      dueDateSubject,
      submitSubject,
    };

    return AddBloc._(
      () async {
        await Future.wait(subscriptions.map((s) => s.cancel()));
        await Future.wait(subjects.map((s) => s.close()));
        print('[ADD_BLOC] disposed');
      },
      dueDateChanged: dueDateSubject.add,
      message$: message$,
      submitAdd: () => submitSubject.add(null),
      titleChanged: titleSubject.add,
    );
  }
}
