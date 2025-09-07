// lib/models/comment_model.dart
import './user_model.dart';

class Comment {
  final int id;
  final String body;
  final User user;
  final List<Comment> replies;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.body,
    required this.user,
    required this.replies,
    required this.createdAt,
  });

  // ---- Safe parsers ----
  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  static DateTime _toDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: _toInt(json['id']),
        body: (json['body'] ?? '').toString(),
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        replies: (json['replies'] as List?)
                ?.map((x) => Comment.fromJson(x as Map<String, dynamic>))
                .toList() ??
            const <Comment>[],
        createdAt: _toDate(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'body': body,
        'user': user.toJson(), // پێویستە User.toJson هەبێت
        'replies': replies.map((c) => c.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
      };

  Comment copyWith({
    int? id,
    String? body,
    User? user,
    List<Comment>? replies,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      body: body ?? this.body,
      user: user ?? this.user,
      replies: replies ?? this.replies,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // یارمەتی بۆ لیست
  static List<Comment> listFromJson(List data) =>
      data.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
}
