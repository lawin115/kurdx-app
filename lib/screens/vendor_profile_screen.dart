import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';

import '../models/user_model.dart';
import '../models/auction_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/auction_list_card.dart';
import './edit_profile_screen.dart';
import './chat_screen.dart';
import './login_screen.dart';

// Modern Color Palette - Consistent with your app
const Color kPrimaryColor = Color(0xFF6366F1); // Indigo
const Color kSecondaryColor = Color(0xFF8B5CF6); // Purple
const Color kAccentColor = Color(0xFF06D6A0); // Emerald
const Color kSurfaceColor = Color(0xFFF8FAFC); // Slate-50
const Color kTextPrimary = Color(0xFF0F172A); // Slate-900
const Color kTextSecondary = Color(0xFF64748B); // Slate-500
const Color kBorderColor = Color(0xFFE2E8F0); // Slate-200
const Color kWarningColor = Color(0xFFF59E0B); // Amber
const Color kDangerColor = Color(0xFFEF4444); // Red
const Color kSuccessColor = Color(0xFF10B981); // Emerald

class VendorProfileScreen extends StatefulWidget {
  final int vendorId;
  const VendorProfileScreen({super.key, required this.vendorId});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen>
    with TickerProviderStateMixin {
  
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  
  // Animation Controllers
  late AnimationController _heroController;
  late AnimationController _statsController;
  late AnimationController _buttonController;
  late Animation<double> _heroAnimation;
  late Animation<double> _statsAnimation;
  late Animation<double> _buttonAnimation;
  
  // Data State
  User? _vendor;
  List<Auction> _auctions = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  int _followersCount = 0;
  User? _currentUser;
  Map<String, dynamic>? _stats;
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scrollController.addListener(_onScroll);
    _currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    _fetchVendorProfile();
  }

  void _initializeAnimations() {
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _heroAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
    );
    _statsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.elasticOut),
    );
    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack),
    );
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 200;
    if (shouldShow != _showAppBarTitle) {
      setState(() => _showAppBarTitle = shouldShow);
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    _statsController.dispose();
    _buttonController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchVendorProfile() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final data = await _apiService.getVendorProfile(widget.vendorId, token);
    
    if (mounted && data != null) {
      setState(() {
        _vendor = User.fromJson(data['vendor']);
        _auctions = (data['auctions']['data'] as List).map((d) => Auction.fromJson(d)).toList();
        _stats = data['stats'];
        _isFollowing = _stats?['is_following'] ?? false;
        _followersCount = _stats?['followers_count'] ?? 0;
        _isLoading = false;
      });
      
      // Start animations after data loads
      _heroController.forward();
      await Future.delayed(const Duration(milliseconds: 400));
      _statsController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _buttonController.forward();
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _toggleFollow() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();
    final response = await _apiService.toggleFollow(widget.vendorId, auth.token!);

    if (mounted && response != null) {
      setState(() {
        _isFollowing = response['is_following'];
        _stats?['followers_count'] += _isFollowing ? 1 : -1;
      });
      
      _showSnackBar(
        _isFollowing ? 'فۆڵۆو کرا!' : 'فۆڵۆو لاببرا',
        _isFollowing ? kSuccessColor : kTextSecondary,
      );
    } else if (mounted) {
      _showSnackBar('هەڵەیەک ڕوویدا!', kDangerColor);
    }
  }

  Future<void> _startChat() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
      return;
    }
    
    if (_vendor == null) return;
    
    _showLoadingDialog();
    
    final conversationId = await _apiService.startOrGetConversation(_vendor!.id, auth.token!);
    if (mounted) Navigator.of(context).pop();

    if (conversationId != null && mounted) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
            conversationId: conversationId,
            otherUser: _vendor!,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              )),
              child: child,
            );
          },
        ),
      );
    } else if (mounted) {
      _showSnackBar('هەڵەیەک لە دەستپێکردنی چاتدا ڕوویدا', kDangerColor);
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: kPrimaryColor),
              const SizedBox(height: 16),
              Text('دروستکردنی چات...', style: TextStyle(color: kTextSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurfaceColor,
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _vendor == null
            ? _centeredMessage('پێشانگا نەدۆزرایەوە')
              : _buildContent(),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: _showAppBarTitle ? Colors.white.withOpacity(0.95) : Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      flexibleSpace: _showAppBarTitle
          ? ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.white.withOpacity(0.8)),
              ),
            )
          : null,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _showAppBarTitle ? Colors.transparent : Colors.black.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: BackButton(
          color: _showAppBarTitle ? kTextPrimary : Colors.white,
        ),
      ),
      title: AnimatedOpacity(
        opacity: _showAppBarTitle ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          _vendor?.name ?? '',
          style: TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _showAppBarTitle ? Colors.transparent : Colors.black.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.more_vert,
              color: _showAppBarTitle ? kTextPrimary : Colors.white,
            ),
            onPressed: () {
              // Add menu functionality
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildHeroSection(),
        _buildStatsSection(),
        _buildActionButtons(),
        _buildAboutSection(),
       ..._buildAuctionsSection(),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHeroSection() {
    return SliverToBoxAdapter(
      child: Container(
        height: 320,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kPrimaryColor.withOpacity(0.8),
                    kSecondaryColor.withOpacity(0.6),
                    kAccentColor.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: (_vendor!.profilePhotoUrl != null && _vendor!.profilePhotoUrl!.isNotEmpty && !_vendor!.profilePhotoUrl!.contains('null'))
                  ? CachedNetworkImage(
                      imageUrl: _vendor!.profilePhotoUrl!,
                      fit: BoxFit.cover,
                      colorBlendMode: BlendMode.overlay,
                      color: kPrimaryColor.withOpacity(0.3),
                    )
                  : null,
            ),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            
            // Profile Content
            AnimatedBuilder(
              animation: _heroAnimation,
              builder: (context, child) {
                return Opacity(
                 opacity: _heroAnimation.value.clamp(0.0, 1.0), // FIXED
                  child: Transform.translate(
                    offset: Offset(0, 50 * (1 - _heroAnimation.value)),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Profile Avatar
                          Hero(
                            tag: 'vendor-avatar-${_vendor!.id}',
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                backgroundImage: (_vendor!.profilePhotoUrl != null && _vendor!.profilePhotoUrl!.isNotEmpty && !_vendor!.profilePhotoUrl!.contains('null'))
                                    ? NetworkImage(_vendor!.profilePhotoUrl!)
                                    : null,
                                child: _vendor!.profilePhotoUrl == null
                                    ? Icon(Icons.store, size: 48, color: kPrimaryColor)
                                    : null,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Vendor Name
                          Text(
                            _vendor!.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Location and Verification
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_vendor!.location != null) ...[
                                Icon(Icons.location_on, color: Colors.white70, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _vendor!.location!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kSuccessColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'پەسەندکراو',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
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
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _statsAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * _statsAnimation.value),
            child: Opacity(
              opacity: _statsAnimation.value.clamp(0.0, 1.0),
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: kTextPrimary.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildModernStatItem(
                        'فۆڵۆوەر',
                        (_stats?['followers_count'] ?? 0).toString(),
                        Icons.group_outlined,
                        kPrimaryColor,
                      ),
                      Container(width: 1, height: 40, color: kBorderColor),
                      _buildModernStatItem(
                        'فرۆشراو',
                        (_stats?['auctions_sold'] ?? 0).toString(),
                        Icons.sell_outlined,
                        kAccentColor,
                      ),
                      Container(width: 1, height: 40, color: kBorderColor),
                      _buildModernStatItem(
                        'سەرکەوتن',
                        '${_stats?['success_rate'] ?? 0}%',
                        Icons.trending_up_outlined,
                        kSuccessColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: kTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final bool isMyOwnProfile = _currentUser?.id == _vendor?.id;
    
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _buttonAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - _buttonAnimation.value)),
            child: Opacity(
               opacity: _buttonAnimation.value.clamp(0.0, 1.0), // FIXED
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: isMyOwnProfile ? _buildOwnerActions() : _buildVisitorActions(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOwnerActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor.withOpacity(0.1), kSecondaryColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'پرۆفایلەکەت',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const EditProfileScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: animation.drive(Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      )),
                      child: child,
                    );
                  },
                ),
              ),
              icon: const Icon(Icons.edit, size: 20),
              label: const Text('گۆڕینی پرۆفایل', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitorActions() {
    return Row(
      children: [
        // Follow Button
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: _isFollowing
                  ? LinearGradient(colors: [kBorderColor, kBorderColor])
                  : LinearGradient(colors: [kPrimaryColor, kSecondaryColor]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (!_isFollowing)
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleFollow,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isFollowing ? Icons.check : Icons.person_add_alt_1,
                        color: _isFollowing ? kTextSecondary : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isFollowing ? 'فۆڵۆو کراوە' : 'فۆڵۆو بکە',
                        style: TextStyle(
                          color: _isFollowing ? kTextSecondary : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
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
        
        // Message Button
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kAccentColor),
              boxShadow: [
                BoxShadow(
                  color: kAccentColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _startChat,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message_outlined, color: kAccentColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'نامە بنێرە',
                        style: TextStyle(
                          color: kAccentColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
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

  Widget _buildAboutSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kTextPrimary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [kSecondaryColor, kPrimaryColor]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'دەربارەی پێشانگا',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _vendor?.bio ?? 'بیرۆکەیەک نییە',
                  style: TextStyle(
                    color: kTextSecondary,
                    height: 1.6,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAuctionsSection() {
  return [
    SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [kAccentColor, kSuccessColor]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.gavel, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'مەزادە چالاکەکان',
                style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            if (_auctions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kAccentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_auctions.length}',
                  style: TextStyle(
                    color: kAccentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    _buildAuctionsList(), // ئەمە پێویستە Sliver بگەڕێنێت
  ];
}

  
Widget _buildAuctionsList() {
  if (_auctions.isEmpty) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text("ئەم پێشانگایە هیچ مەزادێکی چالاکی نییە"),
          ],
        ),
      ),
    );
  }

  return SliverPadding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    sliver: SliverMasonryGrid.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childCount: _auctions.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          delay: Duration(milliseconds: 100 * (index % 4)),
          child: AuctionGridCard(auction: _auctions[index]),
        );
      },
    ),
  );
}
    }


class _buildLoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: kPrimaryColor),
    );
  }
}

class _centeredMessage extends StatelessWidget {
  final String message;
  const _centeredMessage(this.message);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

