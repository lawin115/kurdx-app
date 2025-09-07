import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kurdpoint/screens/order_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/data_cache_provider.dart';
import '../services/api_service.dart';
import '../auction_detail_screen.dart';

// Modern Professional Color Palette (matching other screens)
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

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with TickerProviderStateMixin {
  List<Order> _orders = [];
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  late AnimationController _animationController;
  late AnimationController _refreshAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  String _selectedFilter = 'All';
  List<String> _statusFilters = ['All', 'Processing', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCachedOrders();
  }
  
  void _loadCachedOrders() {
    final dataCacheProvider = Provider.of<DataCacheProvider>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    
    // Instagram-style: Always show cached data immediately
    setState(() {
      _orders = List.from(dataCacheProvider.orders);
    });
    
    if (dataCacheProvider.orders.isNotEmpty) {
      print("📱 Instagram-style orders: ${_orders.length} orders displayed instantly");
    }
    
    // Trigger background refresh without blocking UI
    if (token != null) {
      Future.microtask(() => dataCacheProvider.fetchOrders(token));
    }
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  Future<void> _refreshOrders() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final dataCacheProvider = Provider.of<DataCacheProvider>(context, listen: false);
    
    if (token == null) return;
    
    // Instagram-style: Only show loading if no cached data
    if (_orders.isEmpty) {
      setState(() => _isLoading = true);
    }
    
    try {
      await dataCacheProvider.fetchOrders(token, forceRefresh: true);
      
      // Update UI with fresh data
      setState(() {
        _orders = List.from(dataCacheProvider.orders);
        _isLoading = false;
      });
      
      print("📱 Orders updated in background");
    } catch (e) {
      setState(() => _isLoading = false);
      print("❌ Error refreshing orders: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kModernSurface,
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildOrdersContent(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(140),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kModernGradientStart,
              kModernGradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                automaticallyImplyLeading: true,
                iconTheme: const IconThemeData(color: Colors.white),
                toolbarHeight: 56,
                title: Text(
                  "My Orders",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 24,
                    letterSpacing: -0.5,
                  ),
                ),
                centerTitle: false,
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white, size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _refreshOrders();
                      },
                    ),
                  ),
                ],
              ),
              _buildStatusFilters(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilters.length,
        itemBuilder: (context, index) {
          final filter = _statusFilters[index];
          final isSelected = filter == _selectedFilter;
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? kModernPrimary : Colors.white,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 140),
      child: RefreshIndicator(
        onRefresh: _refreshOrders,
        color: kModernPrimary,
        backgroundColor: kModernCard,
        child: _isLoading && _orders.isEmpty
            ? _buildLoadingState()
            : _orders.isEmpty
                ? _buildEmptyState()
                : _buildOrdersList(_getFilteredOrders()),
      ),
    );
  }

  List<Order> _getFilteredOrders() {
    if (_selectedFilter == 'All') return _orders;
    return _orders.where((order) => 
        order.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernPrimary, kModernAccent],
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: kModernPrimary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Loading your orders...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kModernTextSecondary,
            ),
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kModernError.withOpacity(0.1),
                  kModernWarning.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: kModernError.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: kModernError,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Something went wrong",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kModernTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Unable to load your orders",
            style: TextStyle(
              fontSize: 14,
              color: kModernTextSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildRetryButton(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
              border: Border.all(
                color: kModernBorder,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 60,
              color: kModernTextLight,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No orders yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kModernTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start bidding on auctions to see your orders here",
            style: TextStyle(
              fontSize: 14,
              color: kModernTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildExploreButton(),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kModernOrange.withOpacity(0.1),
                  kModernPink.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.filter_list_off_rounded,
              size: 50,
              color: kModernTextLight,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No $_selectedFilter orders",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kModernTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try selecting a different filter",
            style: TextStyle(
              fontSize: 14,
              color: kModernTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: orders.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
      itemBuilder: (ctx, index) {
        final order = orders[index];
        return _buildModernOrderCard(order, index);
      },
    );
  }

  Widget _buildModernOrderCard(Order order, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: kModernCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => 
                      OrderDetailScreen(order: order),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderHeader(order),
                  const SizedBox(height: 16),
                  _buildOrderContent(order),
                  const SizedBox(height: 16),
                  _buildOrderFooter(order),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(Order order) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order #${order.id.toString().padLeft(8, '0')}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kModernTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Order Date: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}",
              style: TextStyle(
                fontSize: 12,
                color: kModernTextLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        _buildModernStatusChip(order.status),
      ],
    );
  }

  Widget _buildOrderContent(Order order) {
    return Row(
      children: [
        _buildModernOrderImage(order),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.auction.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kModernTextPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kModernGreen.withOpacity(0.1),
                      kModernAccent.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: kModernGreen.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      size: 16,
                      color: kModernGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${NumberFormat.simpleCurrency().format(order.finalPrice)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kModernGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernOrderImage(Order order) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: order.auction.images.isNotEmpty
              ? order.auction.images.first.url
              : '',
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kModernPrimary.withOpacity(0.1),
                  kModernAccent.withOpacity(0.1),
                ],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: kModernPrimary,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kModernPrimary.withOpacity(0.1),
                  kModernAccent.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.image_not_supported_rounded,
              color: kModernTextLight,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderFooter(Order order) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(order: order),
                ),
              );
            },
            icon: Icon(
              Icons.visibility_rounded,
              size: 18,
              color: kModernPrimary,
            ),
            label: Text(
              "View Details",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: kModernPrimary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: kModernPrimary.withOpacity(0.3),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              // Navigate to auction detail
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AuctionDetailScreen(auctionId: order.auction.id),
                ),
              );
            },
            icon: Icon(
              Icons.gavel_rounded,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              "View Auction",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kModernPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatusChip(String status) {
    final statusInfo = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusInfo['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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
            size: 16,
            color: statusInfo['color'],
          ),
          const SizedBox(width: 6),
          Text(
            statusInfo['text'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusInfo['color'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _refreshOrders();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kModernError, kModernWarning],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: kModernError.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "Try Again",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Navigate to explore screen
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kModernPrimary, kModernAccent],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: kModernPrimary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "Explore Auctions",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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

