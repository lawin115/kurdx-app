// lib/utils/notification_manager.dart

import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cached_network_image/cached_network_image.dart'; // importـی نوێ
import '/services/notification_service.dart'; // بۆ گەیشتن بە navigatorKey

class NotificationManager {
  static void showInAppNotification(RemoteMessage message) {
    // ===== گرنگ: وەرگرتنی context لە navigatorKey =====
    // ئەمە وا دەکات بتوانین لە هەر شوێنێکەوە Flushbar پیشان بدەین
    final context = NotificationService.navigatorKey.currentContext;
    if (context == null) return;
    
    final notification = message.notification;
    if (notification == null) return;

    final String? senderProfileUrl = message.data['sender_profile_url'];

    // داخستنی هەر flushbarـێکی پێشوو
    Flushbar().dismiss();
    
    Flushbar(
      // ===== دیزاینی نوێ و پرۆfeshnal =====
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(12),
      backgroundColor: Theme.of(context).cardColor,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
      duration: const Duration(seconds: 5),
      
      // ناوەڕۆکی Flushbar
      titleText: Text(
        notification.title ?? 'ئاگادارکردنەوەی نوێ',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      messageText: Text(
        notification.body ?? '',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
      ),
      
      // ئایکۆن
      icon: CircleAvatar(
        radius: 22,
        
        backgroundImage: senderProfileUrl != null && senderProfileUrl.isNotEmpty
            ? CachedNetworkImageProvider(senderProfileUrl)
            : null,
        child: senderProfileUrl == null || senderProfileUrl.isEmpty
            ? const Icon(Icons.notifications_active, size: 24)
            : null,
      ),

      // دوگمەی "بینین"
      mainButton: TextButton(
        onPressed: () {
          // کاتێک کلیکی لێدەکات، Flushbarـەکە دابخە و بچۆ بۆ لاپەڕەکه
          Flushbar().dismiss();
         NotificationManager.showInAppNotification(message); 
        },
        child: const Text('بینین'),
      ),
      
      // شێوازی دەرکەوتن
      flushbarPosition: FlushbarPosition.TOP,
      animationDuration: const Duration(milliseconds: 500),
      
    ).show(context);
  }
}