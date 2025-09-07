import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../models/order_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../generated/l10n/app_localizations.dart';

// Modern Instagram-style color palette (matching driver dashboard)
const Color kModernPrimary = Color(0xFF6366F1); // Modern Purple
const Color kModernSecondary = Color(0xFFEC4899); // Hot Pink
const Color kModernAccent = Color(0xFF06B6D4); // Cyan
const Color kModernWarning = Color(0xFFFF9A56); // Orange
const Color kModernError = Color(0xFFEF4444); // Red
const Color kModernSuccess = Color(0xFF10B981); // Emerald
const Color kModernGradientStart = Color(0xFF667EEA); // Purple Blue
const Color kModernGradientEnd = Color(0xFF764BA2); // Deep Purple
const Color kModernSurface = Color(0xFFF8FAFC); // Light Surface
const Color kModernCard = Color(0xFFFFFFFF); // White Cards
const Color kModernTextPrimary = Color(0xFF0F172A); // Dark Text
const Color kModernTextSecondary = Color(0xFF64748B); // Gray Text
const Color kModernBorder = Color(0xFFE2E8F0); // Subtle Border

class DeliveryDetailScreen extends StatefulWidget {
  final Order order;
  const DeliveryDetailScreen({super.key, required this.order});
  
  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> with TickerProviderStateMixin {
  late Order _currentOrder;
  bool _isLoadingStatusChange = false;
  final ApiService _apiService = ApiService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  Future<void> _openMap(String location) async {
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$location');
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch(e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    final phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if(await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.error}: ${l10n.errorOccurred}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoadingStatusChange = true);
    
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    try {
      final updatedOrder = await _apiService.updateDriverOrderStatus(_currentOrder.id, newStatus, token);
      
      if (updatedOrder != null && mounted) {
        setState(() => _currentOrder = updatedOrder);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.orderFor} ${_currentOrder.id} ${l10n.successfully} ${l10n.updated}'), 
            backgroundColor: kModernSuccess,
          ),
        );
        HapticFeedback.lightImpact();
      } else if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOccurred), 
            backgroundColor: kModernError,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'), 
            backgroundColor: kModernError,
          ),
        );
      }
    }
    
    if (mounted) setState(() => _isLoadingStatusChange = false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer = _currentOrder.user; // کڕیار
    final vendor = _currentOrder.vendor; // فرۆشیار
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(l10n),
      body: _buildModernBody(customer, vendor, l10n),
      bottomNavigationBar: _buildActionButton(l10n),
    );
  }

  PreferredSizeWidget _buildModernAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(
        '${l10n.orderFor} #${_currentOrder.id}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: Container(
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
      ),
      leading: Container(
        margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildModernBody(User? customer, User? vendor, AppLocalizations l10n) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOrderHeader(l10n),
              const SizedBox(height: 24),
              _buildStatusStepper(l10n),
              const SizedBox(height: 24),
              if (customer != null)
                _buildInfoCard('${l10n.orderFor}: ${customer.name}', customer, l10n, canOpenMap: true),
              const SizedBox(height: 16),
              if (vendor != null)
                _buildInfoCard('${l10n.vendor}: ${vendor.name}', vendor, l10n, canOpenMap: false),
              const SizedBox(height: 16),
              _buildAuctionCard(l10n),
              const SizedBox(height: 16),
              _buildPriceCard(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kModernPrimary.withOpacity(0.9), kModernSecondary.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kModernPrimary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.orderFor} #${_currentOrder.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStatusText(_currentOrder.status, l10n),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(_currentOrder.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(_currentOrder.status, l10n),
                  style: TextStyle(
                    color: _getStatusColor(_currentOrder.status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper(AppLocalizations l10n) {
    final statuses = ['processing', 'shipped', 'out_for_delivery', 'delivered'];
    int currentStep = statuses.indexOf(_currentOrder.status);
    if(currentStep < 0) currentStep = 1; // ئەگەر shipped بوو

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kModernCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kModernTextPrimary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.todayTasks,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kModernTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isActive = index <= currentStep;
            final isCompleted = index < currentStep;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted 
                        ? kModernSuccess 
                        : (isActive ? kModernPrimary : kModernTextSecondary.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : kModernTextSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getStatusText(status, l10n),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive ? kModernTextPrimary : kModernTextSecondary,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    const Icon(
                      Icons.check_circle,
                      color: kModernSuccess,
                      size: 20,
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(String title, User user, AppLocalizations l10n, {required bool canOpenMap}) {
    return Container(
      decoration: BoxDecoration(
        color: kModernCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kModernTextPrimary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [kModernPrimary, kModernSecondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      canOpenMap ? Icons.person : Icons.store,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kModernTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoRow(Icons.person_outline, user.name, l10n),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.phone_outlined, 
              user.phoneNumber ?? l10n.unknown, 
              l10n,
              onAction: user.phoneNumber != null ? () => _makeCall(user.phoneNumber!) : null,
              actionIcon: Icons.call_outlined,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.location_on_outlined, 
              user.location ?? l10n.unknown, 
              l10n,
              onAction: canOpenMap && user.location != null ? () => _openMap(user.location!) : null,
              actionIcon: Icons.map_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, AppLocalizations l10n, {VoidCallback? onAction, IconData? actionIcon}) {
    return Row(
      children: [
        Icon(icon, color: kModernTextSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: kModernTextPrimary,
            ),
          ),
        ),
        if (onAction != null)
          IconButton(
            icon: Icon(actionIcon, color: kModernPrimary),
            onPressed: onAction,
          ),
      ],
    );
  }
  
  Widget _buildAuctionCard(AppLocalizations l10n) {
    final auction = _currentOrder.auction;
    
    return Container(
      decoration: BoxDecoration(
        color: kModernCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kModernTextPrimary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [kModernAccent, kModernSecondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.shopping_bag,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  auction.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kModernTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              auction.description,
              style: TextStyle(
                fontSize: 14,
                color: kModernTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kModernPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${l10n.price}: ${NumberFormat.currency(symbol: "\$").format(auction.currentPrice)}',
                    style: TextStyle(
                      color: kModernPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                if (auction.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kModernAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      auction.category!.name,
                      style: TextStyle(
                        color: kModernAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPriceCard(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kModernSuccess.withOpacity(0.1), kModernSuccess.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kModernSuccess.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${l10n.collectedAmount}:", 
              style: TextStyle(
                fontSize: 18, 
                color: kModernSuccess, 
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              NumberFormat.currency(symbol: "\$").format(_currentOrder.finalPrice),
              style: TextStyle(
                fontSize: 24, 
                color: kModernSuccess, 
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(AppLocalizations l10n) {
    String? nextStatus;
    String? buttonText;
    IconData? buttonIcon;

    if (_currentOrder.status == 'shipped') {
      nextStatus = 'out_for_delivery';
      buttonText = l10n.outForDelivery;
      buttonIcon = Icons.delivery_dining_outlined;
    } else if (_currentOrder.status == 'out_for_delivery') {
      nextStatus = 'delivered';
      buttonText = l10n.delivered;
      buttonIcon = Icons.check_circle_outline;
    }

    if (nextStatus == null || buttonText == null) {
      return const SizedBox.shrink(); // ئەگەر delivered بوو, هیچ پیشان مەدە
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: _isLoadingStatusChange
        ? Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: kModernPrimary,
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          )
        : Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernPrimary, kModernSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kModernPrimary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              icon: Icon(buttonIcon, color: Colors.white),
              label: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              onPressed: () => _updateStatus(nextStatus!),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'shipped':
        return kModernPrimary;
      case 'out_for_delivery':
        return kModernAccent;
      case 'delivered':
        return kModernSuccess;
      case 'cancelled':
        return kModernError;
      default:
        return kModernTextSecondary;
    }
  }

  String _getStatusText(String status, AppLocalizations l10n) {
    switch(status) {
      case 'pending_payment': 
        return l10n.pendingPayment;
      case 'processing': 
        return l10n.processing;
      case 'shipped': 
        return l10n.shipped;
      case 'out_for_delivery': 
        return l10n.outForDelivery;
      case 'delivered': 
        return l10n.delivered;
      case 'cancelled': 
        return l10n.cancelled;
      default: 
        return status;
    }
  }
}