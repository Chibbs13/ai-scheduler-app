import 'package:hive/hive.dart';
import 'package:todo_db/src/models/todo.dart';
import 'package:todo_db/src/services/notification_service.dart';

class TodoDbService {
  static const String _boxName = 'todos';
  late Box<Todo> _todoBox;
  bool _isInitialized = false;
  final _notificationService = NotificationService();

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(TodoAdapter());
      }
      _todoBox = await Hive.openBox<Todo>(_boxName);
      await _notificationService.init();
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize TodoDbService: $e');
    }
  }

  Future<void> close() async {
    if (!_isInitialized) return;
    try {
      await _todoBox.close();
      _isInitialized = false;
    } catch (e) {
      throw Exception('Failed to close TodoDbService: $e');
    }
  }

  // CRUD Operations
  Future<List<Todo>> getAllTodos() async {
    _checkInitialized();
    try {
      return _todoBox.values.toList();
    } catch (e) {
      throw Exception('Failed to get all todos: $e');
    }
  }

  Future<Todo?> getTodo(String id) async {
    _checkInitialized();
    try {
      return _todoBox.get(id);
    } catch (e) {
      throw Exception('Failed to get todo: $e');
    }
  }

  Future<void> addTodo(Todo todo) async {
    _checkInitialized();
    try {
      await _todoBox.put(todo.id, todo);
      if (todo.reminderEnabled) {
        await _notificationService.scheduleReminder(todo);
      }
    } catch (e) {
      throw Exception('Failed to add todo: $e');
    }
  }

  Future<void> updateTodo(Todo todo) async {
    _checkInitialized();
    try {
      if (!_todoBox.containsKey(todo.id)) {
        throw Exception('Todo with id ${todo.id} does not exist');
      }
      await _todoBox.put(todo.id, todo);
      await _notificationService.updateReminder(todo);
    } catch (e) {
      throw Exception('Failed to update todo: $e');
    }
  }

  Future<void> deleteTodo(String id) async {
    _checkInitialized();
    try {
      if (!_todoBox.containsKey(id)) {
        throw Exception('Todo with id $id does not exist');
      }
      final todo = _todoBox.get(id);
      if (todo != null) {
        await _notificationService.cancelReminder(todo);
      }
      await _todoBox.delete(id);
    } catch (e) {
      throw Exception('Failed to delete todo: $e');
    }
  }

  Future<void> deleteAllTodos() async {
    _checkInitialized();
    try {
      final todos = _todoBox.values.toList();
      for (final todo in todos) {
        await _notificationService.cancelReminder(todo);
      }
      await _todoBox.clear();
    } catch (e) {
      throw Exception('Failed to delete all todos: $e');
    }
  }

  // Search and Filter Operations
  Future<List<Todo>> searchTodos(String query) async {
    _checkInitialized();
    try {
      final todos = _todoBox.values.toList();
      return todos.where((todo) {
        final titleMatch =
            todo.title.toLowerCase().contains(query.toLowerCase());
        final descriptionMatch =
            todo.description.toLowerCase().contains(query.toLowerCase());
        final tagsMatch = todo.tags
            .any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
        return titleMatch || descriptionMatch || tagsMatch;
      }).toList();
    } catch (e) {
      throw Exception('Failed to search todos: $e');
    }
  }

  Future<List<Todo>> getTodosByPriority(int priority) async {
    _checkInitialized();
    try {
      return _todoBox.values
          .where((todo) => todo.priority == priority)
          .toList();
    } catch (e) {
      throw Exception('Failed to get todos by priority: $e');
    }
  }

  Future<List<Todo>> getCompletedTodos() async {
    _checkInitialized();
    try {
      return _todoBox.values.where((todo) => todo.isCompleted).toList();
    } catch (e) {
      throw Exception('Failed to get completed todos: $e');
    }
  }

  Future<List<Todo>> getIncompleteTodos() async {
    _checkInitialized();
    try {
      return _todoBox.values.where((todo) => !todo.isCompleted).toList();
    } catch (e) {
      throw Exception('Failed to get incomplete todos: $e');
    }
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception('TodoDbService is not initialized. Call init() first.');
    }
  }
}
