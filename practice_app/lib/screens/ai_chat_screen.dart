import 'package:flutter/material.dart';
import '../services/task_parser_service.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIChatScreen extends StatefulWidget {
  final VoidCallback? onTasksCreated;
  const AIChatScreen({super.key, this.onTasksCreated});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late TodoService _todoService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _todoService = TodoService(prefs);
  }

  Future<List<Map<String, dynamic>>> fetchTasksFromBackend(
      String message) async {
    final response = await http.post(
      Uri.parse(
          'http://localhost:5000/api/ai-tasks'), // Change to your backend URL if needed
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['tasks']);
    } else {
      throw Exception('Failed to fetch tasks');
    }
  }

  void _handleSubmit() async {
    if (_messageController.text.isEmpty) return;

    final userMessage = _messageController.text;
    _messageController.clear();

    setState(() {
      _messages.add({
        'text': userMessage,
        'isUser': true,
      });
    });

    try {
      final tasks = await fetchTasksFromBackend(userMessage);

      if (tasks.isNotEmpty) {
        for (final task in tasks) {
          DateTime? dueDate;
          if (task['Date'] != null && task['Time'] != null) {
            try {
              dueDate = DateTime.parse('${task['Date']}T${task['Time']}');
            } catch (e) {
              continue;
            }
          }
          await _todoService.addTodo(Todo(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: task['Task'] ?? 'Untitled',
            description: task['Duration'] ?? '',
            dueDate: dueDate,
            isCompleted: false,
            tags: ['ai'],
          ));
        }
        if (widget.onTasksCreated != null) widget.onTasksCreated!();
        setState(() {
          _messages.add({
            'text':
                'I\'ve created ${tasks.length} tasks for you:\n${tasks.map((t) => '- ${t['Task']} on ${t['Date']} at ${t['Time']}').join('\n')}',
            'isUser': false,
          });
        });
      } else {
        setState(() {
          _messages.add({
            'text':
                'I couldn\'t understand the task details. Please include the time, days, and duration.',
            'isUser': false,
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'text': 'Error: ${e.toString()}',
          'isUser': false,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Icon(
                      Icons.smart_toy,
                      size: 80,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message['isUser']
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: message['isUser']
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message['text'],
                            style: TextStyle(
                              color: message['isUser']
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _handleSubmit(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _handleSubmit,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
