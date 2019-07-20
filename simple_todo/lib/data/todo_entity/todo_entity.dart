class TodoEntity {
  final int id;
  final String title;
  final DateTime dueDate;
  final bool completed;

  TodoEntity(this.id, this.title, this.dueDate, this.completed);

  factory TodoEntity.fromJson(Map<String, dynamic> json) {
    return TodoEntity(
      json['id'],
      json['title'],
      DateTime.parse(json['due_date']),
      json['completed'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'due_date': dueDate.toIso8601String(),
      'completed': completed ? 1 : 0,
    }..removeWhere((_, v) => v == null);
  }
}
