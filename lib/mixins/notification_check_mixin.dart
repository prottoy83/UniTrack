import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../widgets/attendance_popup.dart';

mixin NotificationCheckMixin<T extends StatefulWidget> on State<T> {
  
  void initNotificationCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNotifications();
    });
  }

  Future<void> _checkPendingNotifications() async {
    try {
      debugPrint('🔔 Checking for pending notifications...');
      final pendingNotifications = await NotificationService().getPendingNotifications();
      debugPrint('🔔 Found ${pendingNotifications.length} pending notifications');
      
      if (pendingNotifications.isNotEmpty && mounted) {
        debugPrint('🔔 Showing pending notification popup');
        // Show the first pending notification
        AttendancePopupOverlay.show(context, pendingNotifications.first);
      }
    } catch (e) {
      debugPrint('❌ Error checking pending notifications: $e');
    }
  }

  // Method to manually add a test pending notification
  Future<void> addTestPendingNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingList = prefs.getStringList('pending_notifications') ?? [];
      
      final testNotification = {
        'notificationId': 99999,
        'courseId': 1,
        'courseName': 'Test Course',
        'scheduleId': 1,
        'scheduledTime': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
      };
      
      pendingList.add(jsonEncode(testNotification));
      await prefs.setStringList('pending_notifications', pendingList);
      debugPrint('✅ Added test pending notification');
      
      // Trigger check
      await _checkPendingNotifications();
    } catch (e) {
      debugPrint('❌ Error adding test notification: $e');
    }
  }
}