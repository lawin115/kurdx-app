// lib/screens/auction_detail_screen.dart

import 'package:flutter_animate/animate.dart';
import 'package:flutter_animate/effects/scale_effect.dart';
import 'package:flutter_animate/effects/shake_effect.dart';
import 'package:flutter_animate/effects/then_effect.dart';
import 'package:kurdpoint/models/bid_model.dart';
import 'package:kurdpoint/models/conversation_model.dart';
import 'package:kurdpoint/screens/chat_screen.dart';
import 'package:kurdpoint/screens/login_screen.dart';
import 'package:kurdpoint/screens/vendor_profile_screen.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:intl/intl.dart';
import 'package:timer_builder/timer_builder.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';

import '../models/auction_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

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
const Color kSuccessColor = kModernSuccess;

class AuctionDetailScreen extends StatefulWidget {
  final int auctionId;
  const AuctionDetailScreen({super.key, required this.auctionId});

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen>
    with TickerProviderStateMixin {
  // Controllers & Services
  final ApiService _apiService = ApiService();
  final CarouselController _carouselController = CarouselController();
  final TextEditingController _bidController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PageController _imagePageController = PageController();
  late final FocusNode _commentFocusNode;

  // Animation Controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _priceController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _priceAnimation;

  // Data State
  Auction? _auction;
  String? _token;
  User? _currentUser;
  PusherChannelsClient? _pusherClient;

  // UI State
  bool _isLoading = true;
  bool _isPlacingBid = false;
  bool _isAuctionActive = true;
  int _currentImageIndex = 0;
  int? _replyToCommentId;
  bool _isRetryingConnection = false;
  bool _hasAgreedToVendorTerms = false;
  bool _showBidHistory = false;
  bool _showAppBar = false;
  GlobalKey _priceKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _commentFocusNode = FocusNode();
    _scrollController.addListener(_onScroll);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _token = auth.token;
    _currentUser = auth.user;
    _fetchAuctionDetails();
    _initPusher();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _priceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _priceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _priceController, curve: Curves.elasticOut),
    );

    _slideController.forward();
    _fadeController.forward();
  }

  void _onScroll() {
    final shouldShowAppBar = _scrollController.offset > 200;
    if (shouldShowAppBar != _showAppBar) {
      setState(() => _showAppBar = shouldShowAppBar);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _priceController.dispose();
    _pusherClient?.disconnect();
    _bidController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuctionDetails({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);
    final fetchedAuction = await _apiService.getAuctionDetails(widget.auctionId, _token);
    if (mounted) {
      setState(() {
        _auction = fetchedAuction;
        _isLoading = false;
        if (_auction != null) {
          _isAuctionActive = DateTime.now().isBefore(_auction!.endTime);
          if (_bidController.text.isEmpty) {
            _bidController.text = (_auction!.currentPrice + _auction!.bidIncrement).toStringAsFixed(2);
          }
        }
      });
    }
  }

  Future<void> _initPusher() async {
    if (_isRetryingConnection) return;
    _isRetryingConnection = true;
    try {
      const String laravelHost = "10.0.2.2"; // Use 10.0.2.2 for Android emulator to access localhost
      const String reverbPort = "8080"; // Default port for Laravel Reverb
      const String appKey = "qmkcqfx960e6h7q00qdp";
      final String channelName = 'auction.${widget.auctionId}';

      final hostOptions = PusherChannelsOptions.fromHost(
          scheme: 'ws', host: laravelHost, port: int.parse(reverbPort), key: appKey);
      _pusherClient = PusherChannelsClient.websocket(
        options: hostOptions,
        connectionErrorHandler: (_, __, refresh) => refresh(),
      );

      final channel = _pusherClient!.publicChannel(channelName);

      channel.bind('BidPlaced').listen((event) {
        if (mounted && event.data != null) {
          try {
            final eventData = jsonDecode(event.data!);
            setState(() {
              _auction = _auction!.copyWith(
                currentPrice: double.parse(eventData['current_price'].toString()),
                bids: [Bid.fromJson(eventData['latest_bid']), ..._auction!.bids],
              );
              _priceKey = GlobalKey();
            });
            _priceController.forward(from: 0.0);
          } catch (e) {
            print("Error parsing BidPlaced: $e");
            _fetchAuctionDetails(showLoading: false);
          }
        }
      });

      channel.bind('AuctionTimeExtended').listen((event) {
        if (mounted && event.data != null && _auction != null) {
          try {
            final eventData = jsonDecode(event.data!);
            setState(() => _auction = _auction!.copyWith(
                endTime: DateTime.parse(eventData['newEndTime']['date'])));
          } catch (e) {
            print("Error parsing TimeExtended: $e");
          }
        }
      });

      _pusherClient!.onConnectionEstablished.listen((_) => channel.subscribe());
      await _pusherClient!.connect();
      _isRetryingConnection = false;
    } catch (e) {
      _retryConnection();
    }
  }

  void _retryConnection() {
    if (mounted) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _isRetryingConnection = false;
          _initPusher();
        }
      });
    }
  }

  Future<void> _placeBid() async {
    if (_isPlacingBid || _bidController.text.trim().isEmpty) return;
    if (_token == null) {
      _navigateToLogin();
      return;
    }

    final vendorTerms = _auction?.user?.vendorTerms;
    if (vendorTerms != null && vendorTerms.isNotEmpty && !_hasAgreedToVendorTerms) {
      final didAgree = await _showVendorTermsDialog(vendorTerms);
      if (didAgree == true) {
        setState(() => _hasAgreedToVendorTerms = true);
      } else {
        return;
      }
    }

    final highestBidder = _auction?.bids.isNotEmpty == true ? _auction!.bids.first.user : null;
    if (highestBidder?.id == _currentUser?.id) {
      _showSnackBar('تۆ پێشتر بەرزترین نرخت داناوە!', kWarningColor);
      return;
    }

    setState(() => _isPlacingBid = true);
    HapticFeedback.lightImpact();

    final success = await _apiService.placeBid(widget.auctionId, _bidController.text, _token!);
    if (mounted) {
      setState(() => _isPlacingBid = false);
      if (success) {
        _bidController.clear();
        _showSnackBar('نرخەکەت بە سەرکەوتوویی زیادکرا!', kSuccessColor);
        HapticFeedback.mediumImpact();
      } else {
        _showSnackBar('هەڵەیەک ڕوویدا، نرخەکەت بەرزتر بکە.', kDangerColor);
        HapticFeedback.heavyImpact();
      }
    }
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

  Future<bool?> _showVendorTermsDialog(String terms) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('مەرجەکانی فرۆشیار', 
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700)),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Text(terms, style: TextStyle(color: kTextSecondary, height: 1.5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('ڕەتکردنەوە', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ڕازیم'),
          ),
        ],
      ),
    );
  }

  Future<void> _postComment() async {
    final commentBody = _commentController.text.trim();
    if (commentBody.isEmpty || _token == null) return;

    _commentFocusNode.unfocus();
    final tempBody = _commentController.text;
    _commentController.clear();

    final newComment = await _apiService.postComment(
        widget.auctionId, tempBody, _replyToCommentId, _token!);
    if (mounted) {
      if (newComment != null) {
        _fetchAuctionDetails(showLoading: false);
        setState(() => _replyToCommentId = null);
        _showSnackBar('کۆمێنتەکەت زیادکرا', kSuccessColor);
      } else {
        setState(() => _commentController.text = tempBody);
        _showSnackBar('ناردنی کۆمێنت سەرکەوتوو نەبوو', kDangerColor);
      }
    }
  }

  void _toggleWatchlist() {
    Provider.of<AuthProvider>(context, listen: false).toggleWatchlist(_auction!.id);
    HapticFeedback.lightImpact();
  }

  Future<void> _shareAuction() async {
    if (_token == null) {
      _showSnackBar('بۆ هاوبەشیکردن، تکایە بچۆ ژوورەوە.', kWarningColor);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: kPrimaryColor),
              SizedBox(height: 16),
              Text('چاوەڕوان بە...', style: TextStyle(color: kTextSecondary)),
            ],
          ),
        ),
      ),
    );

    final conversations = await _apiService.getConversations(_token!);
    if (mounted) Navigator.of(context).pop();

    if (mounted) {
      if (conversations == null || conversations.isEmpty) {
        _showSnackBar('تۆ هێشتا هیچ گفتوگەیەکت نییە.', kWarningColor);
        return;
      }
      _showShareDialog(conversations);
    }
  }

  void _showShareDialog(List<Conversation> conversations) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBorderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [kPrimaryColor, kSecondaryColor]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.share, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "هاوبەشیکردن لەگەڵ",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: conversations.length,
                itemBuilder: (ctx, index) => _buildConversationItem(conversations[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationItem(Conversation convo) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Hero(
          tag: 'avatar-${convo.otherUser.id}',
          child: CircleAvatar(
            radius: 24,
            backgroundColor: kPrimaryColor.withOpacity(0.1),
            backgroundImage: convo.otherUser.profilePhotoUrl != null
                ? NetworkImage(convo.otherUser.profilePhotoUrl!)
                : null,
            child: convo.otherUser.profilePhotoUrl == null
                ? Text(
                    convo.otherUser.name[0].toUpperCase(),
                    style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),
                  )
                : null,
          ),
        ),
        title: Text(
          convo.otherUser.name,
          style: const TextStyle(fontWeight: FontWeight.w600, color: kTextPrimary),
        ),
        subtitle: convo.latestMessage != null
            ? Text(
                convo.latestMessage!.body ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: kTextSecondary),
              )
            : null,
        trailing: Icon(Icons.send, color: kPrimaryColor, size: 20),
        onTap: () => _handleShareToConversation(convo),
      ),
    );
  }

  Future<void> _handleShareToConversation(Conversation convo) async {
    Navigator.of(context).pop();

    final sentMessage = await _apiService.shareAuctionInChat(convo.id, _auction!.id, _token!);

    if (mounted) {
      if (sentMessage != null) {
        _showSnackBar('مەزاد بۆ ${convo.otherUser.name} نێردرا', kSuccessColor);
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
              conversationId: convo.id,
              otherUser: convo.otherUser,
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
      } else {
        _showSnackBar('هەڵەیەک لە ناردندا ڕوویدا', kDangerColor);
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurfaceColor,
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(),
      body: _isLoading ? _buildLoadingShimmer() : _auction == null ? _buildErrorState() : _buildContent(),
      bottomNavigationBar: _auction != null ? _buildBottomBidArea() : null,
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: _showAppBar ? Colors.white.withOpacity(0.95) : Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      flexibleSpace: _showAppBar
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
          color: _showAppBar ? Colors.transparent : Colors.black.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: BackButton(
          color: _showAppBar ? kTextPrimary : Colors.white,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
      title: AnimatedOpacity(
        opacity: _showAppBar ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          _auction?.title ?? '',
          style: TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: _buildAppBarActions(),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      if (_auction != null) ...[
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _showAppBar ? Colors.transparent : Colors.black.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.share_rounded,
              color: _showAppBar ? kTextPrimary : Colors.white,
              size: 22,
            ),
            onPressed: _shareAuction,
          ),
        ),
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _showAppBar ? Colors.transparent : Colors.black.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Consumer<AuthProvider>(
            builder: (context, auth, child) => IconButton(
              icon: Icon(
                auth.isInWatchlist(_auction!.id) ? Icons.favorite : Icons.favorite_border,
                color: auth.isInWatchlist(_auction!.id) 
                    ? kDangerColor 
                    : (_showAppBar ? kTextPrimary : Colors.white),
                size: 22,
              ),
              onPressed: _toggleWatchlist,
            ),
          ),
        ),
      ]
    ];
  }

  Widget _buildContent() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: _buildImageGallery(),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeInUp(
            duration: const Duration(milliseconds: 700),
            delay: const Duration(milliseconds: 100),
            child: _buildMainInfoSection(),
          ),
        ),
        SliverToBoxAdapter(
          child: FadeInUp(
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 200),
            child: _buildBidHistorySection(),
          ),
        ),
        if (_showBidHistory)
          SliverToBoxAdapter(
            child: FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Container(
                child: Column(
                  children: [
                    if (_auction!.bids.isEmpty)
                      _buildEmptyBidHistoryState()
                    else
                      ..._auction!.bids.asMap().entries.map((entry) {
                        final index = entry.key;
                        final bid = entry.value;
                        return FadeInUp(
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: index * 50),
                          child: _buildBidHistoryItem(bid, index),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: FadeInUp(
            duration: const Duration(milliseconds: 900),
            delay: const Duration(milliseconds: 300),
            child: _buildCommentSection(),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 120)), // Bottom padding for FAB
      ],
    );
  }

  // 🎯 Modern Image Gallery
  Widget _buildImageGallery() {
    if (_auction!.images.isEmpty) {
      return Container(
        height: 350,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kBorderColor, kSurfaceColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported_outlined, size: 64, color: kTextSecondary),
              const SizedBox(height: 16),
              Text(
                'وێنە بەردەست نییە',
                style: TextStyle(color: kTextSecondary, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 350,
      child: Stack(
        children: [
          PageView.builder(
            controller: _imagePageController,
            onPageChanged: (index) => setState(() => _currentImageIndex = index),
            itemCount: _auction!.images.length,
            itemBuilder: (context, index) {
              return Hero(
                tag: 'auction-image-${_auction!.id}-$index',
                child: CachedNetworkImage(
                  imageUrl: _auction!.images[index].url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kBorderColor, Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kBorderColor, kSurfaceColor],
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.error_outline, color: kDangerColor, size: 48),
                    ),
                  ),
                ),
              );
            },
          ),
          // Image indicators with glassmorphism effect
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _auction!.images.asMap().entries.map((entry) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: _currentImageIndex == entry.key ? 24 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: _currentImageIndex == entry.key 
                                ? Colors.white 
                                : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: _currentImageIndex == entry.key 
                                ? [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Fullscreen view button
          Positioned(
            top: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white, size: 24),
                    onPressed: () => _showFullscreenImages(),
                  ),
                ),
              ),
            ),
          ),
          // Navigation arrows
          if (_auction!.images.length > 1) ...[
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentImageIndex > 0) {
                      _imagePageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chevron_left, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentImageIndex < _auction!.images.length - 1) {
                      _imagePageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chevron_right, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  // 🎯 Modern Main Info Section
  Widget _buildMainInfoSection() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.2), // Start off-screen
        end: Offset.zero,
      ).animate(_slideAnimation),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Category
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _auction!.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: kTextPrimary,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kPrimaryColor.withOpacity(0.1), kSecondaryColor.withOpacity(0.1)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'کاتەگۆری: ${_auction!.category?.name ?? 'عامل'}',
                            style: TextStyle(
                              color: kPrimaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildViewCounter(),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Description
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description_outlined, color: kTextSecondary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'وەسف',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _auction!.description,
                      style: TextStyle(
                        color: kTextSecondary,
                        height: 1.6,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Vendor Info
              _buildModernVendorCard(),
              
              const SizedBox(height: 20),
              
              // Price & Bidding Info
              _buildModernPriceCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorderColor),
        boxShadow: [
          BoxShadow(
            color: kTextPrimary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, color: kTextSecondary, size: 16),
          const SizedBox(width: 6),
          Text(
            '${_auction?.bids?.length ?? 0}', // Use actual view count or bids count as proxy
            style: TextStyle(
              color: kTextSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernVendorCard() {
    final vendor = _auction!.user;
    if (vendor == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withOpacity(0.05),
            kSecondaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  VendorProfileScreen(vendorId: vendor.id),
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'vendor-${vendor.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: kPrimaryColor.withOpacity(0.2), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: kPrimaryColor.withOpacity(0.1),
                      backgroundImage: vendor.profilePhotoUrl != null
                          ? NetworkImage(vendor.profilePhotoUrl!)
                          : null,
                      child: vendor.profilePhotoUrl == null
                          ? Icon(Icons.storefront, color: kPrimaryColor, size: 28)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.verified, color: kSuccessColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'فرۆشیاری پەسەندکراو',
                            style: TextStyle(
                              color: kSuccessColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '4.8 ⭐ (156 نرخ)',
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: kPrimaryColor,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernPriceCard() {
    final formatCurrency = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final highestBidder = _auction!.bids.isNotEmpty ? _auction!.bids.first.user : null;
    final isCurrentUserHighest = highestBidder?.id == _currentUser?.id;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kAccentColor.withOpacity(0.05), kSuccessColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kAccentColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Current Price Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نرخی ئێستا',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      key: _priceKey,
                      animation: _priceAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _priceAnimation.value,
                          child: Text(
                            formatCurrency.format(_auction!.currentPrice),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: kAccentColor,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                if (highestBidder != null) _buildHighestBidderBadge(highestBidder, isCurrentUserHighest),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Statistics Row
            Row(
              children: [
                _buildStatItem('بیدەرەکان', '${_auction!.bids.length}', Icons.group_outlined),
                const SizedBox(width: 20),
                _buildStatItem('کەمترین زیادکردن', formatCurrency.format(_auction!.bidIncrement), Icons.add_circle_outline),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Container(
              width: double.infinity,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kBorderColor.withOpacity(0),
                    kBorderColor,
                    kBorderColor.withOpacity(0),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Countdown Timer
            _buildModernCountdownTimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHighestBidderBadge(User highestBidder, bool isCurrentUserHighest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrentUserHighest 
              ? [kSuccessColor, kAccentColor]
              : [kWarningColor, kPrimaryColor],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isCurrentUserHighest ? kSuccessColor : kWarningColor).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCurrentUserHighest ? Icons.emoji_events : Icons.person,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            isCurrentUserHighest ? 'تۆ براوەیت!' : highestBidder.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: kTextSecondary, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCountdownTimer() {
    return TimerBuilder.periodic(
      const Duration(seconds: 1),
      builder: (context) {
        final now = DateTime.now();
        if (now.isAfter(_auction!.endTime)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isAuctionActive) {
              setState(() => _isAuctionActive = false);
            }
          });
          return _buildEndedState();
        }
        
        final remaining = _auction!.endTime.difference(now);
        return Column(
          children: [
            Text(
              'کاتی ماوە',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimeUnit('رۆژ', remaining.inDays),
                _buildTimeUnit('کاتژمێر', remaining.inHours.remainder(24)),
                _buildTimeUnit('خولەک', remaining.inMinutes.remainder(60)),
                _buildTimeUnit('چرکە', remaining.inSeconds.remainder(60)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeUnit(String label, int value) {
    final color = _getTimeUnitColor(label, value);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimeUnitColor(String label, int value) {
    if (label == 'رۆژ' && value > 0) return kPrimaryColor;
    if (label == 'کاتژمێر' && value > 1) return kSuccessColor;
    if (label == 'خولەک' && value > 10) return kWarningColor;
    return kDangerColor;
  }

  Widget _buildEndedState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kDangerColor.withOpacity(0.1), kDangerColor.withOpacity(0.2)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kDangerColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_off, color: kDangerColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'مەزاد کۆتایی هات',
            style: TextStyle(
              color: kDangerColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 Modern Bid History Section
  Widget _buildBidHistorySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kPrimaryColor, kSecondaryColor]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مێژووی نرخەکان',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: kTextPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (_auction!.bids.isNotEmpty)
                        Text(
                          '${_auction!.bids.length} بیدی تۆمارکراو',
                          style: TextStyle(color: kTextSecondary, fontSize: 13),
                        ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: kSurfaceColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: kBorderColor),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _showBidHistory ? Icons.expand_less : Icons.expand_more,
                      color: kTextPrimary,
                    ),
                    onPressed: () => setState(() => _showBidHistory = !_showBidHistory),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidHistoryList() {
    if (_auction!.bids.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kTextSecondary.withOpacity(0.1), kTextSecondary.withOpacity(0.05)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.history_toggle_off, size: 40, color: kTextSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                'هێشتا هیچ نرخێک زیادنەکراوە',
                style: TextStyle(
                  fontSize: 16,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'یەکەم کەس ببە کە نرخ زیاد دەکات!',
                style: TextStyle(
                  fontSize: 14,
                  color: kTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList.separated(
      itemCount: _auction!.bids.length,
      itemBuilder: (context, index) {
        final bid = _auction!.bids[index];
        final isCurrentUser = bid.user?.id == _currentUser?.id;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrentUser ? kSuccessColor.withOpacity(0.3) : kBorderColor,
            ),
            boxShadow: [
              if (isCurrentUser)
                BoxShadow(
                  color: kSuccessColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrentUser ? kSuccessColor : kPrimaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: isCurrentUser 
                        ? kSuccessColor.withOpacity(0.1) 
                        : kSurfaceColor,
                    backgroundImage: bid.user?.profilePhotoUrl != null
                        ? NetworkImage(bid.user!.profilePhotoUrl!)
                        : null,
                    child: bid.user?.profilePhotoUrl == null
                        ? Text(
                            bid.user?.name[0].toUpperCase() ?? '?',
                            style: TextStyle(
                              color: isCurrentUser ? kSuccessColor : kTextPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bid.user?.name ?? 'بەکارهێنەری سڕاوە',
                              style: TextStyle(
                                fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                                color: isCurrentUser ? kSuccessColor : kTextPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isCurrentUser)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: kSuccessColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'تۆ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d, h:mm a').format(bid.createdAt),
                        style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCurrentUser 
                          ? [kSuccessColor, kAccentColor]
                          : [kPrimaryColor.withOpacity(0.1), kSecondaryColor.withOpacity(0.1)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    NumberFormat.currency(symbol: '\$').format(bid.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isCurrentUser ? Colors.white : kPrimaryColor,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
    );
  }

  // 🎯 Modern Comment Section
  Widget _buildCommentSection() {
    return Container(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kSecondaryColor, kPrimaryColor]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.comment_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'پرسیار و وەڵامەکان',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (_auction!.comments.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_auction!.comments.length}',
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Comment Input
            if (_token != null) _buildModernCommentInput(),
            
            const SizedBox(height: 20),
            
            // Comments List
            if (_auction!.comments.isEmpty)
              _buildEmptyCommentsState()
            else
              Column(
                children: _auction!.comments
                    .map((comment) => _buildModernCommentItem(comment))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCommentInput() {
    final isReplying = _replyToCommentId != null;
    
    return Container(
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isReplying)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, color: kPrimaryColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'وەڵامدانەوە...',
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _replyToCommentId = null;
                      _commentFocusNode.unfocus();
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: kTextSecondary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: kTextSecondary, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                  backgroundImage: _currentUser?.profilePhotoUrl != null
                      ? NetworkImage(_currentUser!.profilePhotoUrl!)
                      : null,
                  child: _currentUser?.profilePhotoUrl == null
                      ? Text(
                          _currentUser?.name[0].toUpperCase() ?? '?',
                          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: isReplying ? 'وەڵامەکەت بنووسە...' : 'پرسیارێکت بنووسە...',
                      hintStyle: TextStyle(color: kTextSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: TextStyle(color: kTextPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kPrimaryColor, kSecondaryColor]),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _postComment,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCommentsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kTextSecondary.withOpacity(0.1), kTextSecondary.withOpacity(0.05)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.question_answer_outlined, size: 36, color: kTextSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            'هێشتا هیچ پرسیارێک نەکراوە',
            style: TextStyle(
              fontSize: 16,
              color: kTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'یەکەم کەس ببە کە پرسیارێک دەکات!',
            style: TextStyle(
              fontSize: 14,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCommentItem(Comment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kSurfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kPrimaryColor.withOpacity(0.1),
                  backgroundImage: comment.user.profilePhotoUrl != null
                      ? NetworkImage(comment.user.profilePhotoUrl!)
                      : null,
                  child: comment.user.profilePhotoUrl == null
                      ? Text(
                          comment.user.name[0].toUpperCase(),
                          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w600),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(comment.createdAt),
                        style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _replyToCommentId = comment.id;
                      _commentFocusNode.requestFocus();
                    }),
                    icon: Icon(Icons.reply, color: kPrimaryColor, size: 16),
                    label: Text(
                      'وەڵام',
                      style: TextStyle(color: kPrimaryColor, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Text(
                comment.body,
                style: TextStyle(
                  color: kTextPrimary,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ),
            if (comment.replies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 16),
                child: Column(
                  children: comment.replies
                      .map((reply) => _buildModernCommentItem(reply))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🎯 Modern Bottom Bid Area
  Widget _buildBottomBidArea() {
    final isOwner = _auction?.user?.id == _currentUser?.id;
    
    if (!_isAuctionActive) {
      return Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: kTextPrimary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kDangerColor.withOpacity(0.1), kDangerColor.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kDangerColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_off, color: kDangerColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'ئەم مەزادە کۆتایی هاتووە',
                style: TextStyle(
                  color: kDangerColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isOwner) {
      return Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: kTextPrimary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryColor.withOpacity(0.1), kSecondaryColor.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront, color: kPrimaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'تۆ خاوەنی ئەم مەزادەیت',
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_token == null) {
      return Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: kTextPrimary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _navigateToLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text(
            'بچۆ ژوورەوە بۆ زیادکردنی نرخ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return _buildModernBidInput();
  }

  Widget _buildModernBidInput() {
    final highestBidder = _auction?.bids.isNotEmpty == true ? _auction!.bids.first.user : null;
    final isCurrentUserHighest = highestBidder?.id == _currentUser?.id;
    final double bidIncrement = _auction!.bidIncrement;
    final double currentPrice = _auction!.currentPrice;
    final double minAllowedBid = currentPrice + bidIncrement;

    if (_bidController.text.isEmpty) {
      _bidController.text = minAllowedBid.toStringAsFixed(2);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: kTextPrimary.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current User Status
                if (isCurrentUserHighest)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [kSuccessColor, kAccentColor]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'تۆ براوەی ئێستایت!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Bid Input Row
                Row(
                  children: [
                    // Bid Amount Controller
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCurrentUserHighest 
                                ? [kBorderColor.withOpacity(0.3), kBorderColor.withOpacity(0.1)]
                                : [kPrimaryColor.withOpacity(0.1), kSecondaryColor.withOpacity(0.05)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCurrentUserHighest 
                                ? kBorderColor 
                                : kPrimaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Decrease Button
                            Container(
                              decoration: BoxDecoration(
                                color: isCurrentUserHighest 
                                    ? kTextSecondary.withOpacity(0.1) 
                                    : kPrimaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.remove,
                                  color: isCurrentUserHighest ? kTextSecondary : kPrimaryColor,
                                  size: 20,
                                ),
                                onPressed: isCurrentUserHighest ? null : () {
                                  final currentBid = double.tryParse(_bidController.text) ?? 0.0;
                                  if ((currentBid - bidIncrement) >= minAllowedBid) {
                                    setState(() => _bidController.text = 
                                        (currentBid - bidIncrement).toStringAsFixed(2));
                                  }
                                },
                              ),
                            ),

                            // Price Display
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'نرخەکەت',
                                      style: TextStyle(
                                        color: isCurrentUserHighest ? kTextSecondary : kTextPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      NumberFormat.currency(symbol: '\$').format(
                                          double.tryParse(_bidController.text) ?? 0.0),
                                      style: TextStyle(
                                        color: isCurrentUserHighest ? kTextSecondary : kPrimaryColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Increase Button
                            Container(
                              decoration: BoxDecoration(
                                color: isCurrentUserHighest 
                                    ? kTextSecondary.withOpacity(0.1) 
                                    : kPrimaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.add,
                                  color: isCurrentUserHighest ? kTextSecondary : kPrimaryColor,
                                  size: 20,
                                ),
                                onPressed: isCurrentUserHighest ? null : () {
                                  final currentBid = double.tryParse(_bidController.text) ?? 0.0;
                                  setState(() => _bidController.text = 
                                      (currentBid + bidIncrement).toStringAsFixed(2));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Bid Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: isCurrentUserHighest || _isPlacingBid
                            ? LinearGradient(colors: [kBorderColor, kBorderColor])
                            : LinearGradient(colors: [kAccentColor, kSuccessColor]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (!isCurrentUserHighest && !_isPlacingBid)
                            BoxShadow(
                              color: kAccentColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isCurrentUserHighest || _isPlacingBid ? null : () {
                            HapticFeedback.mediumImpact();
                            _placeBid();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            child: _isPlacingBid
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.gavel,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'بید',
                                        style: TextStyle(
                                          color: Colors.white,
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎯 Enhanced Loading Shimmer with Modern Design
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: kModernBorder.withOpacity(0.3),
      highlightColor: Colors.white,
      period: const Duration(milliseconds: 1200),
      child: CustomScrollView(
        slivers: [
          // Image Gallery Shimmer
          SliverToBoxAdapter(
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kModernBorder.withOpacity(0.2), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) => Container(
                        width: index == 0 ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content Shimmer
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main card shimmer
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: kModernTextPrimary.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title shimmer
                        Container(
                          height: 28,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Category shimmer
                        Container(
                          height: 20,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Description shimmer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kModernSurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 16,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 16,
                                width: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Vendor card shimmer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kModernPrimary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 18,
                                      width: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 14,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Price card shimmer
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: kModernAccent.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 14,
                                        width: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 32,
                                        width: 120,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    height: 40,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Timer shimmer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(4, (index) => Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                )),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bid history shimmer
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: kModernTextPrimary.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: kModernPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 18,
                                width: 140,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 14,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: kModernSurface,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Comments shimmer
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: kModernTextPrimary.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: kModernSecondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              height: 18,
                              width: 160,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 60,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: kModernSurface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kModernError.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    kModernError.withOpacity(0.1), 
                    kModernError.withOpacity(0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: kModernError.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded, 
                size: 50, 
                color: kModernError
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'هەڵەیەک لە وەرگرتنی داتادا ڕوویدا',
              style: TextStyle(
                fontSize: 20,
                color: kModernTextPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'تکایە ئینتەرنێتەکەت بپشکنە و دووبارە هەوڵبدەرەوە',
              style: TextStyle(
                fontSize: 15,
                color: kModernTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kModernPrimary, kModernSecondary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
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
              child: ElevatedButton.icon(
                onPressed: _fetchAuctionDetails,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text(
                  'دووبارە هەوڵبدەرەوە',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'گەڕانەوە بۆ لاپەڕەکەی پێشوو',
                style: TextStyle(
                  color: kModernTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyBidHistoryState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(40),
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
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kTextSecondary.withOpacity(0.1), kTextSecondary.withOpacity(0.05)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_toggle_off, size: 40, color: kTextSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            'هێشتا هیچ نرخێک زیادنەکراوە',
            style: TextStyle(
              fontSize: 16,
              color: kTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'یەکەم کەس ببە کە نرخ زیاد دەکات!',
            style: TextStyle(
              fontSize: 14,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidHistoryItem(bid, int index) {
    final isCurrentUser = bid.user?.id == _currentUser?.id;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? kSuccessColor.withOpacity(0.3) : kBorderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: isCurrentUser 
                ? kSuccessColor.withOpacity(0.1) 
                : kTextPrimary.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrentUser ? kSuccessColor : kPrimaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: isCurrentUser 
                    ? kSuccessColor.withOpacity(0.1) 
                    : kSurfaceColor,
                backgroundImage: bid.user?.profilePhotoUrl != null
                    ? NetworkImage(bid.user!.profilePhotoUrl!)
                    : null,
                child: bid.user?.profilePhotoUrl == null
                    ? Text(
                        bid.user?.name[0].toUpperCase() ?? '?',
                        style: TextStyle(
                          color: isCurrentUser ? kSuccessColor : kTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bid.user?.name ?? 'بەکارهێنەری سڕاوە',
                          style: TextStyle(
                            fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w600,
                            color: isCurrentUser ? kSuccessColor : kTextPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kSuccessColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'تۆ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (index == 0 && _auction!.bids.length > 1)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [kAccentColor, kSuccessColor]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emoji_events, color: Colors.white, size: 12),
                              const SizedBox(width: 4),
                              const Text(
                                'بەرز',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d, h:mm a').format(bid.createdAt),
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCurrentUser 
                      ? [kSuccessColor, kAccentColor]
                      : [kPrimaryColor.withOpacity(0.1), kSecondaryColor.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                NumberFormat.currency(symbol: '\$').format(bid.amount),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isCurrentUser ? Colors.white : kPrimaryColor,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullscreenImages() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                '${_currentImageIndex + 1} / ${_auction!.images.length}',
                style: const TextStyle(color: Colors.white),
              ),
              centerTitle: true,
            ),
            body: PageView.builder(
              controller: PageController(initialPage: _currentImageIndex),
              itemCount: _auction!.images.length,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: _auction!.images[index].url,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error, color: Colors.white, size: 64),
                    ),
                  ),
                );
              },
            ),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}