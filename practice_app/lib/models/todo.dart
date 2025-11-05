import 'package:hive/hive.dart';
part 'todo.g.dart';

@HiveType(typeId: 0)
class Todo {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final List<String> tags;
  @HiveField(4)
  final bool isCompleted;
  @HiveField(5)
  final DateTime? dueDate;
  @HiveField(6)
  final DateTime createdAt;
  @HiveField(7)
  final DateTime updatedAt;
  @HiveField(8)
  final int priority;
  @HiveField(9)
  final int duration;
  @HiveField(10)
  final String? calendarEventId;
  @HiveField(11)
  final DateTime? reminderTime;

  Todo({
    required this.id,
    required this.title,
    this.description = '',
    List<String>? tags,
    this.isCompleted = false,
    this.dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.priority = 0,
    this.duration = 30,
    this.calendarEventId,
    this.reminderTime,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get formattedDuration {
    if (duration < 60) {
      return '$duration min';
    }
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    if (minutes == 0) {
      return '$hours hr';
    }
    return '$hours hr $minutes min';
  }

  String get priorityLabel {
    switch (priority) {
      case 0:
        return 'Low';
      case 1:
        return 'Medium';
      case 2:
        return 'High';
      default:
        return 'Low';
    }
  }

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? tags,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? priority,
    int? duration,
    String? calendarEventId,
    DateTime? reminderTime,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priority: priority ?? this.priority,
      duration: duration ?? this.duration,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tags': tags,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'priority': priority,
      'duration': duration,
      'calendarEventId': calendarEventId,
      'reminderTime': reminderTime?.toIso8601String(),
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      isCompleted: json['isCompleted'] ?? false,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      priority: json['priority'] ?? 0,
      duration: json['duration'] ?? 30,
      calendarEventId: json['calendarEventId'],
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'])
          : null,
    );
  }
}
