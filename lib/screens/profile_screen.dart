// lib/screens/profile_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../models/auction_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import './edit_profile_screen.dart';
import './blocked_users_screen.dart';
import '../widgets/auction_list_card.dart';
import '../widgets/language_selection_widget.dart';
import '../auction_detail_screen.dart';
import '../generated/l10n/app_localizations.dart';

// Instagram/TikTok inspired modern color palette
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Data State
  Map<String, dynamic>? _stats;
  List<Auction> _activeAuctions = [];
  List<Order> _soldOrders = [];
  List<Auction> _participatedAuctions = [];
  List<Auction>? _watchedAuctions;
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  bool _isHeaderExpanded = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchData();
    _setupScrollListener();
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

  void _setupScrollListener() {
    _scrollController.addListener(() {
      final isExpanded = _scrollController.offset < 100;
      if (isExpanded != _isHeaderExpanded) {
        setState(() {
          _isHeaderExpanded = isExpanded;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ---- Helpers ----
  String? _safeUrl(String? url) {
    if (url == null) return null;
    final u = url.trim();
    if (u.isEmpty) return null;
    if (u.endsWith('/0') || u.endsWith('/storage/0')) return null;
    if (!u.startsWith('http')) return null;
    return u;
  }

  Widget _netImage(String? url,
      {BoxFit fit = BoxFit.cover,
      Widget? fallback,
      double? width,
      double? height}) {
    final safe = _safeUrl(url);
    if (safe == null) {
      return fallback ??
          Container(
            color: Colors.grey[200],
            width: width,
            height: height,
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          );
    }
    return CachedNetworkImage(
      imageUrl: safe,
      fit: fit,
      width: width,
      height: height,
      placeholder: (ctx, u) => Container(color: Colors.grey[300]),
      errorWidget: (ctx, u, err) => fallback ??
          Container(
            color: Colors.grey[200],
            width: width,
            height: height,
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          ),
    );
  }

  Future<void> _fetchData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final isVendor = authProvider.user?.role == 'vendor';
    final futures = [
      _apiService.getMyActivity(token),
      _apiService.getWatchlist(token),
    ];
    if (isVendor) {
      futures.add(_apiService.getSoldAuctions(token));
    }

    try {
      final results = await Future.wait(futures);
      if (!mounted) return;

      final activityData = results[0] as Map<String, dynamic>?;
      _watchedAuctions = results[1] as List<Auction>?;

      if (activityData != null) {
        _stats = activityData['stats'];
        final allMyAuctions = (activityData['my_auctions'] as List? ?? [])
            .map((d) => Auction.fromJson(d))
            .toList();
        _activeAuctions = allMyAuctions.where((a) => !a.isEnded).toList();
        _participatedAuctions =
            (activityData['participated_auctions'] as List? ?? [])
                .map((d) => Auction.fromJson(d))
                .toList();
      }

      if (isVendor && results.length > 2) {
        _soldOrders = results[2] as List<Order>? ?? [];
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(AppLocalizations.of(context)!.error);
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onEditProfile() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
  }

  void _onBlockedUsers() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BlockedUsersScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: kModernSurface,
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(user),
      body:  _buildModernContent(user),
    );
  }

  PreferredSizeWidget _buildModernAppBar(User? user) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
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
      title: AnimatedOpacity(
        opacity: _isHeaderExpanded ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Row(
          children: [
            // Story-style ring around avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [kModernPink, kModernOrange, kModernAccent],
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(1),
                child: ClipOval(
                  child: user?.profilePhotoUrl != null
                      ? _netImage(
                          user!.profilePhotoUrl!,
                          fit: BoxFit.cover,
                          fallback: Container(
                            color: kModernSurface,
                            child: Icon(
                              Icons.person,
                              color: kModernTextSecondary,
                              size: 16,
                            ),
                          ),
                        )
                      : Container(
                          color: kModernSurface,
                          child: Icon(
                            Icons.person,
                            color: kModernTextSecondary,
                            size: 16,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.name ?? AppLocalizations.of(context)!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _getRoleText(user?.role),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModernIconButton(
                Icons.favorite_border,
                () {},
              ),
              const SizedBox(width: 8),
              _buildModernIconButton(
                Icons.more_vert,
                () => _showModernOptionsMenu(user),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModernIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _showModernOptionsMenu(User? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: kModernBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildModernMenuOption(
              Icons.edit_outlined,
              AppLocalizations.of(context)!.editProfile,
              _onEditProfile,
              color: kModernPrimary,
            ),
            if (user?.role == 'vendor')
              _buildModernMenuOption(
                Icons.block_outlined,
                AppLocalizations.of(context)!.blockedUsers,
                _onBlockedUsers,
                color: kModernWarning,
              ),
            _buildModernMenuOption(
              Icons.language_outlined,
              AppLocalizations.of(context)!.language,
              () => LanguageBottomSheet.show(context),
              color: kModernAccent,
            ),
            _buildModernMenuOption(
              Icons.notifications_outlined,
              AppLocalizations.of(context)!.notifications,
              () {},
              color: kModernAccent,
            ),
            _buildModernMenuOption(
              Icons.help_outline,
              AppLocalizations.of(context)!.help,
              () {},
              color: kModernAccent,
            ),
            const SizedBox(height: 20),
            _buildModernMenuOption(
              Icons.logout_outlined,
              AppLocalizations.of(context)!.logout,
              () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.pop(context);
              },
              color: kModernError,
              isDanger: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMenuOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = kTextPrimary,
    bool isDanger = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDanger ? color : kTextPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: kTextSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernContent(User? user) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: _buildModernProfileHeader(user),
            ),
            SliverToBoxAdapter(
              child: _buildModernStats(user),
            ),
            SliverToBoxAdapter(
              child: _buildModernActionButtons(user),
            ),
            SliverToBoxAdapter(
              child: _buildModernTabBar(user),
            ),
            SliverToBoxAdapter(
              child: _buildModernTabContent(user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernProfileHeader(User? user) {
    final avatarUrl = _safeUrl(user?.profilePhotoUrl);

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
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Instagram-style Profile Section
              Row(
                children: [
                  // Large Story Ring Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          kModernPink,
                          kModernOrange,
                          kModernAccent,
                          kModernGreen,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: avatarUrl != null
                            ? _netImage(
                                avatarUrl,
                                fit: BoxFit.cover,
                                fallback: Container(
                                  color: kModernSurface,
                                  child: Icon(
                                    Icons.person,
                                    size: 36,
                                    color: kModernTextSecondary,
                                  ),
                                ),
                              )
                            : Container(
                                color: kModernSurface,
                                child: Icon(
                                  Icons.person,
                                  size: 36,
                                  color: kModernTextSecondary,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // User Info with Modern Typography
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? AppLocalizations.of(context)!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getRoleColor(user?.role).withOpacity(0.8),
                                _getRoleColor(user?.role),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _getRoleColor(user?.role).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _getRoleText(user?.role),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (user?.email != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            user!.email!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Bio Section with Glassmorphism
              if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    user.bio!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'vendor':
        return kModernPrimary;
      case 'driver':
        return kModernOrange;
      default:
        return kModernAccent;
    }
  }

  Widget _buildModernStats(User? user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      transform: Matrix4.translationValues(0, -30, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildModernStatItem(
                (_stats?['total_auctions_created'] ?? 0).toString(),
                'مزاد',
                Icons.local_fire_department_outlined,
                kModernPrimary,
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: kModernBorder,
            ),
            Expanded(
              child: _buildModernStatItem(
                (_stats?['total_followers'] ?? 0).toString(),
                'شوێنکەوتوو',
                Icons.favorite_outline,
                kModernSecondary,
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: kModernBorder,
            ),
            Expanded(
              child: _buildModernStatItem(
                (_stats?['total_following'] ?? 0).toString(),
                'شوێنکەوتن',
                Icons.trending_up_outlined,
                kModernAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatItem(
    String number,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          number,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: kModernTextPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
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

  Widget _buildBio(User? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user?.name ?? 'بەکارهێنەر',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getRoleText(user?.role),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          if (user?.email != null) ...[
            const SizedBox(height: 4),
            Text(
              user!.email!,
              style: const TextStyle(
                fontSize: 14,
                color: kPrimaryColor,
              ),
            ),
          ],
          if (user?.bio != null && user!.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              user.bio!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernActionButtons(User? user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final isOwnProfile = currentUser?.id == user?.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (isOwnProfile) ...[
            // Own Profile Buttons
            Expanded(
              flex: 2,
              child: _buildModernActionButton(
                'گۆڕینی پرۆفایل',
                Icons.edit_outlined,
                [kModernPrimary, kModernSecondary],
                _onEditProfile,
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernActionButton(
                'هاوبەشیکردن',
                Icons.share_outlined,
                [kModernAccent, kModernBlue],
                () {},
              ),
            ),
          ] else ...[
            // Other User Profile Buttons
            Expanded(
              flex: 2,
              child: _buildModernActionButton(
                'فۆلۆو',
                Icons.person_add_outlined,
                [kModernPrimary, kModernSecondary],
                () {},
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildModernActionButton(
                'پەیام',
                Icons.chat_bubble_outline,
                [kModernAccent, kModernBlue],
                () {},
              ),
            ),
          ],
          const SizedBox(width: 12),
          _buildModernIconActionButton(
            Icons.more_horiz,
            [kModernOrange, kModernPink],
            () => _showModernOptionsMenu(user),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(
    String text,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onPressed, {
    bool isPrimary = false,
  }) {
    return Container(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernIconActionButton(
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onPressed,
  ) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  String _getRoleText(String? role) {
    final l10n = AppLocalizations.of(context)!;
    switch (role) {
      case 'vendor':
        return l10n.vendor;
      case 'driver':
        return l10n.driver;
      default:
        return l10n.user;
    }
  }

  Widget _buildModernTabBar(User? user) {
    final isVendor = user?.role == 'vendor';
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: kModernCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kModernBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: kModernTextPrimary.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildProfessionalTabButton(
              Icons.grid_on_outlined,
              l10n.all,
              0,
              isSelected: _selectedTabIndex == 0,
            ),
          ),
          if (isVendor) ...[
            Expanded(
              child: _buildProfessionalTabButton(
                Icons.sell_outlined,
                l10n.sold,
                1,
                isSelected: _selectedTabIndex == 1,
              ),
            ),
            Expanded(
              child: _buildProfessionalTabButton(
                Icons.favorite_outline,
                l10n.favorites,
                2,
                isSelected: _selectedTabIndex == 2,
              ),
            ),
            Expanded(
              child: _buildProfessionalTabButton(
                Icons.bookmark_outline,
                l10n.watchlist,
                3,
                isSelected: _selectedTabIndex == 3,
              ),
            ),
          ] else ...[
            Expanded(
              child: _buildProfessionalTabButton(
                Icons.favorite_outline,
                l10n.favorites,
                1,
                isSelected: _selectedTabIndex == 1,
              ),
            ),
            Expanded(
              child: _buildProfessionalTabButton(
                Icons.bookmark_outline,
                l10n.watchlist,
                2,
                isSelected: _selectedTabIndex == 2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfessionalTabButton(
    IconData icon,
    String label,
    int index, {
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? kModernPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : kModernTextSecondary,
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : kModernTextSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTabContent(User? user) {
    final isVendor = user?.role == 'vendor';
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (isVendor) ...[
            switch (_selectedTabIndex) {
              0 => _buildModernGrid(_activeAuctions, l10n.noActiveAuctions),
              1 => _buildModernSoldOrdersGrid(_soldOrders, l10n.nothingSoldYet),
              2 => _buildModernGrid(_participatedAuctions, l10n.noParticipation),
              3 => _buildModernGrid(_watchedAuctions ?? [], l10n.emptyWatchlist),
              _ => _buildModernGrid(_activeAuctions, l10n.noActiveAuctions),
            }
          ] else ...[
            switch (_selectedTabIndex) {
              0 => _buildModernGrid(_participatedAuctions, l10n.noParticipation),
              1 => _buildModernGrid(_participatedAuctions, l10n.noParticipation),
              2 => _buildModernGrid(_watchedAuctions ?? [], l10n.emptyWatchlist),
              _ => _buildModernGrid(_participatedAuctions, l10n.noParticipation),
            }
          ]
        ],
      ),
    );
  }

  Widget _buildModernGrid(List<Auction> auctions, String emptyMessage) {
    if (auctions.isEmpty) {
      return _buildModernEmptyState(emptyMessage);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: auctions.length,
      itemBuilder: (context, index) {
        final auction = auctions[index];
        return _buildModernAuctionCard(auction);
      },
    );
  }

  Widget _buildModernAuctionCard(Auction auction) {
    final coverUrl = _safeUrl(auction.images.isNotEmpty ? auction.images.first.url : null);

    return GestureDetector(
      onTap: () => _navigateToAuctionDetail(auction.id),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  color: kModernSurface,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: coverUrl != null
                          ? _netImage(coverUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                          : Container(
                              color: kModernSurface,
                              child: Center(
                                child: Icon(Icons.image_not_supported, color: kTextSecondary, size: 40),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kModernPrimary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${auction.currentPrice.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (auction.images.length > 1)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.collections_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      auction.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kModernTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 13,
                          color: kModernTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            auction.isEnded ? 'کۆتایی هاتووە' : 'چالاکە',
                            style: TextStyle(
                              fontSize: 11,
                              color: auction.isEnded ? kModernError : kModernAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSoldOrdersGrid(List<Order> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return _buildModernEmptyState(emptyMessage);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildModernSoldOrderCard(order);
      },
    );
  }

  Widget _buildModernSoldOrderCard(Order order) {
    final coverUrl = _safeUrl(order.auction.images.isNotEmpty
        ? order.auction.images.first.url
        : null);

    return Container(
      decoration: BoxDecoration(
        color: kModernCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    color: kModernSurface,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: coverUrl != null
                        ? _netImage(coverUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                        : Container(
                            color: kModernSurface,
                            child: Center(
                              child: Icon(Icons.image_not_supported, color: kTextSecondary, size: 40),
                            ),
                          ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        order.auction.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kModernTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'فرۆشراوە بۆ ${order.user?.name ?? "نەناسراو"}',
                        style: TextStyle(
                          fontSize: 11,
                          color: kModernTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'نرخی کۆتایی: ${order.finalPrice}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kModernAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kSuccessColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernEmptyState(String message) {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kModernSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.image_search_outlined,
                size: 60,
                color: kModernTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: kModernTextSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
              color: kModernPrimary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'بارکردنی زانیاری...',
            style: TextStyle(
              fontSize: 16,
              color: kModernTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAuctionDetail(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuctionDetailScreen(auctionId: id),
      ),
    );
  }
}