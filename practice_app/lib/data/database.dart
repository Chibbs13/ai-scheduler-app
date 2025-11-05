import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo.dart';

class Database {
  static const String _boxName = 'todos';
  static Box<Todo>? _todoBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TodoAdapter());
    _todoBox = await Hive.openBox<Todo>(_boxName);
  }

  static Box<Todo> get todoBox {
    if (_todoBox == null) {
      throw Exception('Database not initialized. Call Database.init() first.');
    }
    return _todoBox!;
  }

  static Future<void> close() async {
    await _todoBox?.close();
  }
}
