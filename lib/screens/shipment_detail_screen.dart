import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/shipment_model.dart';
import '../models/order_model.dart';

// Modern Professional Color Palette (matching app design system)
const Color kModernPrimary = Color(0xFF6366F1); // Modern Purple
const Color kModernSecondary = Color(0xFFEC4899); // Hot Pink
const Color kModernAccent = Color(0xFF06B6D4); // Cyan
const Color kModernWarning = Color(0xFFFF9A56); // Orange
const Color kModernError = Color(0xFFEF4444); // Red
const Color kModernSuccess = Color(0xFF10B981); // Green
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

class ShipmentDetailScreen extends StatefulWidget {
  final Shipment shipment;
  const ShipmentDetailScreen({super.key, required this.shipment});

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _headerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
    _headerController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _headerController.dispose();
    super.dispose();
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
          child: _buildBody(),
        ),
      ),
    );
  }
  
  PreferredSizeWidget _buildModernAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
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
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              leading: Container(
                margin: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Text(
                      'Shipment Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    'Shipment #${widget.shipment.id}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              centerTitle: false,
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.print_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _printShipment();
                    },
                  ),
                ),
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
                    icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _shareShipment();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildBody() {
    return Container(
      margin: const EdgeInsets.only(top: 120),
      child: Column(
        children: [
          _buildShipmentSummary(),
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShipmentSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kModernCard,
            kModernSurface,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: kModernBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kModernPrimary, kModernAccent],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kModernPrimary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Value',
                      style: TextStyle(
                        fontSize: 14,
                        color: kModernTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(symbol: 'IQD ').format(widget.shipment.totalValue),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: kModernTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(widget.shipment.status),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Orders',
                  '${widget.shipment.orders.length}',
                  Icons.inventory_2_rounded,
                  kModernWarning,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: kModernBorder,
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Delivered',
                  '${widget.shipment.orders.where((o) => o.status == 'delivered').length}',
                  Icons.check_circle_rounded,
                  kModernSuccess,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: kModernBorder,
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Pending',
                  '${widget.shipment.orders.where((o) => o.status == 'pending').length}',
                  Icons.schedule_rounded,
                  kModernWarning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kModernTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: kModernTextSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;
    
    switch (status.toLowerCase()) {
      case 'delivered':
        color = kModernSuccess;
        text = 'Delivered';
        icon = Icons.check_circle_rounded;
        break;
      case 'pending':
        color = kModernWarning;
        text = 'Pending';
        icon = Icons.schedule_rounded;
        break;
      case 'cancelled':
        color = kModernError;
        text = 'Cancelled';
        icon = Icons.cancel_rounded;
        break;
      default:
        color = kModernTextSecondary;
        text = status;
        icon = Icons.info_rounded;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: widget.shipment.orders.length,
      itemBuilder: (ctx, index) {
        final order = widget.shipment.orders[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _buildModernOrderCard(order, index),
        );
      },
    );
  }
  
  Widget _buildModernOrderCard(Order order, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kModernCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kModernBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: ExpansionTile(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            childrenPadding: EdgeInsets.zero,
            title: Text(
              order.auction.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kModernTextPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Customer: ${order.user?.name ?? 'Unknown'}',
                style: TextStyle(
                  fontSize: 14,
                  color: kModernTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kModernPrimary.withOpacity(0.1),
                    kModernAccent.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kModernPrimary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                color: kModernPrimary,
                size: 24,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusBadge(order.status),
                const SizedBox(width: 8),
                Icon(
                  Icons.expand_more_rounded,
                  color: kModernTextSecondary,
                ),
              ],
            ),
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kModernSurface.withOpacity(0.5),
                      kModernCard,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 1,
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
                      const SizedBox(height: 20),
                      Text(
                        'Customer Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kModernTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildModernInfoTile(
                        Icons.person_rounded,
                        'Customer Name',
                        order.user?.name ?? 'Unknown Customer',
                        kModernPrimary,
                      ),
                      const SizedBox(height: 12),
                      _buildModernInfoTile(
                        Icons.phone_rounded,
                        'Phone Number',
                        order.user?.phoneNumber ?? 'No phone number',
                        kModernAccent,
                      ),
                      const SizedBox(height: 12),
                      _buildModernInfoTile(
                        Icons.location_on_rounded,
                        'Delivery Address',
                        order.user?.location ?? 'No address provided',
                        kModernWarning,
                      ),
                      const SizedBox(height: 12),
                      _buildModernInfoTile(
                        Icons.monetization_on_rounded,
                        'Order Value',
                        NumberFormat.currency(symbol: 'IQD ').format(order.finalPrice),
                        kModernSuccess,
                      ),
                      const SizedBox(height: 24),
                      _buildActionButtons(order),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildModernInfoTile(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: kModernTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kModernTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(Order order) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernSuccess, kModernGreen],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kModernSuccess.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _markAsDelivered(order);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mark Delivered',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: kModernCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: kModernError,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _markAsCancelled(order);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel_rounded,
                        color: kModernError,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cancel Order',
                        style: TextStyle(
                          color: kModernError,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Action methods
  void _printShipment() {
    // TODO: Implement print functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.print_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Print functionality coming soon'),
          ],
        ),
        backgroundColor: kModernPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  void _shareShipment() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.share_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Share functionality coming soon'),
          ],
        ),
        backgroundColor: kModernAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  void _markAsDelivered(Order order) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Order #${order.id} marked as delivered'),
          ],
        ),
        backgroundColor: kModernSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  void _markAsCancelled(Order order) {
    HapticFeedback.mediumImpact();
    _showCancelConfirmationDialog(order);
  }
  
  void _showCancelConfirmationDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: kModernCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kModernError, kModernWarning],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cancel Order',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Are you sure you want to cancel this order?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: kModernTextPrimary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This action cannot be undone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: kModernTextSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: kModernSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kModernBorder, width: 1),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Text(
                                      'Keep Order',
                                      style: TextStyle(
                                        color: kModernTextSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [kModernError, kModernWarning]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.cancel_rounded, color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Text('Order #${order.id} has been cancelled'),
                                        ],
                                      ),
                                      backgroundColor: kModernError,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Text(
                                      'Cancel Order',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
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
}
