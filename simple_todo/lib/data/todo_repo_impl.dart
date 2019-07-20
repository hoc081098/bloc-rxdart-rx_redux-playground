import 'package:built_collection/built_collection.dart';
import 'package:rxdart/rxdart.dart';
import 'package:simple_todo/data/mapper.dart';
import 'package:simple_todo/data/todo_dao/todo_dao.dart';
import 'package:simple_todo/domain/todo.dart';
import 'package:simple_todo/domain/todo_repo.dart';

class TodoRepoImpl implements TodoRepo {
  final TodoDao _todoDao;
  final Mappers _mappers;

  const TodoRepoImpl(this._todoDao, this._mappers);

  @override
  Observable<BuiltList<Todo>> allTodo() {
    return _todoDao.allTodo().map((entities) {
      final todos = entities.map(_mappers.entityToDomain);
      return BuiltList<Todo>.of(todos);
    });
  }

  @override
  Future<bool> delete(Todo todo) {
    return _todoDao.delete(_mappers.domainToEntity(todo));
  }

  @override
  Future<bool> insert(Todo todo) {
    return _todoDao.insert(_mappers.domainToEntity(todo));
  }

  @override
  Future<bool> update(Todo todo) {
    return _todoDao.update(_mappers.domainToEntity(todo));
  }
}
