import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/todo.dart';
import '../services/task_color_service.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class ScheduleScreen extends StatefulWidget {
  final List<Todo> todos;

  const ScheduleScreen({
    super.key,
    required this.todos,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late CalendarController _calendarController;
  List<Appointment> _appointments = [];
  DateTime? _selectedDate;
  final Random _random = Random();

  Color _getRandomColor() {
    return Color.fromRGBO(
      _random.nextInt(200),
      _random.nextInt(200),
      _random.nextInt(200),
      0.2,
    );
  }

  @override
  void initState() {
    super.initState();
    _calendarController = CalendarController();
    _updateAppointments();
  }

  void _updateAppointments() {
    final todoAppointments =
        widget.todos.where((todo) => todo.dueDate != null).map((todo) {
      final startTime = todo.dueDate!;
      final endTime = startTime.add(const Duration(hours: 1));
      final taskColor = TaskColorService().getColorForTask(todo.title);
      return Appointment(
        startTime: startTime,
        endTime: endTime,
        subject: todo.title,
        color: taskColor,
        notes: todo.description,
        isAllDay: false,
      );
    }).toList();

    setState(() {
      _appointments = todoAppointments;
    });
  }

  void _onTap(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.calendarCell) {
      setState(() {
        _selectedDate = details.date;
        _calendarController.displayDate = details.date!;
      });
      // If switching to day view, scroll to earliest event or 8:00 AM
      if (_calendarController.view == CalendarView.day &&
          details.date != null) {
        final eventsForDay = _appointments
            .where((a) =>
                a.startTime.year == details.date!.year &&
                a.startTime.month == details.date!.month &&
                a.startTime.day == details.date!.day)
            .toList();
        if (eventsForDay.isNotEmpty) {
          eventsForDay.sort((a, b) => a.startTime.compareTo(b.startTime));
          _calendarController.displayDate = eventsForDay.first.startTime;
        } else {
          _calendarController.displayDate = DateTime(
            details.date!.year,
            details.date!.month,
            details.date!.day,
            8,
            0,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Find the earliest event for the selected day (if any)
    DateTime? selectedDate = _calendarController.selectedDate;
    DateTime? initialDisplayDate;
    if (_calendarController.view == CalendarView.day && selectedDate != null) {
      final eventsForDay = _appointments
          .where((a) =>
              a.startTime.year == selectedDate.year &&
              a.startTime.month == selectedDate.month &&
              a.startTime.day == selectedDate.day)
          .toList();
      if (eventsForDay.isNotEmpty) {
        eventsForDay.sort((a, b) => a.startTime.compareTo(b.startTime));
        initialDisplayDate = eventsForDay.first.startTime;
      } else {
        // Default to 8:00 AM on the selected day
        initialDisplayDate = DateTime(
            selectedDate.year, selectedDate.month, selectedDate.day, 8, 0);
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateAppointments,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 2,
              child: SfCalendar(
                view: _selectedDate != null
                    ? CalendarView.day
                    : CalendarView.month,
                controller: _calendarController,
                dataSource: _AppointmentDataSource(_appointments),
                onTap: _onTap,
                initialDisplayDate: initialDisplayDate,
                showDatePickerButton: true,
                showNavigationArrow: true,
                allowViewNavigation: true,
                monthViewSettings: MonthViewSettings(
                  appointmentDisplayMode: MonthAppointmentDisplayMode.none,
                ),
                timeSlotViewSettings: const TimeSlotViewSettings(
                  startHour: 0,
                  endHour: 24,
                  timeFormat: 'h:mm a',
                  timeIntervalHeight: 50,
                  timeInterval: Duration(minutes: 30),
                ),
                monthCellBuilder: (context, details) {
                  final dayEvents = _appointments.where((appointment) {
                    return appointment.startTime.year == details.date.year &&
                        appointment.startTime.month == details.date.month &&
                        appointment.startTime.day == details.date.day;
                  }).toList();

                  final isSelected = _calendarController.selectedDate != null &&
                      details.date.year ==
                          _calendarController.selectedDate!.year &&
                      details.date.month ==
                          _calendarController.selectedDate!.month &&
                      details.date.day == _calendarController.selectedDate!.day;

                  final now = DateTime.now();
                  final isToday = details.date.year == now.year &&
                      details.date.month == now.month &&
                      details.date.day == now.day;

                  final currentMonth = _calendarController.displayDate?.month;
                  final isCurrentMonth = currentMonth != null &&
                      details.date.month == currentMonth;

                  // Colors
                  Color bgColor = Colors.white;
                  if (isToday) {
                    bgColor = Colors.blue[100]!;
                  } else if (isSelected) {
                    bgColor = Colors.green[200]!;
                  } else if (dayEvents.isNotEmpty) {
                    bgColor = TaskColorService()
                        .getColorForTask(dayEvents.first.subject)
                        .withOpacity(0.18);
                  } else if (!isCurrentMonth) {
                    bgColor = Colors.grey.withOpacity(0.07);
                  }

                  // Border/shadow
                  BoxDecoration decoration = BoxDecoration(
                    shape: BoxShape.circle,
                    color: bgColor,
                    border: Border.all(
                      color: isSelected
                          ? Colors.green[700]!
                          : isToday
                              ? Colors.blue[400]!
                              : Colors.grey.withOpacity(0.18),
                      width: isSelected || isToday ? 2 : 1,
                    ),
                    boxShadow: [
                      if (isSelected || isToday || dayEvents.isNotEmpty)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  );

                  // Dot or emoji for tasks
                  Widget? indicator;
                  if (dayEvents.isNotEmpty) {
                    indicator = Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: TaskColorService()
                              .getColorForTask(dayEvents.first.subject),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Center(
                        child: Container(
                          decoration: decoration,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${details.date.day}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isCurrentMonth
                                      ? (isSelected
                                          ? Colors.green[900]
                                          : isToday
                                              ? Colors.blue[900]
                                              : Colors.black)
                                      : Colors.grey,
                                ),
                              ),
                              if (indicator != null) indicator,
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                appointmentTextStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                appointmentBuilder: (context, details) {
                  final appointment = details.appointments.first;
                  final timeFormat = DateFormat('h:mm a');
                  final startTime = timeFormat.format(appointment.startTime);
                  final endTime = timeFormat.format(appointment.endTime);

                  // Get color from TaskColorService
                  final appointmentColor =
                      TaskColorService().getColorForTask(appointment.subject);

                  // Get text color based on theme
                  final isDarkMode =
                      Theme.of(context).brightness == Brightness.dark;
                  final textColor = isDarkMode ? Colors.white : Colors.black;

                  final isDayView =
                      _calendarController.view == CalendarView.day;

                  // Optionally, pick an emoji based on the title/category
                  String emoji = '';
                  final lowerTitle = appointment.subject.toLowerCase();
                  if (lowerTitle.contains('study') ||
                      lowerTitle.contains('read')) {
                    emoji = '📘 ';
                  } else if (lowerTitle.contains('gym') ||
                      lowerTitle.contains('workout')) {
                    emoji = '🏋️ ';
                  } else if (lowerTitle.contains('meeting')) {
                    emoji = '📅 ';
                  } else if (lowerTitle.contains('call')) {
                    emoji = '📞 ';
                  } else if (lowerTitle.contains('doctor')) {
                    emoji = '🩺 ';
                  } else if (lowerTitle.contains('shop') ||
                      lowerTitle.contains('grocery')) {
                    emoji = '🛒 ';
                  } else if (lowerTitle.contains('walk') ||
                      lowerTitle.contains('run')) {
                    emoji = '🏃 ';
                  } else if (lowerTitle.contains('meditate')) {
                    emoji = '🧘 ';
                  } else if (lowerTitle.contains('clean')) {
                    emoji = '🧹 ';
                  } else if (lowerTitle.contains('write')) {
                    emoji = '✍️ ';
                  }

                  if (isDayView) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: appointmentColor.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: appointmentColor.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                            color: appointmentColor.withOpacity(0.7), width: 2),
                      ),
                      child: SingleChildScrollView(
                        physics: ClampingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (emoji.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    appointment.subject,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: textColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$startTime - $endTime',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (appointment.notes != null &&
                                appointment.notes!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  appointment.notes!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textColor.withOpacity(0.85),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Default style for other views
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: appointmentColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: appointmentColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            startTime,
                            style: TextStyle(
                              fontSize: 10,
                              color: textColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appointment.subject,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (appointment.notes?.isNotEmpty ?? false)
                                Text(
                                  appointment.notes!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
