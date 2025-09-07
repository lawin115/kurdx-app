// lib/screens/order_detail_screen.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart'; 

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

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  String? _vendorPaymentDetails;
  bool _isLoadingPaymentDetails = true;
  bool _isConfirmingPayment = false;
  late Order _currentOrder;
  PusherChannelsClient? _pusherClient;
  bool _isRetryingConnection = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initPusher();
    _currentOrder = widget.order;
    if (_currentOrder.status == 'processing') {
      _fetchPaymentDetails();
    } else {
      setState(() => _isLoadingPaymentDetails = false);
    }
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    _pusherClient?.disconnect();
    super.dispose();
  }
  
  Future<void> _fetchPaymentDetails() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;
    
    final details = await _apiService.getOrderPaymentDetails(widget.order.id, token);
    if (mounted) {
      setState(() {
        _vendorPaymentDetails = details?['payment_details'];
        _isLoadingPaymentDetails = false;
      });
    }
  }
Future<void> _initPusher() async {
  if (_isRetryingConnection) return;
  _isRetryingConnection = true;

  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    final token = authProvider.token;

    if (userId == null || token == null) {
      print("[Pusher] User not logged in, aborting pusher connection.");
      return;
    }
    
    // ===== زانیارییە نوێیەکان =====
    const String domainHost = "ubuntu.tail73d562.ts.net";
    const String appKey = "qmkcqfx960e6h7q00qdp";
    final String channelName = 'private-users.$userId';

    // 1. دروستکردنی Options
    final hostOptions = PusherChannelsOptions.fromHost(
      scheme: 'wss', // 'wss' بۆ httpsـی سەلامەت
      host: domainHost,
      // پۆرتی ستانداردی 'wss' 443ـە و پێویست بە نووسین ناکات
      key: appKey,
    );
    
    // 2. دروستکردنی Client
    _pusherClient = PusherChannelsClient.websocket(
      options: hostOptions,
      connectionErrorHandler: (exception, trace, refresh) {
        print("!!! [Pusher] Connection Error: $exception");
        refresh();
      },
    );

    // 3. دروستکردنی چەناڵی تایبەت (Private Channel)
    final channel = _pusherClient!.privateChannel(
      channelName,
      // پێویستە Authorization Delegate دابنرێت
      authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
        authorizationEndpoint: Uri.parse('https://$domainHost/api/broadcasting/auth'), // URLـی دروست
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );
    
    // 4. گوێگرتن لە Eventـی نوێ
    channel.bind('OrderStatusUpdated').listen((event) {
      if (mounted && event.data != null) {
        try {
          final orderData = jsonDecode(event.data!)['order'];
          if (orderData['id'] == _currentOrder.id) {
            setState(() {
              _currentOrder = Order.fromJson(orderData);
              print("--- Order status updated via Pusher to: ${_currentOrder.status} ---");
            });
          }
        } catch (e) {
          print("!!! Error parsing OrderStatusUpdated: $e");
        }
      }
    });

    // 5. پەیوەستبوون و Subscribe کردن
    _pusherClient!.onConnectionEstablished.listen((_) {
      print("--- [Pusher] Connection established. Subscribing to $channelName ---");
      channel.subscribe();
    });

   

  

    await _pusherClient!.connect();
    _isRetryingConnection = false;
    
  } catch (e) {
    print("!!! Failed to init pusher on order detail screen: $e");
    
  }
}

  Future<void> _confirmPayment() async {
    setState(() => _isConfirmingPayment = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    final success = await _apiService.confirmPayment(widget.order.id, token);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پشتڕاستکرایەوە! فرۆشیار ئاگادار کرا.'), backgroundColor: Colors.green));
        setState(() {
          // دۆخی ناوخۆیی نوێ دەکەینەوە
          _currentOrder = _currentOrder.copyWith(status: 'paid'); 
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەڵەیەک ڕوویدا'), backgroundColor: Colors.red));
      }
    }
    setState(() => _isConfirmingPayment = false);
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
          child: _buildOrderDetailContent(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
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
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            automaticallyImplyLeading: true,
            iconTheme: const IconThemeData(color: Colors.white),
            toolbarHeight: 56,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order Details",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  "#${_currentOrder.id.toString().padLeft(8, '0')}",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
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
                  icon: Icon(Icons.share_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummaryCard(),
            const SizedBox(height: 20),
            _buildModernOrderStatusStepper(),
            const SizedBox(height: 20),
            _buildAuctionDetailsCard(),
            const SizedBox(height: 20),
            if (_currentOrder.status == 'processing') _buildModernPaymentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kModernPrimary, kModernAccent],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kModernTextPrimary,
                        ),
                      ),
                      Text(
                        "Order placed successfully",
                        style: TextStyle(
                          fontSize: 14,
                          color: kModernTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildModernStatusChip(_currentOrder.status),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kModernGreen.withOpacity(0.1),
                    kModernAccent.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: kModernGreen.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    color: kModernGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Final Price",
                        style: TextStyle(
                          fontSize: 14,
                          color: kModernTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        NumberFormat.simpleCurrency().format(_currentOrder.finalPrice),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kModernGreen,
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
    );
  }

  Widget _buildModernOrderStatusStepper() {
    final statuses = ['processing', 'shipped', 'out_for_delivery', 'delivered'];
    final currentStatusIndex = statuses.indexOf(_currentOrder.status);
    
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kModernBlue, kModernAccent],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.timeline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "Order Progress",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kModernTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...statuses.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isActive = index <= currentStatusIndex;
              final isCompleted = index < currentStatusIndex;
              final isCurrent = index == currentStatusIndex;
              
              return _buildStatusStep(status, isActive, isCompleted, isCurrent, index < statuses.length - 1);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStep(String status, bool isActive, bool isCompleted, bool isCurrent, bool hasLine) {
    final statusInfo = _getStatusInfo(status);
    
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: isActive 
                    ? LinearGradient(
                        colors: [statusInfo['color'], statusInfo['color'].withOpacity(0.7)],
                      )
                    : null,
                color: isActive ? null : kModernBorder,
                shape: BoxShape.circle,
                boxShadow: isActive ? [
                  BoxShadow(
                    color: statusInfo['color'].withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : statusInfo['icon'],
                color: isActive ? Colors.white : kModernTextLight,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusInfo['text'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? kModernTextPrimary : kModernTextLight,
                    ),
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Current status",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusInfo['color'],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (hasLine) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 25),
            width: 2,
            height: 24,
            decoration: BoxDecoration(
              gradient: isActive 
                  ? LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [statusInfo['color'], kModernBorder],
                    )
                  : null,
              color: isActive ? null : kModernBorder,
            ),
          ),
          const SizedBox(height: 8),
        ] else const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAuctionDetailsCard() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kModernOrange, kModernPink],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.gavel_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "Auction Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kModernTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildAuctionImage(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentOrder.auction.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kModernTextPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (_currentOrder.auction.description != null) ...[
                        Text(
                          _currentOrder.auction.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: kModernTextSecondary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                      ],
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                        },
                        icon: Icon(Icons.visibility_rounded, size: 18),
                        label: Text("View Auction"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kModernPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionImage() {
    return Container(
      width: 100,
      height: 100,
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
          imageUrl: _currentOrder.auction.images.isNotEmpty
              ? _currentOrder.auction.images.first.url
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
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernPaymentSection() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kModernGreen, kModernAccent],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.payment_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "Payment Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kModernTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kModernWarning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: kModernWarning.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: kModernWarning,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please send the payment to the vendor details below and confirm payment.',
                      style: TextStyle(
                        fontSize: 14,
                        color: kModernWarning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingPaymentDetails)
              _buildPaymentLoading()
            else if (_vendorPaymentDetails != null && _vendorPaymentDetails!.isNotEmpty)
              _buildPaymentDetails()
            else
              _buildNoPaymentDetails(),
            const SizedBox(height: 20),
            _buildPaymentConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentLoading() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kModernSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernPrimary, kModernAccent],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "Loading payment details...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: kModernTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kModernSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kModernBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_rounded,
                color: kModernPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Vendor Payment Details",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kModernTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _vendorPaymentDetails!,
            style: TextStyle(
              fontSize: 14,
              color: kModernTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kModernError.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kModernError.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: kModernError,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'No payment details available. Please contact the vendor.',
              style: TextStyle(
                fontSize: 14,
                color: kModernError,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentConfirmButton() {
    final canConfirm = _vendorPaymentDetails != null && _vendorPaymentDetails!.isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canConfirm && !_isConfirmingPayment ? _confirmPayment : null,
        icon: _isConfirmingPayment
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(Icons.check_circle_rounded, size: 20),
        label: Text(
          _isConfirmingPayment ? "Confirming..." : "Confirm Payment Sent",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canConfirm ? kModernGreen : kModernTextLight,
          foregroundColor: Colors.white,
          elevation: canConfirm ? 8 : 0,
          shadowColor: canConfirm ? kModernGreen.withOpacity(0.3) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
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

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending_payment':
        return {
          'color': kModernWarning,
          'text': 'Pending Payment',
          'icon': Icons.hourglass_top_rounded
        };
      case 'processing':
        return {
          'color': kModernBlue,
          'text': 'Processing',
          'icon': Icons.inventory_2_outlined
        };
      case 'shipped':
        return {
          'color': kModernPrimary,
          'text': 'Shipped',
          'icon': Icons.local_shipping_rounded
        };
      case 'out_for_delivery':
        return {
          'color': kModernOrange,
          'text': 'Out for Delivery',
          'icon': Icons.delivery_dining_rounded
        };
      case 'delivered':
        return {
          'color': kModernGreen,
          'text': 'Delivered',
          'icon': Icons.check_circle_rounded
        };
      case 'cancelled':
        return {
          'color': kModernError,
          'text': 'Cancelled',
          'icon': Icons.cancel_rounded
        };
      default:
        return {
          'color': kModernTextLight,
          'text': status.toUpperCase(),
          'icon': Icons.help_outline_rounded
        };
    }
  }
}