import 'package:intl/intl.dart';
import '../models/todo.dart';

class TaskParserService {
  static List<Todo> parseTaskInput(String input) {
    final List<Todo> tasks = [];
    final now = DateTime.now();

    // Extract time
    final timeRegex =
        RegExp(r'(\d{1,2})[:;](\d{2})(?:\s*[ap]m)?', caseSensitive: false);
    final timeMatch = timeRegex.firstMatch(input);
    if (timeMatch == null) return tasks;

    int hour = int.parse(timeMatch.group(1)!);
    int minute = int.parse(timeMatch.group(2)!);

    // Check for AM/PM
    if (input.toLowerCase().contains('pm') && hour != 12) {
      hour += 12;
    } else if (input.toLowerCase().contains('am') && hour == 12) {
      hour = 0;
    }

    // Extract days
    final days = <String>[];
    if (input.toLowerCase().contains('monday')) days.add('monday');
    if (input.toLowerCase().contains('tuesday')) days.add('tuesday');
    if (input.toLowerCase().contains('wednesday')) days.add('wednesday');
    if (input.toLowerCase().contains('thursday')) days.add('thursday');
    if (input.toLowerCase().contains('friday')) days.add('friday');
    if (input.toLowerCase().contains('saturday')) days.add('saturday');
    if (input.toLowerCase().contains('sunday')) days.add('sunday');

    // Extract duration
    final durationRegex =
        RegExp(r'for\s+(\d+)\s+(day|week|month|year)s?', caseSensitive: false);
    final durationMatch = durationRegex.firstMatch(input);
    int duration = 1;
    String durationUnit = 'month';

    if (durationMatch != null) {
      duration = int.parse(durationMatch.group(1)!);
      durationUnit = durationMatch.group(2)!;
    }

    // Calculate end date
    DateTime endDate = now;
    switch (durationUnit) {
      case 'day':
        endDate = now.add(Duration(days: duration));
        break;
      case 'week':
        endDate = now.add(Duration(days: duration * 7));
        break;
      case 'month':
        endDate = DateTime(now.year, now.month + duration, now.day);
        break;
      case 'year':
        endDate = DateTime(now.year + duration, now.month, now.day);
        break;
    }

    // Create tasks for each day until end date
    DateTime currentDate = now;
    while (currentDate.isBefore(endDate)) {
      final dayName = DateFormat('EEEE').format(currentDate).toLowerCase();
      if (days.contains(dayName)) {
        final taskDate = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          hour,
          minute,
        );

        // Remove polite/filler phrases
        final ignorePhrases = [
          'can you please',
          'could you please',
          'please',
          'make a task',
          'create a task',
          'i need to',
          'i want to',
          'remind me to',
          'add a task',
          'i have to',
          'i should',
          'i must',
          'i gotta',
          'i got to',
          'i have got to',
        ];
        String cleanedInput = input;
        for (final phrase in ignorePhrases) {
          cleanedInput = cleanedInput.replaceAll(
              RegExp('^$phrase', caseSensitive: false), '');
          cleanedInput = cleanedInput.replaceAll(RegExp('^\s+'), '');
        }

        // Remove day names from the cleaned input for the title
        final allDays = [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday'
        ];
        String titleInput = cleanedInput;
        for (final day in allDays) {
          titleInput =
              titleInput.replaceAll(RegExp(day, caseSensitive: false), '');
        }
        titleInput = titleInput.trim();

        // Extract task description (title)
        String description = titleInput;
        // Try to extract the phrase before 'every' or 'at' as the title
        final descRegex = RegExp(r'^(.*?)\s+(every|at) ', caseSensitive: false);
        final descMatch = descRegex.firstMatch(titleInput);
        String title = description;
        if (descMatch != null && descMatch.group(1) != null) {
          title = descMatch.group(1)!.trim();
        } else {
          // fallback: remove time and duration information
          title = description.replaceAll(timeRegex, '');
          title = title.replaceAll(durationRegex, '');
          title = title.trim();
        }

        tasks.add(Todo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          description: 'Recurring task',
          dueDate: taskDate,
          isCompleted: false,
          tags: ['recurring'],
        ));
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return tasks;
  }
}
