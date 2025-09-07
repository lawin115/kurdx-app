import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kurdpoint/models/driver_dashboard_model.dart';
import 'package:kurdpoint/screens/delivery_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/shipment_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/order_model.dart';
import '../generated/l10n/app_localizations.dart';

// Modern Instagram-style color palette
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

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  DriverDashboardStats? _stats;
  Map<String, dynamic>? _dashboardData;
  List<Order> _ongoingOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchDashboardData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  Future<void> _fetchDashboardData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) {
      if(mounted) setState(() => _isLoading = false);
      return;
    };

    if(!_isLoading) setState(() => _isLoading = false);
    
    try {
      final results = await Future.wait([
        _apiService.getDriverDashboard(token),
        _apiService.getDriverOrders(token),
      ]);

      final fetchedStats = results[0] as DriverDashboardStats?;
      final fetchedOrders = results[1] as List<Order>?;

      if (mounted) {
        setState(() {
          _stats = fetchedStats;
          _ongoingOrders = fetchedOrders ?? [];
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.error;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(l10n),
      body: _buildModernBody(l10n),
    );
  }

  PreferredSizeWidget _buildModernAppBar(AppLocalizations l10n) {
    return AppBar(
      title: Text(
        l10n.driverDashboard,
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
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: _fetchDashboardData,
          ),
        ),
      ],
    );
  }

  Widget _buildModernBody(AppLocalizations l10n) {
    if (_isLoading) {
      return _buildModernLoadingState();
    }

    if (_errorMessage != null) {
      return _buildModernErrorState(l10n);
    }

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildModernStatsHeader(l10n)),
              SliverToBoxAdapter(child: _buildModernStatsGrid(_stats, l10n)),
              SliverToBoxAdapter(child: _buildModernOrdersHeader(l10n)),
              _buildModernOrdersList(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernPrimary, kModernSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.loading,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: kModernTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernErrorState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kModernError.withOpacity(0.1),
            ),
            child: Center(
              child: Icon(
                Icons.error_outline,
                color: kModernError,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _errorMessage!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: kModernTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchDashboardData,
            style: ElevatedButton.styleFrom(
              backgroundColor: kModernPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatsHeader(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Text(
            l10n.todayStats,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kModernTextPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernPrimary.withOpacity(0.2), kModernSecondary.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${DateFormat('EEEE, MMM d').format(DateTime.now())}",
              style: TextStyle(
                color: kModernPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatsGrid(DriverDashboardStats? stats, AppLocalizations l10n) {
    if (stats == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.2,
        children: [
          _buildModernStatCard(
            l10n.collectedAmount,
            NumberFormat.currency(symbol: "\$").format(stats.todaysCollected),
            Icons.account_balance_wallet_outlined,
            kModernSuccess,
          ),
          _buildModernStatCard(
            l10n.deliveredToday,
            stats.todaysDeliveries.toString(),
            Icons.check_circle_outline,
            kModernPrimary,
          ),
          _buildModernStatCard(
            l10n.pendingDeliveries,
            stats.pendingDeliveries.toString(),
            Icons.pending_outlined,
            kModernWarning,
          ),
          _buildModernStatCard(
            l10n.performance,
            "${(stats.todaysDeliveries > 0 ? ((stats.todaysDeliveries / (stats.todaysDeliveries + stats.pendingDeliveries)) * 100).toStringAsFixed(0) : '0')}%",
            Icons.speed_outlined,
            kModernAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(
    String title, 
    String value, 
    IconData icon, 
    Color color
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: Icon(
              icon, 
              color: Colors.white, 
              size: 15,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold, 
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9), 
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernOrdersHeader(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Text(
            l10n.todayTasks,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kModernTextPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: kModernPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${_ongoingOrders.length} ${l10n.tasks}",
              style: TextStyle(
                color: kModernPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernOrdersList(AppLocalizations l10n) {
    if (_ongoingOrders.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          heightFactor: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kModernTextSecondary.withOpacity(0.1),
                ),
                child: Center(
                  child: Icon(
                    Icons.local_shipping_outlined,
                    size: 40,
                    color: kModernTextSecondary.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.noTasks,
                style: const TextStyle(
                  fontSize: 16,
                  color: kModernTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final order = _ongoingOrders[index];
          return _buildModernOrderCard(order, l10n);
        },
        childCount: _ongoingOrders.length,
      ),
    );
  }

  Widget _buildModernOrderCard(Order order, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DeliveryDetailScreen(order: order),
          ),
        ).then((_) => _fetchDashboardData());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: kModernCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kModernTextPrimary.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
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
                        Icons.local_shipping,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${l10n.orderFor}: ${order.user?.name ?? l10n.unknown}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: kModernTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.auction.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: kModernTextSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: kModernTextSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(order.status, l10n),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    NumberFormat.currency(symbol: "\$").format(order.finalPrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: kModernTextPrimary,
                    ),
                  ),
                ],
              ),
            ],
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
    switch (status) {
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

  Widget _buildShipmentsList(List<Shipment> shipments) {
    if (shipments.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          heightFactor: 5, 
          child: Text("هیچ ئەرکێکت نییە."),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final s = shipments[index];
          return Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 16.0, 
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kModernPrimary.withOpacity(0.1),
                ),
                child: Center(
                  child: Text(
                    "${s.orders.length}",
                    style: TextStyle(
                      color: kModernPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                "بارنامەی #${s.id}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                "کۆی نرخ: ${NumberFormat.currency(symbol: "\$").format(s.totalValue)}",
                style: TextStyle(
                  color: kModernTextSecondary,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios, 
                size: 16, 
                color: kModernTextSecondary,
              ),
            ),
          );
        },
        childCount: shipments.length,
      ),
    );
  }
}