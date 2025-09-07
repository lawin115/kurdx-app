// lib/screens/explore_screen.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';

import '../models/auction_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import './vendor_profile_screen.dart';
import '../auction_detail_screen.dart';
import './auction_list_screen.dart';
import '../models/conversation_model.dart';
import './chat_screen.dart';

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

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> 
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late TabController _searchTabController;
  late AnimationController _animationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  List<User> _featuredVendors = [];
  List<Auction> _auctions = [];
  bool _isLoadingExplore = true;
  int _currentPage = 1;
  bool _hasMore = true;
  
  bool _isSearching = false;
  List<User> _searchedUsers = [];
  List<User> _searchedVendors = [];
  bool _isLoadingSearch = false;
  String _selectedFilter = 'All';
  List<String> _categories = ['All', 'Electronics', 'Fashion', 'Home', 'Sports'];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _searchTabController = TabController(length: 2, vsync: this);
    _fetchInitialData();
    _searchFocusNode.addListener(_onFocusChange);
    _searchController.addListener(() => EasyDebounce.debounce(
        'search', const Duration(milliseconds: 600), _performSearch));
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _searchAnimationController = AnimationController(
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
    _searchAnimationController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchController.dispose();
    _scrollController.dispose();
    _searchTabController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_searchFocusNode.hasFocus != _isSearching) {
      setState(() => _isSearching = _searchFocusNode.hasFocus);
      if (_isSearching) _performSearch();
    }
  }

  Future<void> _fetchInitialData() async {
       _isLoadingExplore = false;
    try {
      final results = await Future.wait([
        _apiService.getFeaturedVendors(),
        _apiService.getAuctions(page: 1, limit: 12, liveOnly: false),
      ]);
      if (mounted) {
        setState(() {
          _featuredVendors = results[0] as List<User>? ?? [];
          final paginatedData = results[1] as Map<String, dynamic>?;
          if(paginatedData != null){
            _auctions = (paginatedData['data'] as List).map((d) => Auction.fromJson(d)).toList();
            _currentPage = 2;
            _hasMore = _auctions.length == 12;
          }
           _isLoadingExplore = false;
        });
      }
    } catch(e) {
      if(mounted) setState(() => _isLoadingExplore = false);
    
    }
  }

  Future<void> _performSearch() async {
    setState(() => _isLoadingSearch = true);
    final searchTerm = _searchController.text;
    final token = Provider.of<AuthProvider>(context, listen: false).token;
     print("--- Performing search for term: '$searchTerm' ---");
    final results = await Future.wait([_apiService.searchUsers(role: 'user', searchTerm: searchTerm, token: token),_apiService.searchUsers(role: 'vendor', searchTerm: searchTerm, token: token)]);
     print("--- Search results for 'user': ${results[0]} ---");
  print("--- Search results for 'vendor': ${results[1]} ---");
    if(mounted){
      setState(() {
        _searchedUsers = (results[0]?['data'] as List? ?? []).map((d) => User.fromJson(d)).toList();
        _searchedVendors = (results[1]?['data'] as List? ?? []).map((d) => User.fromJson(d)).toList();
          print("--- Parsed ${_searchedUsers.length} users and ${_searchedVendors.length} vendors. ---");
        _isLoadingSearch = false;
      });
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isSearching ? _buildSearchResults() : _buildExploreContent(),
          ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                automaticallyImplyLeading: false,
                toolbarHeight: 56,
                title: Text(
                  "Explore",
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
                      icon: Icon(Icons.tune, color: Colors.white, size: 20),
                      onPressed: _showFilterModal,
                    ),
                  ),
                ],
              ),
              _buildModernSearchBar(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildModernSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
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
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: "Search users, vendors, auctions...",
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              suffixIcon: _isSearching
                  ? Container(
                      margin: const EdgeInsets.all(6),
                      child: TextButton(
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                          HapticFeedback.lightImpact();
                        },
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExploreContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: RefreshIndicator(
        onRefresh: _fetchInitialData,
        color: kModernPrimary,
        backgroundColor: kModernCard,
        child: CustomScrollView(
          key: const PageStorageKey('explore'),
          controller: _scrollController,
          slivers: [
           // _buildSliverCategoriesFilter(),
            _buildSliverFeaturedVendors(),
            _buildSliverSectionHeader("Trending Auctions", Icons.trending_up),
            if (_isLoadingExplore) 
              _buildSliverShimmerGrid()
            else if (_auctions.isEmpty) 
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else 
              _buildSliverAuctionsGrid(),
            if (!_isLoadingExplore && _hasMore) 
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kModernPrimary, kModernAccent],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      key: const PageStorageKey('search'),
      children: [
        TabBar(controller: _searchTabController, tabs: const [Tab(text: 'بەکارهێنەران'), Tab(text: 'پێشانگاکان')]),
        Expanded(
          child: TabBarView(
            controller: _searchTabController,
            children: [
              _isLoadingSearch ? const Center(child: CircularProgressIndicator()) : _buildUserResultList(_searchedUsers, 'بەکارهێنەر'),
              _isLoadingSearch ? const Center(child: CircularProgressIndicator()) : _buildUserResultList(_searchedVendors, 'پێشانگا'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserResultList(List<User> userList, String type) {
    if (userList.isEmpty) return Center(child: Text('هیچ ${type}ێک نەدۆزرایەوە.'));
    return ListView.builder(
      itemCount: userList.length,
      itemBuilder: (ctx, index) {
        final user = userList[index];
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        return ListTile(
          leading: CircleAvatar(backgroundImage: user.profilePhotoUrl != null ? NetworkImage(user.profilePhotoUrl!) : null),
          title: Text(user.name),
          subtitle: Text(user.location ?? ''),
          onTap: () {
            if(user.role == 'vendor'){
              Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => VendorProfileScreen(vendorId: user.id)));
            }
          },
          trailing: user.id == authProvider.user?.id ? null : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
                IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: () => _startChatWith(user)),
                ElevatedButton(
                  child: Text(user.isFollowedByMe ? 'ئەنفۆڵۆو' : 'فۆڵۆو'),
                  onPressed: () {
                 
                  },
                )
            ]
          )
        );
      },
    );
  }
  
  void _startChatWith(User otherUser) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if(token == null) return;
    final conversationId = await _apiService.startOrGetConversation(otherUser.id, token);
    if (mounted && conversationId != null) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (ctx) => ChatScreen(conversationId: conversationId, otherUser: otherUser)
      ));
    }
  }

   Widget _buildSliverAuctionsGrid() {
  return SliverPadding(
    padding: EdgeInsets.all(4),
    sliver: SliverGrid(
      gridDelegate: SliverQuiltedGridDelegate(
        crossAxisCount: 4,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        repeatPattern: QuiltedGridRepeatPattern.inverted,
        pattern: [
          QuiltedGridTile(2, 2), // Large square
          QuiltedGridTile(1, 1), // Small square
          QuiltedGridTile(1, 1), // Small square
          QuiltedGridTile(1, 2), // Vertical rectangle
        ],
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildGridAuctionCard(_auctions[index]),
        childCount: _auctions.length,
      ),
    ),
  );
}

Widget _buildGridAuctionCard(Auction auction) {
  final theme = Theme.of(context);
  return GestureDetector(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => AuctionDetailScreen(auctionId: auction.id))),
    child: Container(
      decoration: BoxDecoration(
        color: kModernSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main image with better error handling
            auction.images.isNotEmpty && auction.images.first.url.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: auction.images.first.url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: kModernSurface,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: kModernPrimary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: kModernSurface,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            color: kModernTextLight,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Image\nUnavailable',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kModernTextLight,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    color: kModernSurface,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          color: kModernTextLight,
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No Image',
                          style: TextStyle(
                            color: kModernTextLight,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
            
            // Price overlay with modern design
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  NumberFormat.simpleCurrency().format(auction.currentPrice),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  
  Widget _buildSliverShimmerGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(8.0),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2, 
        mainAxisSpacing: 8, 
        crossAxisSpacing: 8,
        childCount: 6,
        itemBuilder: (context, index) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!, 
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: (index % 3 * 50) + 200.0, 
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16)
              )
            )
        )
      ),
    );
  }
  
  Widget _buildSliverSectionHeader(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kModernPrimary, kModernAccent],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kModernTextPrimary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // Navigate to full auction list
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        AuctionListScreen(),
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
              child: Text(
                "See All",
                style: TextStyle(
                  color: kModernPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSliverFeaturedVendors() {
    if (_featuredVendors.isEmpty) return SliverToBoxAdapter(child: SizedBox());
    
    return SliverToBoxAdapter(
      child: Column(
        children: [
          _buildSectionHeader("Featured Vendors", Icons.store_outlined),
          Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 20),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _featuredVendors.length,
              itemBuilder: (context, index) {
                final vendor = _featuredVendors[index];
                return _buildVendorCard(vendor, index);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVendorCard(User vendor, int index) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernPrimary, kModernAccent],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kModernPrimary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: (vendor.profilePhotoUrl != null && vendor.profilePhotoUrl!.isNotEmpty && !vendor.profilePhotoUrl!.contains('null'))
                    ? CachedNetworkImage(
                        imageUrl: vendor.profilePhotoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: kModernSurface,
                          child: Icon(
                            Icons.store,
                            color: kModernPrimary,
                            size: 24,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: kModernSurface,
                          child: Icon(
                            Icons.store,
                            color: kModernPrimary,
                            size: 24,
                          ),
                        ),
                      )
                    : Container(
                        color: kModernSurface,
                        child: Icon(
                          Icons.store,
                          color: kModernPrimary,
                          size: 24,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vendor.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kModernTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernPrimary, kModernAccent],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kModernTextPrimary,
            ),
          ),
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
              Icons.explore_outlined,
              size: 60,
              color: kModernTextLight,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No auctions found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kModernTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your filters or check back later",
            style: TextStyle(
              fontSize: 14,
              color: kModernTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  void _showFilterModal() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterModal(),
    );
  }
  
  Widget _buildFilterModal() {
    return Container(
      decoration: BoxDecoration(
        color: kModernCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kModernBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Filter Options",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kModernTextPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Categories",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kModernTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    final isSelected = _selectedFilter == category;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedFilter = category);
                        Navigator.pop(context);
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: [kModernPrimary, kModernAccent])
                              : null,
                          color: isSelected ? null : kModernSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : kModernBorder,
                          ),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : kModernTextSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

