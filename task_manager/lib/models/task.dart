enum TaskStatus {
  todo('To-Do'),
  inProgress('In Progress'),
  done('Done');

  const TaskStatus(this.value);
  final String value;

  static TaskStatus fromValue(String val) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TaskStatus.todo,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final String dueDate;
  final TaskStatus status;
  final String? blockedById;
  final String? blockedByTitle;
  final int sortOrder; // ← new

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedById,
    this.blockedByTitle,
    this.sortOrder = 0, // ← new
  });

  bool get isBlocked => blockedById != null;

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      dueDate: json['due_date'] as String,
      status: TaskStatus.fromValue(json['status'] as String),
      blockedById: json['blocked_by_id'] as String?,
      blockedByTitle: json['blocked_by_title'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0, // ← new
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'due_date': dueDate,
        'status': status.value,
        'blocked_by_id': blockedById,
        'sort_order': sortOrder, // ← new
      };

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? dueDate,
    TaskStatus? status,
    String? Function()? blockedById,
    String? Function()? blockedByTitle,
    int? sortOrder, // ← new
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedById: blockedById != null ? blockedById() : this.blockedById,
      blockedByTitle:
          blockedByTitle != null ? blockedByTitle() : this.blockedByTitle,
      sortOrder: sortOrder ?? this.sortOrder, // ← new
    );
  }
}
