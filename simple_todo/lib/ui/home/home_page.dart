import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:simple_todo/domain/todo.dart';
import 'package:simple_todo/ui/add/add_new.dart';
import 'package:simple_todo/ui/home/home_bloc.dart';
import 'package:intl/intl.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final homeBloc = BlocProvider.of<HomeBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Simple todo'),
        actions: <Widget>[],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              constraints: BoxConstraints.expand(),
              child: StreamBuilder<BuiltList<Todo>>(
                stream: homeBloc.todos$,
                initialData: homeBloc.todos$.value,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final todos = snapshot.data;
                  return ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (BuildContext context, int index) {
                      return TodoItem(todos[index]);
                    },
                  );
                },
              ),
            ),
          ),
          AddNewTodoWidget()
        ],
      ),
    );
  }
}

class TodoItem extends StatelessWidget {
  static final _dateFormatter = DateFormat.yMMMd().add_Hms();
  final Todo todo;

  const TodoItem(this.todo, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<HomeBloc>(context);

    return Slidable(
      child: CheckboxListTile(
        title: Text(todo.title),
        subtitle: Text('Due date: ${_dateFormatter.format(todo.dueDate)}'),
        onChanged: (newValue) => bloc.toggleCompleted(todo, newValue),
        value: todo.completed,
      ),
      actionPane: SlidableDrawerActionPane(),
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () => bloc.delete(todo),
        ),
      ],
    );
  }
}
