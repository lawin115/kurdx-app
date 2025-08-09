// lib/screens/blocked_users_screen.dart

import 'package:flutter/material.dart';
import 'package:kurdpoint/models/user_model.dart';
import 'package:kurdpoint/providers/auth_provider.dart';
import 'package:kurdpoint/services/api_service.dart';
import 'package:provider/provider.dart';
// ... (import-ەکانی تر)

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});
  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  late Future<List<User>?> _blockedUsersFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  void _loadBlockedUsers() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      _blockedUsersFuture = _apiService.getBlockedUsers(token);
    }
  }

  Future<void> _unblockUser(User userToUnblock) async {
     final token = Provider.of<AuthProvider>(context, listen: false).token!;
     final success = await _apiService.toggleBlockUser(userToUnblock.id, token);
     if (success) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text('${userToUnblock.name} ئەنبلۆک کرا.'),
         backgroundColor: Colors.green,
       ));
       setState(() {
         _loadBlockedUsers(); // Refresh the list
       });
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لیستی بەکارهێنەرە بلۆکراوەکان')),
      body: FutureBuilder<List<User>?>(
        future: _blockedUsersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('تۆ هیچ بەکارهێنەرێکت بلۆک نەکردووە.'));
          }
          
          final blockedUsers = snapshot.data!;
          
          return ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (ctx, index) {
              final user = blockedUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.profilePhotoUrl != null ? NetworkImage(user.profilePhotoUrl!) : null,
                  child: user.profilePhotoUrl == null ? Text(user.name[0]) : null,
                ),
                title: Text(user.name),
                // دوگمەی ئەنبلۆک
                trailing: OutlinedButton(
                  onPressed: () => _unblockUser(user),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                  child: const Text('ئەنبلۆک'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}