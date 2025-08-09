// lib/providers/notification_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> fetchNotifications(String token) async {
    final fetchedNotifications = await _apiService.getNotifications(token);
    if (fetchedNotifications != null) {
      _notifications = fetchedNotifications;
      _calculateUnreadCount();
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId, String token) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1 || _notifications[index].isRead) return;

    // --- Optimistic UI Update ---
    // 1. یەکسەر لە UIـدا دۆخەکە بگۆڕە
    _notifications[index].isRead = true;
    _calculateUnreadCount();
    notifyListeners();

    // 2. داواکارییەکە بۆ سێرڤەر بنێرە
    final success = await _apiService.markNotificationAsRead(notificationId, token);

    // 3. ئەگەر هەڵەیەک ڕوویدا، گۆڕانکارییەکە هەڵبوەشێنەرەوە
    if (!success) {
      _notifications[index].isRead = false;
      _calculateUnreadCount();
      notifyListeners();
      // TODO: پەیامێکی هەڵە پیشان بدە
    }
  }

  // ===== функцIAی نوێ بۆ وەرگرتنی ئاگادارکردنەوەی زیندوو =====
  void addNewNotificationFromMessage(RemoteMessage message) {
    if (message.data['id'] == null) return;

    // دروستکردنی ئۆبجێکتێکی NotificationModel لە پەیامەکەوە
    final newNotification = NotificationModel(
      id: message.data['id'],
      message: message.notification?.body ?? 'پەیامی نوێ',
      createdAt: DateTime.now(),
      isRead: false,
      auctionId: message.data['auction_id'] != null ? int.parse(message.data['auction_id']) : null,
    );
    
    // زیادکردنی بۆ سەرەتای لیستەکە
    _notifications.insert(0, newNotification);
    _calculateUnreadCount();
    
    notifyListeners();
  }
  
  // функцIAیەکی یارمەتیدەر بۆ دووبارە نەبوونەوەی کۆد
  void _calculateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }
}