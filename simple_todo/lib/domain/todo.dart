import 'package:built_value/built_value.dart';

part 'todo.g.dart';

abstract class Todo implements Built<Todo, TodoBuilder> {
  @nullable
  int get id;
  String get title;
  DateTime get dueDate;
  bool get completed;

  Todo._();

  factory Todo([updates(TodoBuilder b)]) = _$Todo;
}
