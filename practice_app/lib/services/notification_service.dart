import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/todo.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(initSettings);
    debugPrint('FlutterLocalNotificationsPlugin initialized');
  }

  Future<void> scheduleReminder(Todo todo) async {
    if (!_isInitialized || todo.reminderTime == null) {
      debugPrint(
          'Cannot schedule reminder: initialized=$_isInitialized, time=${todo.reminderTime}');
      return;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        'todo_reminders',
        'Todo Reminders',
        channelDescription: 'Notifications for todo reminders',
        importance: Importance.high,
        priority: Priority.high,
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledTime = tz.TZDateTime.from(todo.reminderTime!, tz.local);
      debugPrint(
          'Scheduling reminder for todo "${todo.title}" at ${scheduledTime.toString()}');

      await _notifications.zonedSchedule(
        todo.id.hashCode,
        'Todo Reminder',
        todo.title,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('Reminder scheduled successfully');
    } catch (e) {
      debugPrint('Failed to schedule reminder: $e');
    }
  }

  Future<void> cancelReminder(Todo todo) async {
    if (!_isInitialized) {
      debugPrint('Cannot cancel reminder: NotificationService not initialized');
      return;
    }

    try {
      await _notifications.cancel(todo.id.hashCode);
      debugPrint('Reminder cancelled for todo "${todo.title}"');
    } catch (e) {
      debugPrint('Failed to cancel reminder: $e');
    }
  }

  Future<void> updateReminder(Todo todo) async {
    if (!_isInitialized) {
      debugPrint('Cannot update reminder: NotificationService not initialized');
      return;
    }

    try {
      await cancelReminder(todo);
      if (todo.reminderTime != null) {
        await scheduleReminder(todo);
      }
      debugPrint('Reminder updated for todo "${todo.title}"');
    } catch (e) {
      debugPrint('Failed to update reminder: $e');
    }
  }
}
