// lib/models/conversation_model.dart
import './user_model.dart';
import './message_model.dart';

class Conversation {
  final int id;
  final User otherUser;
  final Message? latestMessage;

  Conversation({required this.id, required this.otherUser, this.latestMessage});

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'],
    otherUser: User.fromJson(json['otherUser']),
    latestMessage: json['latest_message'] == null ? null : Message.fromJson(json['latest_message']),
  );
}