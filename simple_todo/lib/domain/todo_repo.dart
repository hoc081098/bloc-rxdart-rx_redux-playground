import 'package:built_collection/built_collection.dart';
import 'package:rxdart/rxdart.dart';
import 'package:simple_todo/domain/todo.dart';

abstract class TodoRepo {
  Observable<BuiltList<Todo>> allTodo();

  Future<bool> update(Todo todo);

  Future<bool> insert(Todo todo);

  Future<bool> delete(Todo todo);
}
