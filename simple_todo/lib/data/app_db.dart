import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simple_todo/data/todo_dao/todo_dao_impl.dart';
import 'package:simple_todo/data/todo_entity/todo_entity.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqlbrite/sqlbrite.dart';

class AppDb {
  static Future<Database> _dbFuture = _open();
  final TodoDaoImpl todoDao;

  AppDb() : this.todoDao = TodoDaoImpl(_dbFuture.then((db) => BriteDatabase(db)));

  static Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'todo_db.db');

    return openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute(
        'CREATE TABLE todos(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, '
        'title TEXT NOT NULL, '
        'due_date TEXT NOT NULL, '
        'completed INTEGER NOT NULL)',
      );

      await _insertEntities(db);
    });
  }

  static Future _insertEntities(Database db) async {
    final batch = db.batch();
    for (var i = 0; i < 10; i++) {
      batch.insert(
        'todos',
        TodoEntity(
          null,
          'Title $i',
          DateTime.now(),
          i % 2 == 0,
        ).toJson(),
      );
    }
    await batch.commit(
      continueOnError: true,
      noResult: true,
    );
  }
}
