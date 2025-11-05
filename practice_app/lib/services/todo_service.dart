import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';
import 'notification_service.dart';

class TodoService {
  static const String baseUrl = 'http://localhost:5000/api';
  static const String _storageKey = 'todos';
  final SharedPreferences _prefs;
  final NotificationService _notificationService = NotificationService();

  TodoService(this._prefs);

  Future<void> init() async {
    await _notificationService.init();
  }

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'];
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Todo>> getTodos() async {
    final String? todosJson = _prefs.getString(_storageKey);
    if (todosJson == null) return [];

    final List<dynamic> todosList = jsonDecode(todosJson);
    return todosList.map((todoJson) => Todo.fromJson(todoJson)).toList();
  }

  Future<void> addTodo(Todo todo) async {
    final todos = await getTodos();
    todos.add(todo);
    await _saveTodos(todos);
    if (todo.reminderTime != null) {
      await _notificationService.scheduleReminder(todo);
    }
  }

  Future<void> updateTodo(Todo todo) async {
    final todos = await getTodos();
    final index = todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      todos[index] = todo;
      await _saveTodos(todos);
      await _notificationService.updateReminder(todo);
    }
  }

  Future<void> deleteTodo(String id) async {
    final todos = await getTodos();
    final todo = todos.firstWhere((t) => t.id == id);
    todos.removeWhere((todo) => todo.id == id);
    await _saveTodos(todos);
    await _notificationService.cancelReminder(todo);
  }

  Future<void> _saveTodos(List<Todo> todos) async {
    final todosJson = jsonEncode(todos.map((todo) => todo.toJson()).toList());
    await _prefs.setString(_storageKey, todosJson);
  }
}
