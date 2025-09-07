
import 'package:flutter/material.dart';
import 'package:kurdpoint/auction_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/order_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import './pdf_preview_screen.dart';

class SoldAuctionsScreen extends StatefulWidget {
  const SoldAuctionsScreen({super.key});
  @override
  State<SoldAuctionsScreen> createState() => _SoldAuctionsScreenState();
}
const Color kModernPrimary = Color(0xFF6366F1); // Modern Purple
const Color kModernSecondary = Color(0xFFEC4899); // Hot Pink
const Color kModernAccent = Color(0xFF06B6D4); // Cyan
const Color kModernWarning = Color(0xFFFF9A56); // Orange
const Color kModernError = Color(0xFFEF4444); // Red
const Color kModernGradientStart = Color(0xFF667EEA); // Purple Blue
const Color kModernGradientEnd = Color(0xFF764BA2); // Deep Purple
const Color kModernPink = Color(0xFFF093FB); // Light Pink
const Color kModernBlue = Color(0xFF4FACFE); // Light Blue
const Color kModernOrange = Color(0xFFFF9A56); // Orange
const Color kModernGreen = Color(0xFF00F5A0); // Neon Green
const Color kModernDark = Color(0xFF1A1A2E); // Dark Background
const Color kModernSurface = Color(0xFFF8FAFC); // Light Surface
const Color kModernCard = Color(0xFFFFFFFF); // White Cards
const Color kModernTextPrimary = Color(0xFF0F172A); // Dark Text
const Color kModernTextSecondary = Color(0xFF64748B); // Gray Text
const Color kModernTextLight = Color(0xFF94A3B8); // Light Gray
const Color kModernBorder = Color(0xFFE2E8F0); // Subtle Border
class _SoldAuctionsScreenState extends State<SoldAuctionsScreen> {
  final ApiService _apiService = ApiService();
  
  List<Order>? _allOrders;
  List<Order> _filteredOrders = [];
  bool _isLoading = true;
  String _selectedFilterStatus = 'all';

  bool _isSelectionMode = false;
  final Set<int> _selectedOrderIds = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    // setState(() => _isLoading = true); // لابردنی ئەمە بۆ refreshـی جوانتر
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      _allOrders = await _apiService.getSoldAuctions(token);
      _filterOrders();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _filterOrders() {
    if (_allOrders == null) return;
    setState(() {
      if (_selectedFilterStatus == 'all') {
        _filteredOrders = List.from(_allOrders!);
      } else {
        _filteredOrders = _allOrders!.where((order) => order.status == _selectedFilterStatus).toList();
      }
    });
  }

  Future<void> _refresh() async {
    await _loadOrders();
    if (mounted) {
      setState(() {
        _isSelectionMode = false;
        _selectedOrderIds.clear();
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedOrderIds.clear();
    });
  }

  void _onOrderTap(Order order) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedOrderIds.contains(order.id)) {
          _selectedOrderIds.remove(order.id);
        } else if (order.status == 'processing' || order.status == 'ready_for_pickup') {
          _selectedOrderIds.add(order.id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تەنها دەتوانیت داواکاری ئامادەکراو هەڵبژێریت.'),
          ));
        }
      });
    } else {
      // ئەگەر لە دۆخی ئاساییدا بوو, وردەکارییەکانی ناو ExpansionTile پیشان دەدرێن
    }
  }

  Future<void> _showDriverSelectionDialog() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()), barrierDismissible: false);
    
    final drivers = await _apiService.getDrivers(token);
    if (!mounted) return;
    Navigator.of(context).pop();
    
    if (drivers == null || drivers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("هیچ شۆفێرێک بەردەست نییە.")));
        return;
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('شۆفێرێک هەڵبژێرە'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: drivers.length,
            itemBuilder: (listCtx, index) {
              final driver = drivers[index];
              return ListTile(
                leading: CircleAvatar(backgroundImage: driver.profilePhotoUrl != null ? NetworkImage(driver.profilePhotoUrl!) : null),
                title: Text(driver.name),
                onTap: () {
                   Navigator.of(ctx).pop();
                   _handoverSelectedOrders(driver.id);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handoverSelectedOrders(int driverId) async {
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    final success = await _apiService.handoverOrdersToDriver(_selectedOrderIds.toList(), driverId, token);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('داواکارییەکان بە سەرکەوتوویی ڕادەست کران'), backgroundColor: Colors.green));
      _refresh();
    } else if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەڵەیەک ڕوویدا'), backgroundColor: Colors.red));
    }
    if (mounted) setState(() => _isLoading = false);
  }
  
  // ===== کۆدی ناوەڕۆک =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedOrderIds.length} هەڵبژێردرا' : 'مەزادە فرۆشراوەکانم'),
     
        actions: [
          if (!_isSelectionMode)
            IconButton(icon: const Icon(Icons.checklist_rtl_outlined), tooltip: 'هەڵبژاردنی بەکۆمەڵ', onPressed: _toggleSelectionMode),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min, // Prevent overflow
              children: [
                _buildModernFilterChips(),
                Expanded(
                  child: _filteredOrders.isEmpty
                      ? _buildModernEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (ctx, index) => _buildModernSoldAuctionCard(_filteredOrders[index]),
                          ),
                           
                        ),
                        
                ),
                const SizedBox(height: 70),
              ],
            ),
     floatingActionButton: _isSelectionMode && _selectedOrderIds.isNotEmpty
    ? Column(
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          FloatingActionButton.extended(
            onPressed: _showDriverSelectionDialog,
            label: const Text('ڕادەستکردن بە شۆفێر'),
            icon: const Icon(Icons.local_shipping_outlined),
          ),
          const SizedBox(height: 70),
        ],
      )
    : null,
    );
   
  }

  // ===== ویجێتە یارمەتیدەرەکان =====

  Widget _buildModernFilterChips() {
    final statuses = ['all', 'processing', 'shipped', 'out_for_delivery', 'delivered', 'cancelled'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          Text(
            'Filter by Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kModernTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: statuses.length,
              itemBuilder: (context, index) {
                final status = statuses[index];
                final isSelected = _selectedFilterStatus == status;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilterStatus = status;
                      if (_isSelectionMode) _toggleSelectionMode();
                    });
                    _filterOrders();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [kModernPrimary, kModernAccent],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : kModernBorder,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: kModernPrimary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: kModernBorder.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Text(
                      status == 'all' ? 'هەموو' : _getStatusText(status),
                      style: TextStyle(
                        color: isSelected ? Colors.white : kModernTextSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (c, i) => const SizedBox(width: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSoldAuctionCard(Order order) {
    final winner = order.user;
    final auction = order.auction;
    final isSelected = _selectedOrderIds.contains(order.id);
    final isSelectable = order.status == 'processing' || order.status == 'ready_for_pickup';
    final statusInfo = _getStatusInfo(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? kModernPrimary : kModernBorder,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? kModernPrimary.withOpacity(0.2)
                : Colors.black.withOpacity(0.08),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: isSelectable
              ? () {
                  if (!_isSelectionMode) _toggleSelectionMode();
                  _onOrderTap(order);
                }
              : null,
          onTap: () => _onOrderTap(order),
          borderRadius: BorderRadius.circular(20),
          child: ExpansionTile(
            key: PageStorageKey(order.id),
            tilePadding: const EdgeInsets.all(16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            leading: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        kModernPrimary.withOpacity(0.1),
                        kModernAccent.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: auction.coverImageUrl ?? '',
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          color: kModernSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: kModernTextSecondary,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          color: kModernSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          size: 32,
                          color: kModernTextSecondary,
                        ),
                      ),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (_isSelectionMode)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? kModernPrimary.withOpacity(0.8)
                          : Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isSelectable
                          ? (isSelected ? Icons.check_circle : Icons.radio_button_unchecked)
                          : Icons.block,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
              ],
            ),
            title: Text(
              auction.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: kModernTextPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildStatusChip(order.status),
                const SizedBox(height: 8),
                Text(
                  'نرخی کۆتایی: ${order.finalPrice}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kModernAccent,
                  ),
                ),
              ],
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kModernSurface,
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (winner != null) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [kModernPrimary.withOpacity(0.1), kModernAccent.withOpacity(0.1)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.person_outline,
                              color: kModernPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'زانیاری براوە',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kModernTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildWinnerInfoRow(Icons.person_outline, winner.name),
                      const SizedBox(height: 12),
                      _buildWinnerInfoRow(Icons.phone_outlined, winner.phoneNumber ?? 'ژمارە تۆمارنەکراوە'),
                      const SizedBox(height: 12),
                      _buildWinnerInfoRow(Icons.location_on_outlined, winner.location ?? 'ناونیشان تۆمارنەکراوە'),
                      const SizedBox(height: 20),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kModernWarning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: kModernWarning.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_outlined,
                              color: kModernWarning,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'زانیاری براوە بەردەست نییە.',
                              style: TextStyle(
                                color: kModernWarning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    Container(
                      width: double.infinity,
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            kModernBorder,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildModernActionButton(
                            'پسووڵە',
                            Icons.picture_as_pdf_outlined,
                            [kModernError, const Color(0xFFDC2626)],
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => PdfPreviewScreen(order: order),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModernActionButton(
                            'بینینی مەزاد',
                            Icons.remove_red_eye_outlined,
                            [kModernPrimary, kModernAccent],
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AuctionDetailScreen(auctionId: order.auction.id),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildWinnerInfoRow(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kModernBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernAccent.withOpacity(0.1), kModernPrimary.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: kModernAccent,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: kModernTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusChip(String status) {
    final statusInfo = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusInfo['color'].withOpacity(0.1),
            statusInfo['color'].withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusInfo['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusInfo['icon'],
            color: statusInfo['color'],
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            statusInfo['text'],
            style: TextStyle(
              color: statusInfo['color'],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(
    String text,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onPressed,
  ) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        icon: Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
        label: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending_payment': return {'color': Colors.orange, 'text': 'چاوەڕێی پارەدان', 'icon': Icons.hourglass_top};
      case 'processing': return {'color': Colors.cyan, 'text': 'ئامادەکردن', 'icon': Icons.inventory_2_outlined};
      case 'ready_for_pickup': return {'color': Colors.blueAccent, 'text': 'ئامادەیە بۆ وەرگرتن', 'icon': Icons.inventory};
      case 'shipped': return {'color': Colors.blue, 'text': 'نێردرا', 'icon': Icons.local_shipping};
      case 'out_for_delivery': return {'color': Colors.purple, 'text': 'بەرەو گەیاندن', 'icon': Icons.delivery_dining};
      case 'delivered': return {'color': Colors.green, 'text': 'گەیشت', 'icon': Icons.check_circle};
      case 'cancelled': return {'color': Colors.red, 'text': 'هەڵوەشێنرایەوە', 'icon': Icons.cancel};
      default: return {'color': Colors.grey, 'text': status, 'icon': Icons.help_outline};
    }
  }

  String _getStatusText(String status) => _getStatusInfo(status)['text'];
  



  Widget _buildModernEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kModernPrimary.withOpacity(0.1),
                  kModernAccent.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 60,
              color: kModernTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'تۆ هێشتا هیچ مەزادێکت نەفرۆشتووە',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kModernTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'کاتێک مەزادەکانت دەفرۆشن، لێرە دەردەکەون',
            style: TextStyle(
              fontSize: 14,
              color: kModernTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
          TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('دووبارە هەوڵبدەرەوە')),
        ],
      ),
    );
  }

  /// ===== Block Confirmation =====
  Future<void> _showBlockConfirmationDialog(User userToBlock) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('بلۆککردنی ${userToBlock.name}'),
        content: const Text(
            'ئایا دڵنیایت دەتەوێت ئەم بەکارهێنەرە بلۆک بکەیت؟ دوای بلۆککردن، چیتر ناتوانێت مەزادەکانی تۆ ببینێت و بەشداری بکات.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('نەخێر')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('بەڵێ, بلۆکی بکە')),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _apiService.toggleBlockUser(userToBlock.id, token);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${userToBlock.name} بە سەرکەوتوویی بلۆک کرا.'),
              backgroundColor: Colors.green),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('هەڵەیەک لە کاتی بلۆککردندا ڕوویدا.'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  /// ===== Status Text =====

}
