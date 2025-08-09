// lib/models/bid_model.dart
import './user_model.dart';

class Bid {
  final int id;
  final double amount;
  final User user;
  
  // ===== گۆڕانکاری یەکەم: ناوی گۆڕاوەکەمان کرد بە createdAt =====
  final DateTime createdAt; 

  Bid({
    required this.id,
    required this.amount,
    required this.user,
    required this.createdAt, // <-- لێرەشدا گۆڕدرا
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    // ===== گۆڕانکاری دووەم: چاککردنی لۆجیک =====
    return Bid(
      id: json['id'],
      amount: double.parse(json['amount'].toString()),
      
      // پشکنین دەکەین: ئەگەر ئۆبجێکتی 'user' بە تەواوی هاتبوو، ئەوە بەکاربهێنە
      user: json.containsKey('user') && json['user'] is Map<String, dynamic>
            ? User.fromJson(json['user'])
            // ئەگەرنا، userـێکی کاتی دروست بکە
            : User(
                id: json['user_id'] ?? 0,
                name: 'Unknown User',
                email: '',
                role: 'user',
                profilePhotoUrl: null
              ),
              
      // createdAt هەمیشە لە APIـیەوە دێت
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}