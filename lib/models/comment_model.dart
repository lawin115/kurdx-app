// lib/models/comment_model.dart
import './user_model.dart';

class Comment {
  final int id;
  final String body;
  final User user;
  final List<Comment> replies;
  final DateTime createdAt;

  Comment({required this.id, required this.body, required this.user, required this.replies, required this.createdAt});

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'],
    body: json['body'],
    user: User.fromJson(json['user']),
    replies: json['replies'] == null ? [] : List<Comment>.from(json['replies'].map((x) => Comment.fromJson(x))),
    createdAt: DateTime.parse(json['created_at']),
  );
}