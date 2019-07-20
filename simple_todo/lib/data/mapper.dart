import 'package:simple_todo/data/todo_entity/todo_entity.dart';
import 'package:simple_todo/domain/todo.dart';

typedef Mapper<T, R> = R Function(T t);

class Mappers {
  final Mapper<Todo, TodoEntity> domainToEntity = (todo) {
    return TodoEntity(
      todo.id,
      todo.title,
      todo.dueDate,
      todo.completed,
    );
  };

  final Mapper<TodoEntity, Todo> entityToDomain = (entity) {
    return Todo(
      (b) => b
        ..id = entity.id
        ..title = entity.title
        ..dueDate = entity.dueDate
        ..completed = entity.completed,
    );
  };
}
