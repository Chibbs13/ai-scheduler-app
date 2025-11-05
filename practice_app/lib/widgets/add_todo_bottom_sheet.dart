import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../services/tag_color_service.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class AddTodoBottomSheet extends StatefulWidget {
  final Function(Todo) onAdd;
  final Todo? todo;

  const AddTodoBottomSheet({
    super.key,
    required this.onAdd,
    this.todo,
  });

  @override
  State<AddTodoBottomSheet> createState() => _AddTodoBottomSheetState();
}

class _AddTodoBottomSheetState extends State<AddTodoBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _enableReminder = true;
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description;
      _dueDate = widget.todo!.dueDate;
      _dueTime = widget.todo!.dueDate != null
          ? TimeOfDay.fromDateTime(widget.todo!.dueDate!)
          : null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final dueDate = _dueDate ?? now;
      final dueTime = _dueTime ?? TimeOfDay.now();

      final dueDateTime = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        dueTime.hour,
        dueTime.minute,
      );

      // Set reminder time 15 minutes before due time if enabled
      final reminderTime = _enableReminder
          ? dueDateTime.subtract(const Duration(minutes: 15))
          : null;

      final todo = Todo(
        id: widget.todo?.id ?? const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        isCompleted: false,
        dueDate: dueDateTime,
        tags: _tags,
        reminderTime: reminderTime,
      );

      widget.onAdd(todo);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.todo == null ? 'Add Todo' : 'Edit Todo',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_dueDate == null
                            ? 'Select Date'
                            : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(_dueTime == null
                            ? 'Select Time'
                            : _dueTime!.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Set Reminder'),
                  subtitle: Text(_dueDate != null && _dueTime != null
                      ? 'Reminder at ${_dueTime!.format(context)} on ${DateFormat('MMM d, y').format(_dueDate!)}'
                      : 'Set date and time to enable reminder'),
                  value: _enableReminder,
                  onChanged: (_dueDate != null && _dueTime != null)
                      ? (value) {
                          setState(() {
                            _enableReminder = value;
                          });
                        }
                      : null,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tags',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _tagController,
                                decoration: const InputDecoration(
                                  labelText: 'Add a tag...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _addTag,
                              icon: const Icon(Icons.add),
                              style: IconButton.styleFrom(
                                backgroundColor: colorScheme.primaryContainer,
                                foregroundColor: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        if (_tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _tags.map((tag) {
                              final tagColor =
                                  TagColorService().getColorForTag(tag);
                              return Chip(
                                label: Text(tag),
                                onDeleted: () => _removeTag(tag),
                                backgroundColor: tagColor.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: tagColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                deleteIconColor: tagColor,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Add Todo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
