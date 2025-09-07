import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../auction_detail_screen.dart';

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

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _headerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  String _selectedFilter = 'all'; // all, unread, read
  
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
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final allNotifications = notificationProvider.notifications;
    
    // Filter notifications based on selected filter
    final notifications = _getFilteredNotifications(allNotifications);

    return Scaffold(
      backgroundColor: kModernSurface,
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(notificationProvider),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildBody(notificationProvider, authProvider, notifications),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(NotificationProvider notificationProvider) {
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
                mainAxisSize: MainAxisSize.min, // Prevent overflow
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Text(
                      'Notifications',
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
                  if (notificationProvider.unreadCount > 0)
                    Text(
                      '${notificationProvider.unreadCount} unread',
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
                    icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _markAllAsRead(notificationProvider);
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
                    icon: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _showFilterOptions();
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

  Widget _buildBody(NotificationProvider notificationProvider, AuthProvider authProvider, List notifications) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            kModernSurface.withOpacity(0.95),
            kModernSurface,
          ],
          stops: const [0.0, 0.15, 0.3],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 120), // App bar spacing
          _buildFilterTabs(),
          const SizedBox(height: 16),
          Expanded(
            child: notifications.isEmpty
                ? _buildEmptyState()
                : _buildNotificationsList(notifications, notificationProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kModernCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kModernBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterTab('all', 'All', Icons.notifications_rounded),
          _buildFilterTab('unread', 'Unread', Icons.mark_email_unread_rounded),
          _buildFilterTab('read', 'Read', Icons.done_all_rounded),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String filter, String label, IconData icon) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? kModernPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: kModernPrimary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : kModernTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : kModernTextSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kModernPrimary.withOpacity(0.1),
                    kModernSecondary.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: kModernBorder,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.notifications_off_rounded,
                size: 48,
                color: kModernTextLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kModernTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stay tuned for auction updates and bidding alerts',
              style: TextStyle(
                fontSize: 14,
                color: kModernTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kModernPrimary, kModernSecondary],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: kModernPrimary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Explore Auctions',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(List notifications, NotificationProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(30 * (1 - value), 0),
              child: Opacity(
                opacity: value,
                child: _buildNotificationCard(notification, provider),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(notification, NotificationProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: notification.isRead ? kModernCard : kModernCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: notification.isRead ? kModernBorder : kModernPrimary.withOpacity(0.3),
          width: notification.isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: notification.isRead
                ? Colors.black.withOpacity(0.05)
                : kModernPrimary.withOpacity(0.15),
            blurRadius: notification.isRead ? 8 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification, provider),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNotificationContent(notification),
                ),
                if (!notification.isRead)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kModernPrimary, kModernSecondary],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: kModernPrimary.withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(notification) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kModernPrimary.withOpacity(0.1),
            kModernSecondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kModernBorder,
          width: 1,
        ),
      ),
      child: Icon(
        Icons.notifications_rounded,
        color: kModernPrimary,
        size: 24,
      ),
    );
  }

  Widget _buildNotificationContent(notification) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notification.message,
          style: TextStyle(
            fontSize: 15,
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
            color: notification.isRead ? kModernTextSecondary : kModernTextPrimary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatTime(notification.createdAt),
          style: TextStyle(
            fontSize: 12,
            color: kModernTextLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Helper Methods
  List _getFilteredNotifications(List allNotifications) {
    switch (_selectedFilter) {
      case 'unread':
        return allNotifications.where((n) => !n.isRead).toList();
      case 'read':
        return allNotifications.where((n) => n.isRead).toList();
      default:
        return allNotifications;
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedFilter) {
      case 'unread':
        return 'No unread notifications';
      case 'read':
        return 'No read notifications';
      default:
        return 'No notifications yet';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  void _markAllAsRead(NotificationProvider provider) {
    // Mark all notifications as read individually since there's no markAllAsRead method
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    for (final notification in provider.notifications) {
      if (!notification.isRead) {
        provider.markAsRead(notification.id, authProvider.token ?? '');
      }
    }
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: kModernSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showFilterOptions() {
    // Could implement a bottom sheet for advanced filtering
    HapticFeedback.selectionClick();
  }

  void _handleNotificationTap(notification, NotificationProvider provider) {
    if (!notification.isRead) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      provider.markAsRead(notification.id, authProvider.token ?? '');
    }
    
    HapticFeedback.lightImpact();
    
    // Navigate to related auction if auction ID exists
    if (notification.auctionId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuctionDetailScreen(auctionId: notification.auctionId!),
        ),
      );
    }
  }
}