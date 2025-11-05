import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import '../services/task_color_service.dart';
import '../widgets/todo_card.dart';
import '../widgets/add_todo_bottom_sheet.dart';
import '../widgets/app_drawer.dart';
import '../screens/schedule_screen.dart';
import '../screens/ai_chat_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeModeChanged;

  const HomeScreen({
    super.key,
    required this.onThemeModeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TodoService _todoService;
  List<Todo> _todos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _todoService = TodoService(prefs);
    await _loadTodos();
  }

  Future<void> _loadTodos() async {
    try {
      final todos = await _todoService.getTodos();
      if (mounted) {
        setState(() {
          _todos = todos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading todos: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addTodo(Todo todo) async {
    try {
      await _todoService.addTodo(todo);
      await _loadTodos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding todo: $e')),
        );
      }
    }
  }

  Future<void> _updateTodo(Todo todo) async {
    try {
      await _todoService.updateTodo(todo);
      await _loadTodos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating todo: $e')),
        );
      }
    }
  }

  Future<void> _deleteTodo(String id) async {
    try {
      await _todoService.deleteTodo(id);
      await _loadTodos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting todo: $e')),
        );
      }
    }
  }

  Map<String, List<Todo>> _groupTodosByTitle() {
    final groupedTodos = <String, List<Todo>>{};
    for (final todo in _todos) {
      if (!groupedTodos.containsKey(todo.title)) {
        groupedTodos[todo.title] = [];
      }
      groupedTodos[todo.title]!.add(todo);
    }
    return groupedTodos;
  }

  @override
  Widget build(BuildContext context) {
    final groupedTodos = _groupTodosByTitle();
    final timeFormat = DateFormat.jm();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              await _loadTodos();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScheduleScreen(todos: _todos),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AIChatScreen(
                    onTasksCreated: _loadTodos,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              widget.onThemeModeChanged(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todos.isEmpty
              ? const Center(child: Text('No tasks yet. Add one!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedTodos.length,
                  itemBuilder: (context, index) {
                    final title = groupedTodos.keys.elementAt(index);
                    final todos = groupedTodos[title]!;
                    final firstTodo = todos.first;
                    final taskColor = TaskColorService().getColorForTask(title);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: taskColor.withOpacity(0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: taskColor.withOpacity(0.6),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Stack(
                              children: [
                                Checkbox(
                                  value: todos.every((t) => t.isCompleted),
                                  onChanged: (bool? value) async {
                                    if (value != null) {
                                      for (final todo in todos) {
                                        await _updateTodo(
                                          todo.copyWith(isCompleted: value),
                                        );
                                      }
                                    }
                                  },
                                  activeColor: taskColor,
                                ),
                                if (todos.length > 1)
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: taskColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        todos.length.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                decoration: todos.every((t) => t.isCompleted)
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (firstTodo.description.isNotEmpty)
                                  Text(
                                    firstTodo.description,
                                    style: TextStyle(
                                      decoration:
                                          todos.every((t) => t.isCompleted)
                                              ? TextDecoration.lineThrough
                                              : null,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white.withOpacity(0.8)
                                          : Colors.black.withOpacity(0.8),
                                    ),
                                  ),
                                if (firstTodo.dueDate != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white.withOpacity(0.8)
                                            : Colors.black.withOpacity(0.8),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${todos.length} occurrence${todos.length > 1 ? 's' : ''} at ${timeFormat.format(firstTodo.dueDate!)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                        .withOpacity(0.8)
                                                    : Colors.black
                                                        .withOpacity(0.8),
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withOpacity(0.8)
                                        : Colors.black.withOpacity(0.8),
                                  ),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (context) => AddTodoBottomSheet(
                                        onAdd: _updateTodo,
                                        todo: firstTodo,
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white.withOpacity(0.8)
                                        : Colors.black.withOpacity(0.8),
                                  ),
                                  onPressed: () async {
                                    for (final todo in todos) {
                                      await _deleteTodo(todo.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (todos.length > 1)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                '${todos.length} identical tasks',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white.withOpacity(0.8)
                                          : Colors.black.withOpacity(0.8),
                                    ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => AddTodoBottomSheet(
              onAdd: _addTodo,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
