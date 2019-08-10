import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:flutter_provider/flutter_provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:simple_todo/domain/todo.dart';
import 'package:simple_todo/domain/todo_repo.dart';
import 'package:simple_todo/ui/add/add_bloc.dart';
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
        title: Text('Rx todo'),
        actions: <Widget>[
          RxStreamBuilder<Filter>(
              stream: homeBloc.filter$,
              builder: (context, snapshot) {
                final filter = snapshot.data;

                return PopupMenuButton<Filter>(
                  offset: Offset(0, 100),
                  initialValue: filter,
                  tooltip: 'Filter',
                  onSelected: homeBloc.changeFilter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    child: Row(
                      children: <Widget>[
                        Center(
                          child: Text(
                            titleFor(filter: filter),
                            style: Theme.of(context).textTheme.subtitle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                  itemBuilder: (BuildContext context) {
                    return Filter.values.map((v) {
                      return PopupMenuItem<Filter>(
                        child: Text(
                          titleFor(filter: v),
                        ),
                        value: v,
                      );
                    }).toList();
                  },
                );
              }),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              constraints: BoxConstraints.expand(),
              child: RxStreamBuilder<BuiltList<Todo>>(
                stream: homeBloc.todos$,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final todos = snapshot.data;
                  return ListView.separated(
                    itemCount: todos.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      return TodoItem(todos[index]);
                    },
                    separatorBuilder: (_, __) => Divider(),
                  );
                },
              ),
            ),
          ),
          BlocProvider<AddBloc>(
            child: AddNewTodoWidget(),
            initBloc: () => AddBloc(Provider.of<TodoRepo>(context)),
          )
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
