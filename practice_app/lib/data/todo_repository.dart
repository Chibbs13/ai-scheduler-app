import '../models/todo.dart';
import 'database.dart';

class TodoRepository {
  final Box<Todo> _box;

  TodoRepository() : _box = Database.todoBox;

  Future<List<Todo>> getAllTodos() async {
    return _box.values.toList();
  }

  Future<Todo?> getTodo(String id) async {
    return _box.get(id);
  }

  Future<void> addTodo(Todo todo) async {
    await _box.put(todo.id, todo);
  }

  Future<void> updateTodo(Todo todo) async {
    await _box.put(todo.id, todo);
  }

  Future<void> deleteTodo(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteAllTodos() async {
    await _box.clear();
  }

  Future<List<Todo>> searchTodos(String query) async {
    final todos = _box.values.toList();
    return todos.where((todo) {
      final titleLower = todo.title.toLowerCase();
      final descriptionLower = todo.description.toLowerCase();
      final searchLower = query.toLowerCase();
      return titleLower.contains(searchLower) ||
          descriptionLower.contains(searchLower);
    }).toList();
  }

  Future<List<Todo>> getTodosByPriority(int priority) async {
    return _box.values.where((todo) => todo.priority == priority).toList();
  }

  Future<List<Todo>> getCompletedTodos() async {
    return _box.values.where((todo) => todo.isCompleted).toList();
  }

  Future<List<Todo>> getIncompleteTodos() async {
    return _box.values.where((todo) => !todo.isCompleted).toList();
  }
}
