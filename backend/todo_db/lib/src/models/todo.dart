import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'todo.g.dart';

@HiveType(typeId: 0)
class Todo extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? dueDate;

  @HiveField(6)
  int priority;

  @HiveField(7)
  List<String> tags;

  @HiveField(8)
  DateTime? reminderTime;

  @HiveField(9)
  bool reminderEnabled;

  @HiveField(10)
  int duration; // Duration in minutes

  @HiveField(11)
  String? preferredTimeOfDay; // 'morning', 'afternoon', 'evening'

  @HiveField(12)
  bool flexible; // Whether the task can be rescheduled

  @HiveField(13)
  List<String>
      dependencies; // IDs of tasks that must be completed before this task

  Todo({
    String? id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    DateTime? createdAt,
    this.dueDate,
    this.priority = 0,
    List<String>? tags,
    this.reminderTime,
    this.reminderEnabled = false,
    this.duration = 30, // Default duration of 30 minutes
    this.preferredTimeOfDay,
    this.flexible = true,
    List<String>? dependencies,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [],
        dependencies = dependencies ?? [] {
    _validate();
  }

  void _validate() {
    if (title.trim().isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
    if (priority < 0 || priority > 2) {
      throw ArgumentError('Priority must be between 0 and 2');
    }
    if (dueDate != null && dueDate!.isBefore(createdAt)) {
      throw ArgumentError('Due date cannot be before creation date');
    }
    if (reminderTime != null && reminderTime!.isBefore(DateTime.now())) {
      throw ArgumentError('Reminder time cannot be in the past');
    }
  }

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
    int? priority,
    List<String>? tags,
    bool? reminderEnabled,
    DateTime? reminderTime,
    int? duration,
    String? preferredTimeOfDay,
    bool? flexible,
    List<String>? dependencies,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      tags: tags ?? List.from(this.tags),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      duration: duration ?? this.duration,
      preferredTimeOfDay: preferredTimeOfDay ?? this.preferredTimeOfDay,
      flexible: flexible ?? this.flexible,
      dependencies: dependencies ?? List.from(this.dependencies),
    );
  }

  bool get isOverdue =>
      dueDate != null && !isCompleted && dueDate!.isBefore(DateTime.now());

  String get formattedDueDate {
    if (dueDate == null) return 'No due date';
    return '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}';
  }

  String get formattedReminderTime {
    if (reminderTime == null) return 'No reminder';
    return '${reminderTime!.hour}:${reminderTime!.minute.toString().padLeft(2, '0')}';
  }

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
        return 'Unknown';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'tags': tags,
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime?.toIso8601String(),
      'duration': duration,
      'preferredTimeOfDay': preferredTimeOfDay,
      'flexible': flexible,
      'dependencies': dependencies,
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      priority: json['priority'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'] as String)
          : null,
      duration: json['duration'] as int? ?? 30,
      preferredTimeOfDay: json['preferredTimeOfDay'] as String?,
      flexible: json['flexible'] as bool? ?? true,
      dependencies:
          (json['dependencies'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          isCompleted == other.isCompleted &&
          createdAt == other.createdAt &&
          dueDate == other.dueDate &&
          priority == other.priority &&
          tags.length == other.tags.length &&
          tags.every((tag) => other.tags.contains(tag)) &&
          reminderTime == other.reminderTime &&
          reminderEnabled == other.reminderEnabled &&
          duration == other.duration &&
          preferredTimeOfDay == other.preferredTimeOfDay &&
          flexible == other.flexible &&
          dependencies.length == other.dependencies.length &&
          dependencies.every((dep) => other.dependencies.contains(dep));

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      isCompleted.hashCode ^
      createdAt.hashCode ^
      dueDate.hashCode ^
      priority.hashCode ^
      tags.hashCode ^
      reminderTime.hashCode ^
      reminderEnabled.hashCode ^
      duration.hashCode ^
      preferredTimeOfDay.hashCode ^
      flexible.hashCode ^
      dependencies.hashCode;
}
