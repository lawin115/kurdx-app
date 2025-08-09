// lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:kurdpoint/models/utils/notification_manager.dart';
import 'package:provider/provider.dart';

// ===== import-ەکان بە شێوازی دروست نووسراون =====
import 'package:kurdpoint/providers/auth_provider.dart';
import 'package:kurdpoint/providers/notification_provider.dart';
import 'package:kurdpoint/auction_detail_screen.dart';

import './api_service.dart';

class NotificationService {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // کلاسە پێویستەکان
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();

  // کلیلی گشتی بۆ گەیشتن بە Navigator
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // функцIAی سەرەki بۆ چالاککردن
  Future<void> initialize(String? token) async {
    // 1. وەرگرتنی ڕێگەپێدان
    await _firebaseMessaging.requestPermission();
    
    // 2. گوێگرەکان دابنێ
    _setupMessageListeners();

    // 3. وەرگرتنی تۆکن و ناردنی بۆ سێرڤەر (ئەگەر لۆگین بووبوو)
    final context = navigatorKey.currentContext;
    if (context != null) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        final fcmToken = await _firebaseMessaging.getToken();
        print("🔔 FCM Token: $fcmToken");
        if (fcmToken != null) {
          await _sendTokenToServer(fcmToken, token);
        }

        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          print("🔔 FCM Token Refreshed: $newToken");
          _sendTokenToServer(newToken, token);
        });
      }
    }
  }

  // --- функцIA یارمەتیدەرەکان ---

  Future<void> _sendTokenToServer(String fcmToken, String apiToken) async {
    try {
      await _apiService.updateFCMToken(fcmToken, apiToken);
    } catch (e) {
      print("!!! Failed to send FCM token to server: $e");
    }
  }

  void _setupMessageListeners() {
    // 1. کاتێک ئەپەکە کراوەیە (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground message received!");
      
      // پیشاندانی Flushbar
      NotificationManager.showInAppNotification(message);

      // نوێکردنەوەی Badge و لیستی ئاگادارکردنەوەکان
      final context = navigatorKey.currentContext;
      if (context != null) {
        final token = Provider.of<AuthProvider>(context, listen: false).token;
        if (token != null) {
           Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(token);
        }
      }
    });

    // 2. کاتێک کلیک لە ئاگادارکردنەوەکە دەکرێت (لە background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Message tapped (from background)!");
      handleMessageNavigation(message.data);
    });

    // 3. کاتێک ئەپەکە لە دۆخی داخراو (terminated) دەکرێتەوە
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print("App launched from terminated state by notification!");
        handleMessageNavigation(message.data);
      }
    });
  }

  // ===== چارەسەری هەڵەی 'private' =====
  // ئەم функцIAیە Publicـە
  void handleMessageNavigation(Map<String, dynamic> data) {
    final auctionId = data['auction_id'];
    if (auctionId != null) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AuctionDetailScreen(auctionId: int.parse(auctionId)),
          ),
        );
      }
    }
  }
}