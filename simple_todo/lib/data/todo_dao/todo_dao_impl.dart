import 'package:rxdart/rxdart.dart';
import 'package:simple_todo/data/todo_dao/todo_dao.dart';
import 'package:simple_todo/data/todo_entity/todo_entity.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlbrite/sqlbrite.dart';

class TodoDaoImpl implements TodoDao {
  final Future<BriteDatabase> _dbFuture;

  const TodoDaoImpl(this._dbFuture);

  @override
  Observable<List<TodoEntity>> allTodo() {
    return Observable.fromFuture(_dbFuture).exhaustMap((db) {
      return db
          .createQuery('todos', orderBy: 'due_date DESC')
          .mapToList((json) => TodoEntity.fromJson(json));
    });
  }

  @override
  Future<bool> update(TodoEntity todo) async {
    final db = await _dbFuture;
    return await db.update(
          'todos',
          todo.toJson(),
          where: 'id = ?',
          whereArgs: [todo.id],
          conflictAlgorithm: ConflictAlgorithm.replace,
        ) >
        0;
  }

  @override
  Future<bool> insert(TodoEntity todo) async {
    final db = await _dbFuture;
    return await db.insert(
          'todos',
          todo.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ) !=
        -1;
  }

  @override
  Future<bool> delete(TodoEntity todo) async {
    final db = await _dbFuture;
    return await db.delete(
          'todos',
          where: 'id = ?',
          whereArgs: [todo.id],
        ) >
        0;
  }
}
