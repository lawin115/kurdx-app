// lib/screens/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:kurdpoint/models/conversation_model.dart';
import 'package:kurdpoint/providers/auth_provider.dart';
import 'package:kurdpoint/screens/chat_screen.dart';
import 'package:kurdpoint/services/api_service.dart';
import 'package:provider/provider.dart';
// ... importـەکانی تر (Conversation, ApiService, AuthProvider, ChatScreen) ...

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<Conversation>?> _conversationsFuture;
  
  @override
  void initState() {
    super.initState();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _conversationsFuture = ApiService().getConversations(token!);
  }

  @override
  Widget build(BuildContext context) {
        final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title:  Text('نامەکان' ,style: TextStyle(color: colorScheme.primary)),
       centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onPrimary,
      
      ),
      body: FutureBuilder<List<Conversation>?>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('هیچ نامەیەکت نییە.'));
          }
          final conversations = snapshot.data!;
          return ListView.separated(
            itemCount: conversations.length,
            itemBuilder: (ctx, index) {
              final convo = conversations[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 28,
                  backgroundImage: convo.otherUser.profilePhotoUrl != null
                      ? NetworkImage(convo.otherUser.profilePhotoUrl!)
                      : null,
                  child: convo.otherUser.profilePhotoUrl == null ? Text(convo.otherUser.name[0]) : null,
                ),
                title: Text(convo.otherUser.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  convo.latestMessage?.body ?? 'هیچ پەیامێک نییە',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      conversationId: convo.id,
                      otherUser: convo.otherUser,
                    ),
                  ));
                },
              );
            },
            separatorBuilder: (ctx, index) => const Divider(indent: 80),
          );
        },
      ),
    );
  }
}