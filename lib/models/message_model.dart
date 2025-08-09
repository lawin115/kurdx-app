import './user_model.dart';
import './auction_model.dart';

class Message {
  final int id;
  final String? body;
  final User user;
  final DateTime createdAt;
  final String type;
  final Auction? auction;

  Message({
    required this.id, this.body, required this.user, required this.createdAt,
    required this.type, this.auction,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      body: json['body'],
      user: User.fromJson(json['user']),
      createdAt: DateTime.parse(json['created_at']),
      type: json['type'] ?? 'text',
      auction: json['auction_from_metadata'] != null
               ? Auction.fromJson(json['auction_from_metadata'])
               : null,
    );
  }
}