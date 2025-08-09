// lib/models/notification_model.dart

class NotificationModel {
  final String id;
  final String message;
  final DateTime createdAt;
  final int? auctionId;
  
  // ===== گۆڕانکاری گرنگ لێرەدایە =====
  // وشەی 'final'-مان لەسەر 'isRead' لاداوە
  bool isRead; 

  NotificationModel({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.auctionId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      message: json['data']['message'] ?? 'پەیامی نوێ',
      // دڵنیابوونەوە لەوەی 'read_at' بوونی هەیە یان نا
      isRead: json['read_at'] != null,
      createdAt: DateTime.parse(json['created_at']),
      auctionId: json['data']['auction_id'],
    );
  }
}