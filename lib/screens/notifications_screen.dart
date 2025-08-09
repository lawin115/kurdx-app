// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../auction_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notifications = notificationProvider.notifications;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      
      appBar: AppBar(
        title: Text('ئاگادارییەکان',style: TextStyle(color: colorScheme.surfaceDim)),
       centerTitle: true,
        elevation: 0,
      backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () => notificationProvider.fetchNotifications(authProvider.token!),
        child: notifications.isEmpty
            ? const Center(child: Text('هیچ ئاگادارکردنەوەیەکی نوێ نییە.'))
            : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (ctx, index) {
                  final notification = notifications[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notification.isRead
                          ? Colors.grey.shade300
                          : Theme.of(context).primaryColor,
                      child: const Icon(Icons.notifications, color: Colors.white),
                    ),
                    title: Text(notification.message),
                    subtitle: Text('${notification.createdAt}'),
                    tileColor: notification.isRead ? null : Colors.indigo.withOpacity(0.05),
                    onTap: () {
                      // نیشانکردن وەک خوێندراوە
                      if (!notification.isRead) {
                        notificationProvider.markAsRead(notification.id, authProvider.token!);
                      }
                      // چوونە سەر لاپەڕەی مەزادەکە
                      if (notification.auctionId != null) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => AuctionDetailScreen(auctionId: notification.auctionId!),
                        ));
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}