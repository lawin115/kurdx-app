import 'dart:async';
import 'dart:ui';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:kurdpoint/models/user_model.dart';
import 'package:kurdpoint/screens/chat_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timer_builder/timer_builder.dart';

import '../models/auction_model.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/data_cache_provider.dart';
import '../services/api_service.dart';
import '../auction_detail_screen.dart';
import '../screens/product_detail_screen.dart';

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

// View type enum
enum ViewType { auctions, products }

// Legacy color mappings for backward compatibility
const Color kPrimaryColor = kModernPrimary;
const Color kSecondaryColor = kModernSecondary;
const Color kAccentColor = kModernAccent;
const Color kSurfaceColor = kModernSurface;
const Color kTextPrimary = kModernTextPrimary;
const Color kTextSecondary = kModernTextSecondary;
const Color kBorderColor = kModernBorder;
const Color kWarningColor = kModernWarning;
const Color kDangerColor = kModernError;

class AuctionListScreen extends StatefulWidget {
  const AuctionListScreen({Key? key}) : super(key: key);

  @override
  _AuctionListScreenState createState() => _AuctionListScreenState();
}

class _AuctionListScreenState extends State<AuctionListScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  List<User> _featuredVendors = [];
  Timer? _debounce;
  List<Auction> _featuredAuctions = [];
  List<Auction> _auctions = [];
  List<Product> _products = [];
  ViewType _currentView = ViewType.auctions;
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isFirstLoad = true;
  bool _hasMore = true;
  int? _selectedCategoryId;
  bool _isSearching = false;
  bool _showLiveOnly = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchChanged);
    _loadCachedData(); // Load cached data first for instant display
    _fetchInitialData();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }

  // Load cached data for instant display - Instagram style
  void _loadCachedData() {
    final dataCacheProvider = Provider.of<DataCacheProvider>(context, listen: false);
    
    // Always show cached data immediately - no loading states
    setState(() {
      _auctions = List.from(dataCacheProvider.auctions);
      _featuredVendors = List.from(dataCacheProvider.vendors);
      _isFirstLoad = false; // Never show loading on cached data
    });
    
    if (dataCacheProvider.auctions.isNotEmpty) {
      print("📱 Instagram-style instant display: ${_auctions.length} auctions");
    }
  }

  Future<void> _fetchInitialData() async {
    final dataCacheProvider = Provider.of<DataCacheProvider>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    
    try {
      // Use cached data if available, otherwise fetch from API
      if (dataCacheProvider.vendors.isEmpty && token != null) {
        await dataCacheProvider.fetchVendors(token);
      }
      
      // Fetch featured auctions from API (not cached yet)
      final featuredAuctions = await _apiService.getFeaturedAuctions();
      
      if (mounted) {
        setState(() {
          _featuredAuctions = featuredAuctions ?? [];
          _featuredVendors = dataCacheProvider.vendors;
        });
      }
    } catch (e) {
      if (mounted) {
        print('Error fetching initial data: $e');
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
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
      if (_currentView == ViewType.auctions) {
        _fetchAuctions();
      } else {
        _fetchProducts();
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _refresh());
  }

  Future<void> _fetchAuctions() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final dataCacheProvider = Provider.of<DataCacheProvider>(context, listen: false);
    
    // Instagram-style: Show cached data immediately, update in background
    if (_searchController.text.isEmpty && _selectedCategoryId == null) {
      // For normal browsing, always use cached data for instant display
      if (dataCacheProvider.auctions.isNotEmpty) {
        setState(() {
          _auctions = List.from(dataCacheProvider.auctions);
          _isFirstLoad = false;
          _isLoading = false;
        });
        // Trigger background refresh
        if (token != null) {
          dataCacheProvider.backgroundFetchAuctions(token);
        }
        return;
      }
    }
    
    // Only show loading for search/filter or when no cached data
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final paginatedData = await _apiService.getAuctions(
        page: _currentPage,
        searchTerm: _searchController.text,
        categoryId: _selectedCategoryId,
        apiToken: token,
        limit: 10,
        liveOnly: _showLiveOnly,
      );

      if (paginatedData != null && mounted) {
        final List<dynamic> auctionData = paginatedData['data'] as List? ?? [];
        final List<Auction> newAuctions =
            auctionData.map((d) => Auction.fromJson(d)).toList();

        setState(() {
          if (_currentPage == 1) {
            _auctions = newAuctions;
          } else {
            _auctions.addAll(newAuctions);
          }
          _currentPage++;
          _hasMore = newAuctions.length == 10;
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    }
  }

  Future<void> _fetchProducts() async {
    // Only show loading for search/filter or when no cached data
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final paginatedData = await _apiService.getProducts(
        page: _currentPage,
        searchTerm: _searchController.text,
        categoryId: _selectedCategoryId,
      );

      if (paginatedData != null && mounted) {
        print("Products API response: $paginatedData");
        final List<dynamic> productData = paginatedData['data'] as List? ?? [];
        print("Products data count: ${productData.length}");
        
        final List<Product> newProducts = [];
        try {
          for (var productJson in productData) {
            try {
              newProducts.add(Product.fromJson(productJson));
            } catch (productError) {
              print("Error parsing individual product: $productError");
              print("Problematic product data: $productJson");
            }
          }
          print("Successfully parsed ${newProducts.length} products");
        } catch (parseError) {
          print("Error parsing products: $parseError");
          print("Sample product data: ${productData.isNotEmpty ? productData[0] : 'No data'}");
        }

        setState(() {
          if (_currentPage == 1) {
            _products = newProducts;
          } else {
            _products.addAll(newProducts);
          }
          _currentPage++;
          _hasMore = newProducts.length == 10;
          _isLoading = false;
          _isFirstLoad = false;
        });
      } else {
        print("No products data received from API");
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isFirstLoad = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching products: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFirstLoad = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final dataCacheProvider = Provider.of<DataCacheProvider>(context, listen: false);
    
    setState(() {
      if (_currentView == ViewType.auctions) {
        _auctions.clear();
      } else {
        _products.clear();
      }
      _currentPage = 1;
      _hasMore = true;
      _isFirstLoad = true;
    });
    
    // If searching or filtering, don't use cache
    if (_searchController.text.isNotEmpty || _selectedCategoryId != null) {
      if (_currentView == ViewType.auctions) {
        await _fetchAuctions();
      } else {
        await _fetchProducts();
      }
    } else {
      // Force refresh cache for pull-to-refresh
      if (_currentView == ViewType.auctions && token != null) {
        await dataCacheProvider.fetchAuctions(token, forceRefresh: true);
        setState(() {
          _auctions = List.from(dataCacheProvider.auctions);
          _isFirstLoad = false;
        });
      } else {
        // For products, we just fetch fresh data
        await _fetchProducts();
      }
    }
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
      _refresh();
    }
    setState(() => _isSearching = false);
  }

  void _toggleLiveFilter() {
    setState(() => _showLiveOnly = !_showLiveOnly);
    _refresh();
  }

  void _switchView(ViewType viewType) {
    if (_currentView != viewType) {
      setState(() {
        _currentView = viewType;
        _currentPage = 1;
        _hasMore = true;
        _isFirstLoad = true;
      });
      _refresh();
    }
  }

  Widget _buildViewToggleButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _switchView(ViewType.auctions),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: _currentView == ViewType.auctions
                      ? LinearGradient(
                          colors: [kModernPrimary, kModernAccent],
                        )
                      : null,
                  color: _currentView == ViewType.auctions ? null : kModernCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _currentView == ViewType.auctions
                        ? kModernPrimary
                        : kModernBorder,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    "Bid Auctions",
                    style: TextStyle(
                      color: _currentView == ViewType.auctions
                          ? Colors.white
                          : kModernTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _switchView(ViewType.products),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: _currentView == ViewType.products
                      ? LinearGradient(
                          colors: [kModernPrimary, kModernAccent],
                        )
                      : null,
                  color: _currentView == ViewType.products ? null : kModernCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _currentView == ViewType.products
                        ? kModernPrimary
                        : kModernBorder,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    "Products",
                    style: TextStyle(
                      color: _currentView == ViewType.products
                          ? Colors.white
                          : kModernTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernProductCard(Product product, int index) {
    try {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: kModernCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: kModernSurface,
                    highlightColor: kModernCard,
                    child: Container(
                      height: 180,
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 180,
                    color: kModernSurface,
                    child: Icon(
                      Icons.error_outline,
                      color: kModernTextLight,
                    ),
                  ),
                ),
              ),
              // Product Details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kModernTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Product Description
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: kModernTextSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Price and Quantity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [kModernPrimary.withOpacity(0.1), kModernAccent.withOpacity(0.1)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Price: \$${product.price.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kModernPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Quantity
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kModernSurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Qty: ${product.quantity}",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: kModernTextSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Sold Out Status
                    if (product.isSoldOut)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kModernError.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "SOLD OUT",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kModernError,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error building product card for product ${product.id}: $e');
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: kModernCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kModernError.withOpacity(0.5)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: kModernError, size: 32),
              const SizedBox(height: 8),
              Text('Error displaying product', style: TextStyle(color: kModernError)),
            ],
          ),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kModernSurface,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _buildModernSliverAppBar(),
        ],
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: kModernPrimary,
          backgroundColor: kModernCard,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildModernFeaturedSection()),
              SliverToBoxAdapter(child: _buildModernVendorsSection()),
              SliverToBoxAdapter(child: _buildViewToggleButtons()),
              SliverToBoxAdapter(child: _buildSectionHeader()),
              if (_isFirstLoad)
                SliverFillRemaining(child: _buildModernShimmerEffect())
              else if (_currentView == ViewType.auctions && _auctions.isEmpty || _currentView == ViewType.products && _products.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childCount: _currentView == ViewType.auctions 
                        ? _auctions.length + (_hasMore ? 1 : 0)
                        : _products.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_currentView == ViewType.auctions && index == _auctions.length ||
                          _currentView == ViewType.products && index == _products.length) {
                        return _buildLoadingIndicator();
                      }
                      return SlideTransition(
                        position: _slideAnimation,
                        child: _currentView == ViewType.auctions
                            ? _buildModernAuctionCard(_auctions[index], index)
                            : _buildModernProductCard(_products[index], index),
                      );
                    },
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // Modern Professional Sliver App Bar with Enhanced Glassmorphism
  SliverAppBar _buildModernSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kModernGradientStart.withOpacity(0.95),
                  kModernGradientEnd.withOpacity(0.95),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      elevation: 0,
      toolbarHeight: 70,
      floating: true,
      pinned: true,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: animation.drive(
              Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _isSearching
            ? _buildModernSearchField()
            : _buildBrandTitle(),
      ),
      actions: _buildAppBarActions(),
    );
  }

  Widget _buildBrandTitle() {
    return Container(
      key: const ValueKey('brand'),
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.8)],
        ).createShader(bounds),
        child: Text(
          "BUY X",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                fontSize: 20,
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
    );
  }

  Widget _buildModernSearchField() {
    return Container(
      key: const ValueKey('search'),
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: _currentView == ViewType.auctions ? "Search auctions..." : "Search products...",
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return _isSearching
        ? [
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
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _stopSearch();
                },
                splashRadius: 20,
              ),
            )
          ]
        : [
            _buildActionButton(
              icon: Icons.search_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                _startSearch();
              },
            ),
            _buildActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, _) => const ChatListScreen(),
                    transitionsBuilder: (context, animation, _, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeOutCubic)),
                        ),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              },
            ),
            _buildActionButton(
              icon: _showLiveOnly ? Icons.live_tv_rounded : Icons.live_tv_outlined,
              onPressed: () {
                HapticFeedback.lightImpact();
                _toggleLiveFilter();
              },
              isActive: _showLiveOnly,
            ),
          ];
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isActive 
            ? Colors.white.withOpacity(0.3) 
            : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        onPressed: onPressed,
        splashRadius: 20,
      ),
    );
  }

  // Modern Featured Vendors Section
  Widget _buildModernVendorsSection() {
    if (_featuredVendors.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kModernAccent, kModernSecondary],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Featured Vendors",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kModernTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kModernAccent.withOpacity(0.1), kModernSecondary.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Top Sellers",
                    style: TextStyle(
                      color: kModernAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _featuredVendors.length,
              itemBuilder: (context, index) {
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(20 * (1 - value), 0),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: _buildVendorCard(_featuredVendors[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVendorCard(User vendor) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kModernAccent, kModernSecondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: kModernAccent.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kModernCard,
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: (vendor.profilePhotoUrl != null && vendor.profilePhotoUrl!.isNotEmpty && !vendor.profilePhotoUrl!.contains('null'))
                      ? vendor.profilePhotoUrl!
                      : 'https://via.placeholder.com/150', // Placeholder image
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kModernAccent.withOpacity(0.1),
                          kModernSecondary.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: kModernAccent,
                      size: 28,
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.person_rounded,
                    color: kModernAccent,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vendor.name,
            style: TextStyle(
              fontSize: 11,
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

  // Enhanced Modern Featured Section
  Widget _buildModernFeaturedSection() {
    if (_featuredAuctions.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kModernPrimary, kModernAccent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Featured Auctions",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kModernTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kModernPrimary.withOpacity(0.1), kModernAccent.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Premium",
                    style: TextStyle(
                      color: kModernPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 240,
            child: CarouselSlider.builder(
              itemCount: _featuredAuctions.length,
              itemBuilder: (context, index, realIndex) {
                return _buildModernFeaturedCard(_featuredAuctions[index]);
              },
              options: CarouselOptions(
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                enlargeCenterPage: true,
                viewportFraction: 0.85,
                enlargeStrategy: CenterPageEnlargeStrategy.height,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFeaturedCard(Auction auction) {
    return GestureDetector(
      onTap: () => _navigateToAuctionDetail(auction.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'featured-${auction.id}',
                child: CachedNetworkImage(
                  imageUrl: auction.coverImageUrl ?? "https://via.placeholder.com/400x240",
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: kBorderColor,
                    child: const Center(
                      child: CircularProgressIndicator(color: kPrimaryColor),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: kBorderColor,
                    child: const Icon(Icons.image_not_supported, color: kTextSecondary),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kAccentColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Featured",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      auction.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPriceChip(auction.currentPrice),
                        _buildTimeRemainingChip(auction.endTime),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_border,
                          color: kPrimaryColor,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceChip(double price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kSecondaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        NumberFormat.simpleCurrency().format(price),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTimeRemainingChip(DateTime endTime) {
    return TimerBuilder.periodic(
      const Duration(seconds: 1),
      builder: (context) {
        final remaining = endTime.difference(DateTime.now());
        if (remaining.isNegative) return const SizedBox.shrink();

        final color = _getTimeColor(remaining);
        final isUrgent = remaining.inMinutes < 10;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isUrgent)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 1.3),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    child: Icon(
                      Icons.timer_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                )
              else
                Icon(Icons.timer_outlined, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                _formatShortTime(remaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🎯 Section Header
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kAccentColor, kPrimaryColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _currentView == ViewType.auctions ? "All Auctions" : "All Products",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: kModernTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const Spacer(),
          if (_currentView == ViewType.auctions)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kModernSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kModernBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_view_rounded, size: 16, color: kModernTextSecondary),
                  const SizedBox(width: 4),
                  Text(
                    "${_auctions.length}",
                    style: TextStyle(
                      color: kModernTextSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kModernSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kModernBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_view_rounded, size: 16, color: kModernTextSecondary),
                  const SizedBox(width: 4),
                  Text(
                    "${_products.length}",
                    style: TextStyle(
                      color: kModernTextSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 🎯 Modern Auction Card
  Widget _buildModernAuctionCard(Auction auction, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: () => _navigateToAuctionDetail(auction.id),
              child: Container(
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
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCardImage(auction),
                      _buildCardContent(auction),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardImage(Auction auction) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1.2,
          child: Hero(
            tag: 'auction-${auction.id}',
            child: CachedNetworkImage(
              imageUrl: auction.images.isNotEmpty ? auction.images.first.url : '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: kBorderColor,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: kPrimaryColor,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: kBorderColor,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported, color: kTextSecondary, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      "وێنە نییە",
                      style: TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: _buildTimeCountdown(auction.endTime),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.remove_red_eye, size: 14, color: kTextSecondary),
                const SizedBox(width: 4),
                Text(
                  auction.viewCount.toString(),
                  style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContent(Auction auction) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            auction.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.monetization_on, size: 16, color: kAccentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  NumberFormat.simpleCurrency().format(auction.currentPrice),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: kAccentColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group, size: 12, color: kPrimaryColor),
                    const SizedBox(width: 4),
                    Text(
                      auction.bidCount.toString(),
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPrimaryColor.withOpacity(0.1), kSecondaryColor.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "بینین",
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCountdown(DateTime endTime) {
    return TimerBuilder.periodic(
      const Duration(seconds: 1),
      builder: (context) {
        final remaining = endTime.difference(DateTime.now());
        if (remaining.isNegative) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: kTextSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "تەواو بووە",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        final color = _getTimeColor(remaining);
        final isUrgent = remaining.inMinutes < 10;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isUrgent)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 1.2),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    child: Icon(
                      Icons.timer_outlined,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                )
              else
                Icon(Icons.timer_outlined, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text(
                _formatShortTime(remaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Modern Empty State with Enhanced Design
  Widget _buildEmptyState() {
    final isAuctionView = _currentView == ViewType.auctions;
    final showLiveOnly = _showLiveOnly && isAuctionView;
    
    String title, subtitle;
    IconData icon;
    
    if (showLiveOnly) {
      title = isAuctionView ? "No Live Auctions" : "No Live Products";
      subtitle = "When live items are available, they will appear here";
      icon = Icons.live_tv_outlined;
    } else {
      title = isAuctionView ? "No Auctions Found" : "No Products Found";
      subtitle = "Try adjusting your search terms or removing filters to see more results";
      icon = Icons.search_off_rounded;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
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
                boxShadow: [
                  BoxShadow(
                    color: kModernPrimary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 56,
                color: kModernPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: kModernTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                subtitle,
                style: TextStyle(
                  color: kModernTextSecondary,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Container(
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
                    _refresh();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                          "Refresh",
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
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Loading Indicator
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernPrimary, kModernAccent],
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
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Loading more...",
            style: TextStyle(
              color: kModernTextSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Modern Shimmer Effect
  Widget _buildModernShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: kModernBorder.withOpacity(0.3),
      highlightColor: kModernCard,
      period: const Duration(milliseconds: 1200),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MasonryGridView.builder(
          gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
          ),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          itemCount: 6,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
              color: kModernCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: kModernBorder,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: kModernCard,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: kModernCard,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 100,
                        decoration: BoxDecoration(
                          color: kModernCard,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            height: 12,
                            width: 60,
                            decoration: BoxDecoration(
                              color: kModernCard,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            height: 12,
                            width: 40,
                            decoration: BoxDecoration(
                              color: kModernCard,
                              borderRadius: BorderRadius.circular(6),
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
        ),
      ),
    );
  }

  // 🎯 Helper Methods
  String _formatShortTime(Duration d) {
    if (d.inDays > 0) {
      return '${d.inDays}ڕۆژ ${d.inHours.remainder(24)}س';
    }
    if (d.inHours > 0) {
      return '${d.inHours}س ${d.inMinutes.remainder(60)}خ';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}خ ${d.inSeconds.remainder(60)}چ';
    }
    return '${d.inSeconds}چرکە';
  }

  Color _getTimeColor(Duration remaining) {
    if (remaining.inHours > 1) {
      return kPrimaryColor;
    }
    if (remaining.inMinutes > 10) {
      return kWarningColor;
    }
    return kDangerColor;
  }

  Future<void> _navigateToAuctionDetail(int auctionId) async {
    HapticFeedback.lightImpact();
    
    final updated = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AuctionDetailScreen(auctionId: auctionId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    );

    if (updated == true) {
      _refresh();
    }
  }
}