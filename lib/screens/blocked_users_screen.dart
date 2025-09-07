// lib/screens/blocked_users_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kurdpoint/models/user_model.dart';
import 'package:kurdpoint/providers/auth_provider.dart';
import 'package:kurdpoint/services/api_service.dart';
import 'package:provider/provider.dart';

// Modern Professional Color Palette
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

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});
  
  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> 
    with TickerProviderStateMixin {
  late Future<List<User>?> _blockedUsersFuture;
  final ApiService _apiService = ApiService();
  
  late AnimationController _animationController;
  late AnimationController _refreshController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadBlockedUsers();
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 400),
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
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _loadBlockedUsers() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      setState(() => _isLoading = true);
      _blockedUsersFuture = _apiService.getBlockedUsers(token);
      _blockedUsersFuture.then((_) {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  Future<void> _unblockUser(User userToUnblock) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token!;
    
    // Show confirmation dialog
    final confirmed = await _showUnblockDialog(userToUnblock);
    if (!confirmed) return;
    
    try {
      final success = await _apiService.toggleBlockUser(userToUnblock.id, token);
      if (success && mounted) {
        _showSuccessSnackbar('${userToUnblock.name} has been unblocked');
        setState(() {
          _loadBlockedUsers(); // Refresh the list
        });
        _refreshController.forward().then((_) => _refreshController.reset());
      } else {
        _showErrorSnackbar('Failed to unblock user');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred');
    }
  }
  
  Future<bool> _showUnblockDialog(User user) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => _buildModernDialog(user),
    ) ?? false;
  }
  
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: kModernSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: kModernError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
                  Text(
                    'Blocked Users',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Manage blocked accounts',
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
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _loadBlockedUsers();
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
      margin: const EdgeInsets.only(top: 100),
      child: FutureBuilder<List<User>?>(
        future: _blockedUsersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }
          
          if (snapshot.hasError) {
            return _buildErrorState();
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }
          
          final blockedUsers = snapshot.data!;
          return _buildUsersList(blockedUsers);
        },
      ),
    );
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
            'Loading blocked users...',
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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kModernError.withOpacity(0.1),
                  kModernError.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: kModernError.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: kModernError,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kModernTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load blocked users',
            style: TextStyle(
              fontSize: 14,
              color: kModernTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
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
                color: kModernPrimary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.block_outlined,
              color: kModernPrimary,
              size: 56,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'No Blocked Users',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kModernTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'You haven\'t blocked anyone yet. Blocked users will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: kModernTextSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildRetryButton(),
        ],
      ),
    );
  }
  
  Widget _buildRetryButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kModernPrimary, kModernAccent],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kModernPrimary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            _loadBlockedUsers();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildUsersList(List<User> blockedUsers) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: blockedUsers.length,
      itemBuilder: (context, index) {
        final user = blockedUsers[index];
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
          child: _buildUserCard(user),
        );
      },
    );
  }
  
  Widget _buildUserCard(User user) {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _buildUserAvatar(user),
            const SizedBox(width: 16),
            Expanded(
              child: _buildUserInfo(user),
            ),
            const SizedBox(width: 16),
            _buildUnblockButton(user),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserAvatar(User user) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            kModernPrimary.withOpacity(0.1),
            kModernAccent.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: kModernPrimary.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: kModernPrimary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: (user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty && !user.profilePhotoUrl!.contains('null'))
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: user.profilePhotoUrl!,
                width: 60,
                height: 60,
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
                errorWidget: (context, url, error) => _buildAvatarFallback(user),
              ),
            )
          : _buildAvatarFallback(user),
    );
  }
  
  Widget _buildAvatarFallback(User user) {
    return Center(
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
        style: TextStyle(
          color: kModernPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 24,
        ),
      ),
    );
  }
  
  Widget _buildUserInfo(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kModernTextPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: kModernError.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: kModernError.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.block,
                color: kModernError,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                'Blocked',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kModernError,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildUnblockButton(User user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kModernSuccess, kModernGreen],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kModernSuccess.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            _unblockUser(user);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Unblock',
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
    );
  }
  
  Widget _buildModernDialog(User user) {
    return Dialog(
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
                  colors: [kModernSuccess, kModernGreen],
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
                      Icons.check_circle_outline,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unblock User',
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
                    'Are you sure you want to unblock ${user.name}?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: kModernTextPrimary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'They will be able to message you and see your content again.',
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
                        child: _buildDialogButton(
                          'Cancel',
                          false,
                          () => Navigator.pop(context, false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDialogButton(
                          'Unblock',
                          true,
                          () => Navigator.pop(context, true),
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
  
  Widget _buildDialogButton(String text, bool isPrimary, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(colors: [kModernSuccess, kModernGreen])
            : null,
        color: isPrimary ? null : kModernSurface,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary
            ? null
            : Border.all(color: kModernBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: isPrimary ? Colors.white : kModernTextSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}