import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:simple_todo/ui/add/add_bloc.dart';

class AddNewTodoWidget extends StatefulWidget {
  @override
  _AddNewTodoWidgetState createState() => _AddNewTodoWidgetState();
}

class _AddNewTodoWidgetState extends State<AddNewTodoWidget> {
  StreamSubscription<AddMessage> _subscription;
  TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController()
      ..addListener(() {
        final title = _textController.text;
        print("Title changed: '$title'");
        BlocProvider.of<AddBloc>(context).titleChanged(title);
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    showSnackBar(message) => Scaffold.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(
              seconds: 1,
              milliseconds: 500,
            ),
          ),
        );

    final bloc = BlocProvider.of<AddBloc>(context);
    _subscription = bloc.message$.listen((message) {
      if (message is AddSuccess) {
        showSnackBar('Added successfully');

        // reset values
        _textController.clear();
        bloc.dueDateChanged(null);
      }
      if (message is AddFailure) {
        print('[ADD_NEW] error=${message.error}');
        showSnackBar('Added not successfully');
      }
      if (message is MissingTitleOrDueDate) {
        showSnackBar('Missing title or due date');
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<AddBloc>(context);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border.all(
          color: Theme.of(context).accentColor,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Title',
                filled: true,
              ),
              onSubmitted: (_) => bloc.submitAdd(),
              controller: _textController,
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: () => _showDateTimeDialog(bloc),
            tooltip: 'Select due date',
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: bloc.submitAdd,
            tooltip: 'Add todo',
          ),
        ],
      ),
    );
  }

  _showDateTimeDialog(AddBloc bloc) async {
    final dateTime = await showDatePicker(
      context: context,
      firstDate: DateTime(2015),
      initialDate: DateTime.now(),
      lastDate: DateTime(2050),
    );
    if (dateTime == null) {
      return;
    }
    final timeOfDay = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (timeOfDay == null) {
      return;
    }
    final dueDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    bloc.dueDateChanged(dueDate);
  }
}
