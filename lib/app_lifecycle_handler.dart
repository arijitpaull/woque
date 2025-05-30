import 'package:flutter/material.dart';
import 'package:woke/notification_service.dart';

class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notificationService = NotificationService();
    
    if (state == AppLifecycleState.resumed) {
      
      notificationService.checkAndShowQuestionReminder();
      
      
      notificationService.scheduleAllNotifications();
    }
  }
}