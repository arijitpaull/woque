import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:woke/question_hive.dart';
import 'package:woke/ai_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize() async {
    if (_isInitialized) {
      return; 
    }
    
    try {
      _notificationsPlugin = FlutterLocalNotificationsPlugin();
      
      
      tz.initializeTimeZones();
      
      const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          
        },
      );
      
      _isInitialized = true;
      debugPrint('Notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
      
    }
  }

  Future<void> scheduleAllNotifications() async {
    
    if (!_isInitialized) {
      debugPrint('Notification service not initialized, attempting to initialize');
      await initialize();
      
      
      if (!_isInitialized) {
        debugPrint('Could not initialize notification service, skipping scheduling');
        return;
      }
    }
    
    try {
      
      final String? todaysAnswer = await getAnswerForToday();
      final bool hasAnsweredToday = todaysAnswer != null && todaysAnswer.isNotEmpty;

      
      if (!hasAnsweredToday) {
        await _scheduleDailyQuestionReminders();
      } else {
        
        await cancelQuestionReminders();
      }

      
      await scheduleJournalReminder();
      
      
      try {
        await scheduleRandomGrowthFact();
      } catch (e) {
        debugPrint('Error scheduling growth fact notification: $e');
        
      }
      
      debugPrint('All notifications scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
      
    }
  }

  
  Future<void> cancelQuestionReminders() async {
    if (!_isInitialized) return;
    
    try {
      
      for (int i = 0; i < 10; i++) {
        await _notificationsPlugin.cancel(100 + i);
      }
    } catch (e) {
      debugPrint('Error canceling question reminders: $e');
    }
  }

  Future<void> _scheduleDailyQuestionReminders() async {
    if (!_isInitialized) return;
    
    try {
      const notificationId = 100;
      const String channelId = 'daily_question_reminders';
      const String channelName = 'Daily Question Reminders';
      const String channelDesc = 'Reminders to answer today\'s question';

      
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: false,
        );

      const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

      
      final List<String> reminderMessages = [
        'Take a moment to answer today\'s question',
        'Your daily reflection question is waiting for you',
        'A few minutes of reflection can change your day. Answer your question.',
        'Don\'t forget to complete your daily reflection',
        'Time for self-reflection! Your daily question awaits',
        'Pause and reflect: Today\'s question is still unanswered'
      ];

      
      final times = [
        TimeOfDay(hour: 9, minute: 0),    
        TimeOfDay(hour: 12, minute: 0),   
        TimeOfDay(hour: 15, minute: 0),   
        TimeOfDay(hour: 18, minute: 0),   
        TimeOfDay(hour: 21, minute: 0),   
        TimeOfDay(hour: 23, minute: 30),  
      ];

      
      final now = DateTime.now();
      final currentTimeOfDay = TimeOfDay.fromDateTime(now);

      for (int i = 0; i < times.length; i++) {
        final time = times[i];
        
        
        if (_isTimeAfter(time, currentTimeOfDay)) {
          
          final message = reminderMessages[i % reminderMessages.length];
          
          await _notificationsPlugin.zonedSchedule(
            notificationId + i,
            'Daily Reflection',
            message,
            _nextInstanceOfTime(time.hour, time.minute),
            platformChannelSpecifics,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: 'daily_question',
          );
        }
      }
    } catch (e) {
      debugPrint('Error scheduling daily question reminders: $e');
    }
  }

  
  bool _isTimeAfter(TimeOfDay time, TimeOfDay currentTime) {
    return time.hour > currentTime.hour || 
           (time.hour == currentTime.hour && time.minute > currentTime.minute);
  }

  Future<void> scheduleJournalReminder() async {
    if (!_isInitialized) return;
    
    try {
      const notificationId = 200;
      const String channelId = 'journal_reminders';
      const String channelName = 'Journal Reminders';
      const String channelDesc = 'Reminders to write journal entries';

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: false,
        );

      const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Journal Time',
        'Write in your journal today',
        _nextInstanceOfTime(17, 0), 
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'journal_entry',
      );
    } catch (e) {
      debugPrint('Error scheduling journal reminder: $e');
    }
  }

  Future<void> scheduleRandomGrowthFact() async {
    if (!_isInitialized) return;
    
    try {
      const notificationId = 300;
      const String channelId = 'growth_facts';
      const String channelName = 'Growth Facts';
      const String channelDesc = 'Random facts about your growth';

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: false,
          styleInformation: BigTextStyleInformation(''), 
        );

      const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

      
      final randomTime = TimeOfDay(
        hour: 10 + (DateTime.now().millisecond % 10), 
        minute: DateTime.now().second % 60,
      );

      
      String factoid;
      try {
        
        factoid = await AiService.getGrowthFactoid();
      } catch (e) {
        debugPrint('Error getting growth factoid: $e');
        
        factoid = "Check your progress insights in the app";
      }
      
      final String previewFactoid = _createFactoidPreview(factoid);

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        'Growth Insight',
        previewFactoid,
        _nextInstanceOfTime(randomTime.hour, randomTime.minute),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'growth_fact',
      );
    } catch (e) {
      debugPrint('Error scheduling growth fact: $e');
    }
  }

  
  String _createFactoidPreview(String factoid) {
    
    if (factoid.length <= 100) return factoid;
    
    
    return "${factoid.substring(0, 97)}...";
  }
  
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }

  
  Future<void> onQuestionAnswered() async {
    if (!_isInitialized) return;
    
    try {
      
      await cancelQuestionReminders();
    } catch (e) {
      debugPrint('Error handling question answered: $e');
    }
  }

  Future<void> checkAndShowQuestionReminder() async {
    if (!_isInitialized) return;
    
    try {
      final String? todaysAnswer = await getAnswerForToday();
      final bool hasAnswered = todaysAnswer != null && todaysAnswer.isNotEmpty;
      
      if (!hasAnswered) {
        await _showQuestionReminderNow();
      }
    } catch (e) {
      debugPrint('Error checking question reminder: $e');
    }
  }

  Future<void> _showQuestionReminderNow() async {
    if (!_isInitialized) return;
    
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'daily_question_reminders',
          'Daily Question Reminders',
          channelDescription: 'Reminders to answer today\'s question',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: false,
        );

      const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

      await _notificationsPlugin.show(
        400, 
        'Daily Reflection',
        'You haven\'t answered today\'s question yet',
        platformChannelSpecifics,
        payload: 'daily_question_now',
      );
    } catch (e) {
      debugPrint('Error showing question reminder: $e');
    }
  }
}