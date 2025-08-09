// lib/screens/explore_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
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
import '../models/conversation_model.dart'; // importـی نوێ
import './chat_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late TabController _searchTabController;

  List<User> _featuredVendors = [];
  List<Auction> _auctions = [];
  bool _isLoadingExplore = true;
  int _currentPage = 1;
  bool _hasMore = true;
  
  bool _isSearching = false;
  List<User> _searchedUsers = [];
  List<User> _searchedVendors = [];
  bool _isLoadingSearch = false;
  
  @override
  void initState() {
    super.initState();
    _searchTabController = TabController(length: 2, vsync: this);
    _fetchInitialData();
    _searchFocusNode.addListener(_onFocusChange);
    _searchController.addListener(() => EasyDebounce.debounce('search', const Duration(milliseconds: 600), _performSearch));
  }

  @override
  void dispose() {
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
        _apiService.getAuctions(page: 1, limit: 12),
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
      appBar: AppBar(
        title: _buildSearchBar(),
        actions: [if (_isSearching) TextButton(child: const Text('لابردن'), onPressed: () => _searchFocusNode.unfocus())],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _isSearching ? _buildSearchResults() : _buildExploreContent(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController, focusNode: _searchFocusNode,
      decoration: const InputDecoration(hintText: 'گەڕان بەدوای بەکارهێنەران...'),
    );
  }

  Widget _buildExploreContent() {
    return RefreshIndicator(
      onRefresh: _fetchInitialData,
      child: CustomScrollView(
        key: const PageStorageKey('explore'),
        controller: _scrollController,
        slivers: [
         
          if (_isLoadingExplore) _buildSliverShimmerGrid()
          else if (_auctions.isEmpty) SliverFillRemaining(child: Center(child: Text('هیچ مەزادێک نییە.')))
          else _buildSliverAuctionsGrid(),
          if (!_isLoadingExplore && _hasMore) SliverToBoxAdapter(child: const Center(child: CircularProgressIndicator())),
        ],
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
      color: Colors.grey[200], // Background color for empty space
      child: Stack(
        fit: StackFit.expand, // Make stack fill the container
        children: [
          // Main image
          CachedNetworkImage(
            imageUrl: auction.images.isNotEmpty ? auction.images.first.url : '',
            fit: BoxFit.cover,
            placeholder: (context, url) => Image.asset(
              'assets/bid.png',
              fit: BoxFit.cover,
            ),
            errorWidget: (context, url, error) => Image.asset(
              'assets/bid.png',
              fit: BoxFit.cover,
            ),
          ),
          
          // Price overlay
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4), // Subtle rounding
              ),
              child: Text(
                NumberFormat.simpleCurrency().format(auction.currentPrice),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
}

