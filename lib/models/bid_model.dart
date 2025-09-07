import './user_model.dart';

class Bid {
  final int id;
  final double amount;
  final User user;
  final DateTime createdAt; 

  Bid({
    required this.id,
    required this.amount,
    required this.user,
    required this.createdAt,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['id'],
      amount: double.parse(json['amount'].toString()),
      user: json.containsKey('user') && json['user'] is Map<String, dynamic>
          ? User.fromJson(json['user'])
          : User(
              id: json['user_id'] ?? 0,
              name: 'Unknown User',
              email: '',
              role: 'user',
              profilePhotoUrl: null,
            ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'user': user.toJson(), // ئەمە بەکارهێنانی toJson لە User
        'created_at': createdAt.toIso8601String(),
      };
}
