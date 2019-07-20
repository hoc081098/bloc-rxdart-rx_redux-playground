import 'package:rxdart/rxdart.dart';
import 'package:simple_todo/data/todo_entity/todo_entity.dart';

abstract class TodoDao {
  Observable<List<TodoEntity>> allTodo();

  Future<bool> update(TodoEntity todo);

  Future<bool> insert(TodoEntity todo);

  Future<bool> delete(TodoEntity todo);
}
