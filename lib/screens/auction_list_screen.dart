import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:kurdpoint/models/user_model.dart';
import 'package:kurdpoint/screens/chat_list_screen.dart';
import 'package:kurdpoint/screens/vendor_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timer_builder/timer_builder.dart';


import '../models/auction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import '../auction_detail_screen.dart';

// Define a cohesive palette (navy, light gray, gold).
const Color kPrimaryColor   = Color(0xFF2E4053); // dominant color
const Color kSecondaryColor = Color(0xFFBFC9CA); // secondary background tint
const Color kAccentColor    = Color(0xFFF1C40F); // accent for highlights

class AuctionListScreen extends StatefulWidget {
  const AuctionListScreen({Key? key}) : super(key: key);

  @override
  _AuctionListScreenState createState() => _AuctionListScreenState();
}

class _AuctionListScreenState extends State<AuctionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  List<User> _featuredVendors = [];
  Timer? _debounce;
  List<Auction> _featuredAuctions = []; 
  List<Auction> _auctions = [];
  int _currentPage = 1;
  bool _isLoading   = false;
  bool _isFirstLoad = true;
  bool _hasMore     = true;
  int? _selectedCategoryId;
  bool _isSearching  = false;
  bool _showLiveOnly = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchChanged);
    _fetchAuctions();
    _fetchInitialData();
  }
    Future<void> _fetchInitialData() async {
    _fetchAuctions();
    
    // وەرگرتنی داتاکان پێکەوە بۆ کارایی باشتر
    final results = await Future.wait([
      _apiService.getCategories(),
      _apiService.getFeaturedAuctions(),
       _apiService.getFeaturedVendors(), // <-- بانگکردنی функцIAی نوێ
    ]);
    
    if (mounted) {
      setState(() {
   
        _featuredAuctions = results[1] as List<Auction>? ?? [];
        _featuredVendors = results[2] as List<User>? ?? [];
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        _hasMore &&
        !_isLoading) {
      _fetchAuctions();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 500), () => _refresh());
  }

  Future<void> _fetchAuctions() async {
     final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    final paginatedData = await _apiService.getAuctions(
      page: _currentPage,
      searchTerm: _searchController.text,
      categoryId: _selectedCategoryId,
      apiToken: token, // <-- زیادکرا
     limit: 10,
    );
    if (paginatedData != null && mounted) {
      final List<dynamic> auctionData =
          paginatedData['data'] as List? ?? [];
      final List<Auction> newAuctions =
          auctionData.map((d) => Auction.fromJson(d)).toList();
      setState(() {
        _auctions.addAll(newAuctions);
        _currentPage++;
        _hasMore = newAuctions.length == 10;
        _isLoading = false;
        _isFirstLoad = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        _isFirstLoad = false;
        _hasMore = false;
      });
    }
     final vendors = await _apiService.getFeaturedVendors();
    if (mounted && vendors != null) setState(() => _featuredVendors = vendors);
  }

  Future<void> _refresh() async {
    setState(() {
      _auctions.clear();
      _currentPage = 1;
      _hasMore = true;
      _isFirstLoad = true;
    });
    await _fetchAuctions();
  }

  void _startSearch() {
    setState(() => _isSearching = true);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _searchFocusNode.requestFocus());
  }

  void _stopSearch() {
    _searchFocusNode.unfocus();
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
    setState(() => _isSearching = false);
  }

  void _toggleLiveFilter() {
    setState(() => _showLiveOnly = !_showLiveOnly);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => <Widget>[
          _buildSliverAppBar(),
          
        ],
           body: Column(
        children: [
          if (_featuredAuctions.isNotEmpty) _buildFeaturedSection(), // بەشی ڕیکلام
        
          Expanded(
            child: RefreshIndicator(onRefresh: _refresh, child: _buildBody()),
          ),
        ],
      ),
        
      ),
    );
  }
Widget _buildFeaturedSection() {
  return SizedBox(
    height: 200, // باڵایی دیاریکراو
    child: CarouselSlider.builder(
      itemCount: _featuredAuctions.length,
   // lib/screens/auction_list_screen.dart -> _buildFeaturedSection() -> CarouselSlider.builder()

itemBuilder: (context, index, realIndex) {
  final auction = _featuredAuctions[index];
  final theme = Theme.of(context);

  return GestureDetector(
    onTap: () {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (ctx) => AuctionDetailScreen(auctionId: auction.id)
      )).then((_) => _refresh()); // دوای گەڕانەوە، refresh بکە
    },
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      // چوارچێوەی سەرەki
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      // ClipRRect بۆ خڕکردنی گۆشەکانی ناوەوە
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand, // وا دەکات منداڵەکان هەموو شوێنەکە بگرن
          children: [
            // 1. وێنەی پاشبنەما
            CachedNetworkImage(
              imageUrl: auction.coverImageUrl ?? "https://via.placeholder.com/400x200.png?text=Featured",
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[300]),
              errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
            ),

            // 2. چینی تاریک (gradient) بۆ جوانی
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent, Colors.black.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            
            // 3. ناوەڕۆک (نووسین و زانیاری)
            Positioned(
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ناونیشانی مەزاد
                  Text(
                    auction.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [const Shadow(blurRadius: 2, color: Colors.black54)]
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8.0),
                  
                  // نرخی ئێستا
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      NumberFormat.simpleCurrency().format(auction.currentPrice),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
},
      options: CarouselOptions(
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16/9,
        viewportFraction: 0.85,
      ),
    ),
  );
}
  SliverAppBar _buildSliverAppBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    
        Provider.of<NotificationProvider>(context).unreadCount;

    return SliverAppBar(
      backgroundColor: colorScheme.background,
       foregroundColor: colorScheme.surfaceDim,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      toolbarHeight: 72,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: const InputDecoration(
                hintText: 'گەڕان…',
                border: InputBorder.none,
              ),
              style:
                  const TextStyle(color: Colors.white, fontSize: 18),
            )
          : Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: user?.profilePhotoUrl != null
                      ? NetworkImage(user!.profilePhotoUrl!)
                      : null,
                  child: user?.profilePhotoUrl == null
                      ? const Icon(Icons.person,
                          size: 20, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بەخێربێیت 👋',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.primary,),
                    ),
                    Text(
                      user?.name ?? 'میوان',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
      actions: _isSearching
          ? [
              IconButton(
                icon:
                    const Icon(Icons.close, color: Colors.white),
                onPressed: _stopSearch,
              ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.search),
                color: colorScheme.primary,
                onPressed: _startSearch,
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                color: colorScheme.primary,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (c) => const ChatListScreen()),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  _showLiveOnly
                      ? Icons.live_tv
                      : Icons.live_tv_outlined,
                  color: _showLiveOnly
                      ? Colors.redAccent
                      : colorScheme.primary,
                ),
                onPressed: _toggleLiveFilter,
              ),
            ],
      pinned: true,
      floating: true,
   
    );
  }

 Widget _buildBody() {
  if (_isFirstLoad) return _buildShimmerEffect();
  if (_auctions.isEmpty) {
    return CustomScrollView(
      slivers: [
     //   SliverToBoxAdapter(child: _buildVendorStories()),
        const SliverFillRemaining(
          child: Center(child: Text('هیچ زیادکراوەیەک نەدۆزرایەوە.')),
        ),
      ],
    );
  }

  return CustomScrollView(
    controller: _scrollController,
    slivers: [
    //  SliverToBoxAdapter(child: _buildVendorStories()),
      SliverPadding(
        padding: const EdgeInsets.all(12),
        sliver: SliverMasonryGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childCount: _auctions.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _auctions.length) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildGridAuctionCard(_auctions[index]);
          },
        ),
      ),
    ],
  );
}

  Widget _buildGridAuctionCard(Auction auction) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(
              builder: (ctx) =>
                  AuctionDetailScreen(auctionId: auction.id)))
          .then((_) => _refresh()),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shadowColor: kPrimaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.1,
                  child: CachedNetworkImage(
                    imageUrl: auction.images.isNotEmpty
                        ? auction.images.first.url
                        : '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Image.asset('assets/bid.png',
                            fit: BoxFit.cover),
                    errorWidget: (context, url, error) =>
                        Image.asset('assets/bid.png',
                            fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        auction.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                                color: kPrimaryColor,
                                fontWeight:
                                    FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.simpleCurrency()
                            .format(auction.currentPrice),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: kAccentColor,
                                fontWeight:
                                    FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              left: 8,
              child: TimerBuilder.periodic(
                const Duration(seconds: 1),
                builder: (context) {
                  final remaining = auction.endTime
                      .difference(DateTime.now());
                  if (remaining.isNegative) {
                    return const SizedBox.shrink();
                  }
                    final cardColor = _getTimeColor(remaining);
                    final isUrgent = remaining.inMinutes < 10;
                    return Card(
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8)),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          children: [
                            if (isUrgent)
                              TweenAnimationBuilder<double>(
                                tween: Tween(
                                    begin: 1.0, end: 1.2),
                                duration: const Duration(
                                    milliseconds: 500),
                                builder: (context, scale,
                                        child) =>
                                    Transform.scale(
                                        scale: scale,
                                        child: child),
                                child: const Icon(
                                  Icons.timer_outlined,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              )
                            else
                              const Icon(
                                Icons.timer_outlined,
                                color: Colors.white,
                                size: 14,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              _formatShortTime(remaining),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
  }
Widget _buildVendorStories() {
  if (_featuredVendors.isEmpty) return const SizedBox.shrink();
  
  return Container(
    height: 125,
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: _featuredVendors.length,
      itemBuilder: (context, index) {
        final vendor = _featuredVendors[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (ctx) => VendorProfileScreen(vendorId: vendor.id),
            ));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.yellow, Colors.red, Colors.purple],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundImage: vendor.profilePhotoUrl != null
                        ? NetworkImage(vendor.profilePhotoUrl!)
                        : null,
                    child: vendor.profilePhotoUrl == null
                        ? const Icon(Icons.store, size: 30)
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 70,
                  alignment: Alignment.center,
                  child: Text(
                    vendor.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
} // Formats a Duration as a short string (e.g., 3m 20s).
  String _formatShortTime(Duration d) {
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours.remainder(24)}h';
    }
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }

  // Color changes based on remaining time:
  Color _getTimeColor(Duration remaining) {
    if (remaining.inHours > 1) {
      return kPrimaryColor;       // deep blue for >1 hour
    }
    if (remaining.inMinutes > 10) {
      return kAccentColor;        // gold for mid-range
    }
    return Colors.redAccent;      // red when urgent
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: kSecondaryColor.withOpacity(0.3),
      highlightColor: Colors.grey[100]!,
      child: MasonryGridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate:
            const SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: 6,
        itemBuilder: (context, index) => Card(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                color: Colors.white,
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 80,
                      color: Colors.white,
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
