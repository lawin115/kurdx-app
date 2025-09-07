// lib/screens/manage_drivers_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ManageDriversScreen extends StatefulWidget {
  const ManageDriversScreen({super.key});
  @override
  State<ManageDriversScreen> createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  late Future<List<User>?> _driversFuture;
  final ApiService _apiService = ApiService();
  
  // Controllers and Keys for the "Add Driver" Dialog
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  void _loadDrivers() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      _driversFuture = _apiService.getDrivers(token);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loadDrivers();
    });
  }

  Future<void> _onAddDriverPressed() async {
    // پاککردنەوەی خانەکان پێش کردنەوەی دیالۆگ
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();

    final bool? success = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("زیادکردنی شۆفێری نوێ"),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "ناوی تەواو"),
                  validator: (v) => v!.isEmpty ? 'نابێت بەتاڵ بێت' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "ئیمەیڵ"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty || !v.contains('@') ? 'ئیمەیڵێکی دروست نییە' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: "وشەی نهێنی کاتی"),
                  obscureText: true,
                  validator: (v) => v!.length < 8 ? 'دەبێت لە 8 پیت کەمتر نەبێت' : null,
                ),
              ],

            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("لابردن")),
          FilledButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final token = Provider.of<AuthProvider>(context, listen: false).token!;
                final newUser = await _apiService.createDriver({
                  'name': _nameController.text,
                  'email': _emailController.text,
                  'password': _passwordController.text,
                }, token);
                
                if (ctx.mounted) {
                   Navigator.of(ctx).pop(newUser != null);
                }
              }
            },
            child: const Text("زیادکردن"),
          ),
        ],
      ),
    );

    if (success == true) {
      _refresh(); // دوای زیادکردنی سەرکەوتوو, لیستەکە نوێ بکەرەوە
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شۆفێر بە سەرکەوتوویی زیادکرا'), backgroundColor: Colors.green),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بەڕێوەبردنی شۆفێرەکان'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _onAddDriverPressed,
            tooltip: 'زیادکردنی شۆفێر',
          ),
        ],
      ),
      body: FutureBuilder<List<User>?>(
        future: _driversFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('هیچ شۆفێرێک تۆمار نەکراوە.'));
          }
          final drivers = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (ctx, index) {
                final driver = drivers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: driver.profilePhotoUrl != null ? NetworkImage(driver.profilePhotoUrl!) : null,
                      child: driver.profilePhotoUrl == null ? Text(driver.name[0]) : null,
                    ),
                    title: Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(driver.email),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () { /* TODO: لێرەدا دەتوانیت menuـیەک بۆ سڕینەوە دابنێیت */ },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}