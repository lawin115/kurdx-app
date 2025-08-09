import 'package:flutter/material.dart';
import 'package:kurdpoint/models/user_model.dart';
import 'package:kurdpoint/screens/pdf_preview_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../auction_detail_screen.dart';

class SoldAuctionsScreen extends StatefulWidget {
  const SoldAuctionsScreen({super.key});

  @override
  State<SoldAuctionsScreen> createState() => _SoldAuctionsScreenState();
}

class _SoldAuctionsScreenState extends State<SoldAuctionsScreen> {
  late Future<List<Order>?> _soldOrdersFuture;
  final ApiService _apiService = ApiService();

  @override
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      _soldOrdersFuture = _apiService.getSoldAuctions(token);
    } else {
      _soldOrdersFuture = Future.value([]); // ئەگər تۆکن نەبوو، لیستی بەتاڵ
    }
  }
  Future<void> _refresh() async {
    setState(() {
      _loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
     final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('مەزادە فرۆشراوەکانم',style: TextStyle(color: colorScheme.surfaceDim),),
         centerTitle: true,
        
         backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 1,
      ),
      body: FutureBuilder<List<Order>?>(
        future: _soldOrdersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return _buildErrorState();
          }
          
          final orders = snapshot.data!;
          
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('تۆ هێشتا هیچ مەزادێکت نەفرۆشتووە', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: orders.length,
              itemBuilder: (ctx, index) {
                return _buildSoldAuctionCard(orders[index], theme);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSoldAuctionCard(Order order, ThemeData theme) {
    final winner = order.user;
    final auction = order.auction;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 8.0),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: auction.coverImageUrl ?? "https://via.placeholder.com/150",
              width: 70, height: 70, fit: BoxFit.cover,
            ),
          ),
          title: Text(auction.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('فرۆشرا بە: ${NumberFormat.simpleCurrency().format(order.finalPrice)}'),
          children: <Widget>[
            const Divider(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('زانیاری براوە', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  // ===== چارەسەری هەڵەی null check =====
                  if (winner != null) ...[
                    _buildWinnerInfoRow(Icons.person_outline, winner.name),
                    const SizedBox(height: 8),
                    _buildWinnerInfoRow(Icons.phone_outlined, winner.phoneNumber ?? 'ژمارە تۆمارنەکراوە'),
                    const SizedBox(height: 8),
                    _buildWinnerInfoRow(Icons.location_on_outlined, winner.location ?? 'ناونیشان تۆمارنەکراوە'),
                  ] else
                    const Text('زانیاری براوە بەردەست نییە.'),
                  
                  const SizedBox(height: 12),
                   TextButton.icon(
                          icon: const Icon(Icons.block, color: Colors.red, size: 18),
                          label: const Text('بلۆک', style: TextStyle(color: Colors.red)),
                          onPressed: () => _showBlockConfirmationDialog(winner!),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                  const Divider(height: 24),
                 
SizedBox(
  width: double.infinity,
  child: FilledButton.icon(
    icon: const Icon(Icons.picture_as_pdf_outlined),
    label: const Text('دروستکردن و چاپکردنی پسووڵە'),
    style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
    onPressed: () {
      // چوونە ناو لاپەڕەی پێشبینی PDF
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => PdfPreviewScreen(order: order),
        ),
      );
    },
  ),
),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('گۆڕینی دۆخ:', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: order.status,
                        items: ['pending_payment','processing', 'shipped', 'out_for_delivery', 'delivered', 'cancelled']
                            .map((value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(_getStatusText(value)),
                                ))
                            .toList(),
                        onChanged: (newStatus) async {
                          if (newStatus != null && newStatus != order.status) {
                            final token = Provider.of<AuthProvider>(context, listen: false).token!;
                            final updated = await _apiService.updateOrderStatus(order.id, newStatus, token);
                            if (updated != null) _refresh(); 
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

    Future<void> _showBlockConfirmationDialog(User userToBlock) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('بلۆککردنی ${userToBlock.name}'),
        content: const Text('ئایا دڵنیایت دەتەوێت ئەم بەکارهێنەرە بلۆک بکەیت؟ دوای بلۆککردن, چیتر ناتوانێت مەزادەکانی تۆ ببینێت و بەشداری بکات.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('نەخێر')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('بەڵێ, بلۆکی بکە')),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _apiService.toggleBlockUser(userToBlock.id, token);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${userToBlock.name} بە سەرکەوتوویی بلۆک کرا.'), backgroundColor: Colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هەڵەیەک لە کاتی بلۆککردندا ڕوویدا.'), backgroundColor: Colors.red),
        );
      }
    }
  }
  Widget _buildWinnerInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }
String _getStatusText(String status) {
    switch (status) {
      case 'pending_payment': return 'چاوەڕێی پارەدان';
      case 'processing': return 'ئامادەکردن';
      case 'shipped': return 'نێردرا';
      case 'out_for_delivery': return 'بەرەو گەیاندن';
      case 'delivered': return 'گەیشت';
      case 'cancelled': return 'هەڵوەشێنرایەوە';
      default: return status;
    }
  }

  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text('هەڵەیەک لە وەرگرتنی داتادا ڕوویدا', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('دووبارە هەوڵبدەرەوە')),
        ],
      ),
    );
  }
}