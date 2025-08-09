import 'package:flutter/material.dart';
import 'package:kurdpoint/screens/order_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../auction_detail_screen.dart'; // بۆ ئەوەی بتوانین بگەڕێینەوە سەر لاپەڕەی مەزاد

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late Future<List<Order>?> _ordersFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // وەرگرتنی تۆکنی بەکارهێنەر و داواکردنی داتا
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      _ordersFuture = _apiService.getMyOrders(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
 final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title:  Text('مەزادە براوەکانم',style: TextStyle(color: colorScheme.surfaceDim)),
         centerTitle: true,
        elevation: 0,
      backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        
      ),
    body: FutureBuilder<List<Order>?>(
  future: _ordersFuture,
  builder: (context, snapshot) {
    // ===== printـی نوێ بۆ پشکنین =====
    print("Snapshot Connection State: ${snapshot.connectionState}");
    if (snapshot.hasError) {
      print("!!! Snapshot Error: ${snapshot.error}");
    }
    if (snapshot.hasData) {
      print("--- Snapshot has data. Number of orders: ${snapshot.data!.length} ---");
    }
    
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
          
          final orders = snapshot.data!;
          
          // حاڵەتی نەبوونی هیچ داواکارییەک
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('تۆ هێشتا هیچ مەزادێکت نەبردۆتەوە', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          // حاڵەتی سەرکەوتوو
          return RefreshIndicator(
            onRefresh: () async {
              final token = Provider.of<AuthProvider>(context, listen: false).token;
              if (token != null) {
                setState(() {
                  _ordersFuture = _apiService.getMyOrders(token);
                });
              }
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: orders.length,
              itemBuilder: (ctx, index) {
                final order = orders[index];
                return _buildOrderCard(order, theme);
              },
            ),
          );
        },
      ),
    );
  }

  // ویجێتێک بۆ دروستکردنی کاردی هەر داواکارییەک
  Widget _buildOrderCard(Order order, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: InkWell(
        onTap: () {
          // TODO: بەکارهێنەر بنێرە بۆ لاپەڕەی وردەکاری داواکارییەکە
          // Navigator.of(context).push(...);
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // وێنەی بچووککراوەی مەزادەکە
                ClipRRect(
  borderRadius: BorderRadius.circular(8.0), // Example border radius
  child: CachedNetworkImage(
    imageUrl: order.auction.images.isNotEmpty
        ? order.auction.images.first.url
        : '', // Provide an empty string or dummy URL if no image,
              // as errorWidget will handle the fallback.
    width: 100,
    height: 100,
    fit: BoxFit.cover,
    placeholder: (context, url) => Container(
      color: Colors.grey[200],
      // Optional: Add a small loading indicator if desired
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    ),
    errorWidget: (context, url, error) => Image.asset(
      'assets/bid.png', // Your local asset path
      width: 100,
      height: 100,
      fit: BoxFit.cover,
      // You can add a small error icon here if the image itself failed to load
      // child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
    ),
  ),
),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.auction.title,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'نرخی کۆتایی: ${NumberFormat.simpleCurrency().format(order.finalPrice)}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusChip(order.status),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // دوگمەیەک بۆ بینینی مەزادە ڕەسەنەکە
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                onPressed: () {
                     Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
                  },
                  child: const Text('بینینی لاپەڕەی مەزاد'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ویجێتێک بۆ پیشاندانی دۆخی داواکاری
    Widget _buildStatusChip(String status) {
    final Map<String, dynamic> statusInfo = _getStatusInfo(status);
    return Chip(
      avatar: Icon(statusInfo['icon'], color: statusInfo['color'], size: 18),
      label: Text(statusInfo['text'], style: TextStyle(fontWeight: FontWeight.bold, color: statusInfo['color'])),
      backgroundColor: statusInfo['color'].withOpacity(0.15),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
    );
  }
  
  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending_payment': return {'color': Colors.orange, 'text': 'چاوەڕێی پارەدان', 'icon': Icons.hourglass_top};
      case 'processing': return {'color': Colors.cyan, 'text': 'ئامادەکردن', 'icon': Icons.inventory_2_outlined};
      case 'shipped': return {'color': Colors.blue, 'text': 'نێردرا', 'icon': Icons.local_shipping};
      case 'out_for_delivery': return {'color': Colors.purple, 'text': 'بەرەو گەیاندن', 'icon': Icons.delivery_dining};
      case 'delivered': return {'color': Colors.green, 'text': 'گەیشت', 'icon': Icons.check_circle};
      case 'cancelled': return {'color': Colors.red, 'text': 'هەڵوەشێنرایەوە', 'icon': Icons.cancel};
      default: return {'color': Colors.grey, 'text': status, 'icon': Icons.help_outline};
    }
  }
  
  }

