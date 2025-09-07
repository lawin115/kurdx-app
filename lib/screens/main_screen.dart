import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kurdpoint/screens/map_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/data_cache_provider.dart';
import './auction_list_screen.dart';
import './profile_screen.dart';
import './add_auction_screen.dart';
import './sold_auctions_screen.dart';
import './explore_screen.dart';
import './my_orders_screen.dart';
import './driver_scan_screen.dart';
import './driver_dashboard_screen.dart';
import './create_post_screen.dart';
import '../screens/create_product_screen.dart';

// Modern Professional Color Palette (consistent with existing design system)
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

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late int _selectedIndex;
  late PageController _pageController;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabScaleAnimation;
  
  bool _showCreateOptions = false;
  bool _isInitializing = false; // Reduced initialization for Instagram-style

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
    _fabAnimationController.forward();
  }

  void _initializeData() {
    Future.delayed(Duration.zero, () async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final dataCacheProvider = Provider.of<DataCacheProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      
      final token = authProvider.token;
      
      try {
        // Instagram-style instant loading
        await dataCacheProvider.preloadForInstantDisplay(token);
        
        // Fetch notifications in background
        if (token != null) {
          Future.microtask(() => notificationProvider.fetchNotifications(token));
        }
        
        print("📱 Instagram-style instant loading completed!");
      } catch (e) {
        print("❌ Error in instant loading: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _showCreateOptions = false;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    HapticFeedback.lightImpact();
  }

  void _toggleCreateOptions() {
    setState(() {
      _showCreateOptions = !_showCreateOptions;
    });
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isVendor = authProvider.user?.role == 'vendor';
    final isDriver = authProvider.user?.role == 'driver';
    final isUser = authProvider.user?.role == 'user';

    final List<Widget> pages = [
      const MapScreen(),
      const AuctionListScreen(),
      const MyOrdersScreen(),
      if (isUser) const ExploreScreen(),
      if (isDriver) const DriverDashboardScreen(),
      if (isVendor) const AddAuctionScreen(),
      if (isVendor) const SoldAuctionsScreen(),
      const ProfileScreen(),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            kModernSurface,
            kModernSurface.withOpacity(0.95),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: _isInitializing 
            ? _buildInitializationScreen()
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Stack(
                  children: [
                    PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      children: pages,
                    ),
                    _buildModernBottomNavBar(isVendor, isDriver, isUser),
                    if (_showCreateOptions) _buildCreateOptionsOverlay(isVendor),
                  ],
                ),
              ),
        floatingActionButton: _isInitializing ? null : _buildModernFloatingActionButton(isVendor),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildInitializationScreen() {
    return Container(
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '📱 Instagram-style loading...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Live data, no waiting',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFloatingActionButton(bool isVendor) {
    if (!isVendor) return const SizedBox.shrink();
    
    return ScaleTransition(
      scale: _fabScaleAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          onPressed: _toggleCreateOptions,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernPrimary, kModernAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kModernPrimary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: AnimatedRotation(
              turns: _showCreateOptions ? 0.125 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateOptionsOverlay(bool isVendor) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showCreateOptions = false),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Create New",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: kModernTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCreateOption(
                      "New Auction",
                      "Create a new auction listing",
                      Icons.gavel_outlined,
                      [kModernPrimary, kModernAccent],
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddAuctionScreen()),
                        );
                        setState(() => _showCreateOptions = false);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCreateOption(
                      "Add Product",
                      "List a new product for sale",
                      Icons.shopping_cart_outlined,
                      [kModernPrimary, kModernAccent],
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateProductScreen()),
                        );
                        setState(() => _showCreateOptions = false);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCreateOption(
                      "New Post",
                      "Share a social media post",
                      Icons.camera_alt_outlined,
                      [kModernOrange, kModernPink],
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                        );
                        setState(() => _showCreateOptions = false);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateOption(
    String title,
    String subtitle,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors.map((c) => c.withOpacity(0.1)).toList(),
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: gradientColors.first.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
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
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kModernTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: kModernTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: gradientColors.first,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernBottomNavBar(bool isVendor, bool isDriver, bool isUser) {
    final navItems = _getNavigationItems(isVendor, isDriver, isUser);
    final centerIndex = navItems.length ~/ 2;

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.85),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: kModernBorder.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: kModernPrimary.withOpacity(0.15),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: navItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isActive = _selectedIndex == index;
                  final isCenterItem = isVendor && index == centerIndex;

                  if (isCenterItem) {
                    return const Expanded(
                      child: SizedBox(width: 60), // Space for FAB
                    );
                  }

                  return Expanded(
                    child: _buildNavItem(item, index, isActive),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(NavigationItem item, int index, bool isActive) {
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 8 : 6,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    kModernPrimary.withOpacity(0.15),
                    kModernAccent.withOpacity(0.15),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [kModernPrimary, kModernAccent],
                      )
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                size: isActive ? 20 : 18,
                color: isActive ? Colors.white : kModernTextSecondary,
              ),
            ),
            if (isActive) ...[
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: kModernPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  List<NavigationItem> _getNavigationItems(bool isVendor, bool isDriver, bool isUser) {
    final items = <NavigationItem>[
      NavigationItem(icon: Icons.map_outlined, label: 'Map'),
      NavigationItem(icon: Icons.home_outlined, label: 'Home'),
    ];

    if (isVendor) {
      items.add(NavigationItem(icon: Icons.add_circle_outline, label: 'Create')); // This will be replaced by FAB
    }

    items.add(NavigationItem(icon: Icons.shopping_bag_outlined, label: 'Orders'));

    if (isUser) {
      items.add(NavigationItem(icon: Icons.explore_outlined, label: 'Explore'));
    }

    if (isDriver) {
      items.add(NavigationItem(icon: Icons.dashboard_outlined, label: 'Dashboard'));
    }

    if (isVendor) {
      items.add(NavigationItem(icon: Icons.sell_outlined, label: 'Sold'));
    }

    items.add(NavigationItem(icon: Icons.person_outline, label: 'Profile'));

    return items;
  }
}

class NavigationItem {
  final IconData icon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.label,
  });
}
