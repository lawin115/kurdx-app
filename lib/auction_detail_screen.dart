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
import 'package:flutter/material.dart';
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



class AuctionDetailScreen extends StatefulWidget {
  final int auctionId;
  const AuctionDetailScreen({super.key, required this.auctionId});

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  // --- Controllers, Services, etc. ---
  final ApiService _apiService = ApiService();
  final CarouselController _carouselController = CarouselController();
  final TextEditingController _bidController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  late final FocusNode _commentFocusNode;

  // --- Data State ---
  Auction? _auction;
  String? _token;
  User? _currentUser;
  PusherChannelsClient? _pusherClient;

  // --- UI State ---
  bool _isLoading = true;
  bool _isPlacingBid = false;
  bool _isAuctionActive = true;
  int _currentImageIndex = 0;
  int? _replyToCommentId;
  bool _isRetryingConnection = false;
  bool _hasAgreedToVendorTerms = false;
  GlobalKey _priceKey = GlobalKey();
   bool _showBidHistory = false;
  @override
  void initState() {
    super.initState();
    _commentFocusNode = FocusNode();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _token = auth.token;
    _currentUser = auth.user;
    _fetchAuctionDetails();
    _initPusher();
  }

  @override
  void dispose() {
    _pusherClient?.disconnect();
    _bidController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  // --- Logic Methods ---

  Future<void> _fetchAuctionDetails({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoading = true);
    final fetchedAuction = await _apiService.getAuctionDetails(widget.auctionId, _token);
    if (mounted) {
      setState(() {
        _auction = fetchedAuction;
        _isLoading = false;
        if (_auction != null) {
          _isAuctionActive = DateTime.now().isBefore(_auction!.endTime);
        }
      });
    }
  }
  
  Future<void> _initPusher() async {
    if (_isRetryingConnection) return;
    _isRetryingConnection = true;
    try {
      const String laravelHost = "ubuntu.tail73d562.ts.net"; // <-- IPی خۆت دابنێ
      const String reverbPort = "8080";
      const String appKey = "qmkcqfx960e6h7q00qdp"; // REVERB_APP_KEY
      final String channelName = 'auction.${widget.auctionId}';

      final hostOptions = PusherChannelsOptions.fromHost(scheme: 'wss', host: laravelHost, port: int.parse(reverbPort), key: appKey);
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
              _priceKey = GlobalKey(); // Assign a new key to force Animate widget to rebuild
            });
          } catch (e) { print("Error parsing BidPlaced: $e"); _fetchAuctionDetails(showLoading: false); }
        }
      });
      
      channel.bind('AuctionTimeExtended').listen((event) {
         if (mounted && event.data != null && _auction != null) {
           try {
             final eventData = jsonDecode(event.data!);
             setState(() => _auction = _auction!.copyWith(endTime: DateTime.parse(eventData['newEndTime']['date'])));
           } catch (e) { print("Error parsing TimeExtended: $e"); }
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
    // ئەگەر مەرجی هەبوو و بەکارهێنەر ڕازی نەبووبوو, دیالۆگەکە پیشان بدە
    final didAgree = await _showVendorTermsDialog(vendorTerms);
    if (didAgree == true) {
      setState(() => _hasAgreedToVendorTerms = true);
    } else {
      return; // ئەگەر ڕازی نەبوو, هیچ مەکە
    }
  }
     final highestBidder = _auction?.bids.isNotEmpty == true ? _auction!.bids.first.user : null;
     if (highestBidder?.id == _currentUser?.id) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تۆ پێشتر بەرزترین نرخت داناوە!'), backgroundColor: Colors.orange));
       return;
     }
     setState(() => _isPlacingBid = true);
     final success = await _apiService.placeBid(widget.auctionId, _bidController.text, _token!);
     if (mounted) {
       if (success) {
         _bidController.clear();
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نرخەکەت بە سەرکەوتوویی زیادکرا!'), backgroundColor: Colors.green));
       } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەڵەیەک ڕوویدا، نرخەکەت بەرزتر بکە.'), backgroundColor: Colors.red));
       }
       setState(() => _isPlacingBid = false);
     }
  }
Future<bool?> _showVendorTermsDialog(String terms) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('مەرجەکانی فرۆشیار'),
      content: SingleChildScrollView(child: Text(terms)),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ڕەتکردنەوە')),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('ڕازیم')),
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
    final newComment = await _apiService.postComment(widget.auctionId, tempBody, _replyToCommentId, _token!);
    if (mounted) {
      if (newComment != null) {
        _fetchAuctionDetails(showLoading: false);
        setState(() => _replyToCommentId = null);
      } else {
        setState(() => _commentController.text = tempBody);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ناردنی کۆمێنت سەرکەوتوو نەبوو'), backgroundColor: Colors.red));
      }
    }
  }
  
  void _toggleWatchlist() {
    Provider.of<AuthProvider>(context, listen: false).toggleWatchlist(_auction!.id);
  }


 Future<void> _shareAuction() async {
    // پشکنین دەکەین بزانین بەکارهێنەر لۆگین بووە
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('بۆ هاوبەشیکردن، تکایە بچۆ ژوورەوە.')),
      );
      return;
    }

    // نیشاندانی loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    // 1. وەرگرتنی لیستی گفتوگۆکان
    final conversations = await _apiService.getConversations(_token!);
    
    // داخستنی loading indicator
    if (mounted) Navigator.of(context).pop();

    if (mounted) {
      if (conversations == null || conversations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تۆ هێشتا هیچ گفتوگەیەکت نییە.')));
        return;
      }
      
      // 2. پیشاندانی Dialog
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => _buildShareDialog(conversations),
      );
    }
  }

  // --- UI Helper Widgets ---

  // ===== ویجێتێکی نوێ بۆ دروستکردنی Dialog =====
  Widget _buildShareDialog(List<Conversation> conversations) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          Text("هاوبەشیکردن لەگەڵ", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          // لیستی گفتوگۆکان
          Expanded(
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (ctx, index) {
                final convo = conversations[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: convo.otherUser.profilePhotoUrl != null ? NetworkImage(convo.otherUser.profilePhotoUrl!) : null,
                    child: convo.otherUser.profilePhotoUrl == null ? Text(convo.otherUser.name[0].toUpperCase()) : null,
                  ),
                  title: Text(convo.otherUser.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: convo.latestMessage != null ? Text(convo.latestMessage!.body ?? '', maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                  onTap: () async {
                    // داخستنی dialog
                    Navigator.of(context).pop();
                    
                    // ناردنی مەزادەکە
                    final sentMessage = await _apiService.shareAuctionInChat(convo.id, _auction!.id, _token!);
                    
                    if (mounted) {
                      if (sentMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('مەزاد بۆ ${convo.otherUser.name} نێردرا'), backgroundColor: Colors.green));
                        
                        // (ئارەزوومەندانە) ڕاستەوخۆ بچۆ ناو چاتەکە
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) => ChatScreen(
                            conversationId: convo.id,
                            otherUser: convo.otherUser,
                          ),
                        ));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هەڵەیەک لە ناردندا ڕوویدا'), backgroundColor: Colors.red));
                      }
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const LoginScreen()));
  }

  // --- Build Method ---
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: _auction?.images.isNotEmpty == true ? Colors.white : Colors.black),
        actions: [
          if (_auction != null) ...[
            IconButton(icon: Icon(Icons.share, color: _auction!.images.isNotEmpty ? Colors.white : Colors.black), onPressed: _shareAuction),
            Consumer<AuthProvider>(
              builder: (context, auth, child) => IconButton(
                icon: Icon(
                  auth.isInWatchlist(_auction!.id) ? Icons.favorite : Icons.favorite_border,
                  color: _auction!.images.isNotEmpty ? Colors.white : Colors.red,
                ),
                onPressed: _toggleWatchlist,
              ),
            ),
          ]
        ],
      ),
      body: _isLoading
          ? _buildLoadingShimmer()
          : _auction == null
              ? _buildErrorState()
              : Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(child: _buildImageGallery()),
                          SliverToBoxAdapter(child: _buildMainInfoSection()),
                          SliverToBoxAdapter(child: _buildBidHistoryHeader()),
                           if (_showBidHistory) _buildBidHistoryList(),
                          SliverToBoxAdapter(child: _buildCommentSection()),
                        ],
                      ),
                    ),
                    _buildBidArea(),
                  ],
                ),
    );
  }

  // --- UI Helper Widgets ---

  Widget _buildImageGallery() {
    if (_auction!.images.isEmpty) {
      return Container(height: 250, color: Colors.grey[300], child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey));
    }
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider(
        
          options: CarouselOptions(
            height: 300,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) => setState(() => _currentImageIndex = index),
          ),
          items: _auction!.images.map((image) => CachedNetworkImage(
            imageUrl: image.url,
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (context, url) => Container(color: Colors.grey[300]),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          )).toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _auction!.images.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _carouselController.animateToPage(entry.key),
              child: Container(
                width: 10.0,
                height: 10.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(_currentImageIndex == entry.key ? 0.9 : 0.4),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildMainInfoSection() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInUp(delay: const Duration(milliseconds: 100), child: Text(_auction!.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          FadeInUp(delay: const Duration(milliseconds: 200), child: Text(_auction!.description, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[700], height: 1.5))),
          FadeInUp(delay: const Duration(milliseconds: 300), child: _buildVendorInfoCard()),
          FadeInUp(delay: const Duration(milliseconds: 400), child: _buildAuctionInfoCard()),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAuctionInfoCard() {
    final theme = Theme.of(context);
    final formatCurrency = NumberFormat.simpleCurrency(locale: 'en_US', decimalDigits: 2);
    final highestBidder = _auction!.bids.isNotEmpty ? _auction!.bids.first.user : null;
    final isCurrentUserHighest = highestBidder?.id == _currentUser?.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('نرخی ئێستا', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 4),
                    Animate(
                      key: _priceKey,
                      effects: const [ShakeEffect(duration: Duration(milliseconds: 500), hz: 4), ThenEffect(), ScaleEffect(duration: Duration(milliseconds: 300), curve: Curves.easeIn)],
                      child: Text(formatCurrency.format(_auction!.currentPrice), style: theme.textTheme.headlineSmall?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (highestBidder != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: isCurrentUserHighest ? Colors.green.shade100 : Colors.amber.shade100, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Icon(isCurrentUserHighest ? Icons.star : Icons.emoji_events, color: isCurrentUserHighest ? Colors.green.shade700 : Colors.amber.shade800, size: 16),
                        const SizedBox(width: 6),
                        Text(isCurrentUserHighest ? 'تۆ براوەیت' : '${highestBidder.name}', style: TextStyle(fontWeight: FontWeight.bold, color: isCurrentUserHighest ? Colors.green.shade800 : Colors.amber.shade900)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            TimerBuilder.periodic(
              const Duration(seconds: 1),
              builder: (context) {
                final now = DateTime.now();
                if (now.isAfter(_auction!.endTime)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && _isAuctionActive) setState(() => _isAuctionActive = false); });
                  return _buildEndedBadge(theme);
                }
                final remaining = _auction!.endTime.difference(now);
                return _buildCountdownTimer(remaining, theme);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCountdownTimer(Duration remaining, ThemeData theme) {
    return Column(
      children: [
        const Text('کاتی ماوە', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTimeUnit('رۆژ', remaining.inDays, theme),
            _buildTimeUnit('کاتژمێر', remaining.inHours.remainder(24), theme),
            _buildTimeUnit('خولەک', remaining.inMinutes.remainder(60), theme),
            _buildTimeUnit('چرکە', remaining.inSeconds.remainder(60), theme),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeUnit(String label, int value, ThemeData theme) {
    return Column(
      children: [
        Text(value.toString().padLeft(2, '0'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildEndedBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_off, size: 18, color: Colors.red.shade800),
          const SizedBox(width: 8),
          Text('مەزاد کۆتایی هات', style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildVendorInfoCard() {
    final vendor = _auction!.user;
    if (vendor == null) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => VendorProfileScreen(vendorId: vendor.id))),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(radius: 25, backgroundImage: vendor.profilePhotoUrl != null ? NetworkImage(vendor.profilePhotoUrl!) : null, child: vendor.profilePhotoUrl == null ? const Icon(Icons.storefront) : null),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(vendor.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Text("فرۆشیار", style: TextStyle(color: Colors.grey[600]))])),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildBidHistoryHeader() {
  
  final theme = Theme.of(context);

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'مێژووی نرخەکان',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                if (_auction!.bids.isNotEmpty)
                  Text(
                    '${_auction!.bids.length} نرخ',
                    style: const TextStyle(color: Colors.grey),
                  ),
                IconButton(
                  icon: Icon(_showBidHistory ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _showBidHistory = !_showBidHistory;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}


 Widget _buildBidHistoryList() {
  if (_auction!.bids.isEmpty) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('هێشتا هیچ نرخێک زیادنەکراوە', style: TextStyle(fontSize: 16, color: Colors.grey)),
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

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundImage: bid.user?.profilePhotoUrl != null
                ? NetworkImage(bid.user!.profilePhotoUrl!)
                : null,
            child: bid.user?.profilePhotoUrl == null
                ? Text(bid.user?.name[0].toUpperCase() ?? '?')
                : null,
          ),
          title: Text(
            bid.user?.name ?? 'بەکارهێنەری سڕاوە',
            style: TextStyle(
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            DateFormat('MMM d, h:mm a').format(bid.createdAt),
          ),
          trailing: Text(
            NumberFormat.simpleCurrency().format(bid.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCurrentUser ? Theme.of(context).primaryColor : null,
            ),
          ),
        ),
      );
    },
    separatorBuilder: (context, index) => const SizedBox(height: 4),
  );
}


  Widget _buildCommentSection() {
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
     
          if (_token != null) _buildCommentInputField(),
          const SizedBox(height: 16),
          if (_auction!.comments.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32.0), child: Text("هێشتا هیچ پرسیارێک نەکراوە.")))
          else
            Column(children: _auction!.comments.map((comment) => _buildCommentItem(comment)).toList()),
        ],
      ),
    );
  }
  
  Widget _buildCommentItem(Comment comment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundImage: comment.user.profilePhotoUrl != null ? NetworkImage(comment.user.profilePhotoUrl!) : null, child: comment.user.profilePhotoUrl == null ? Text(comment.user.name[0].toUpperCase()) : null),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(comment.user.name, style: const TextStyle(fontWeight: FontWeight.bold)), Text(DateFormat('MMM d, yyyy').format(comment.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 12))])),
                TextButton(
                  onPressed: () => setState(() { _replyToCommentId = comment.id; _commentFocusNode.requestFocus(); }),
                  child: const Text("وەڵام"),
                ),
              ],
            ),
            Padding(padding: const EdgeInsets.only(left: 52.0, top: 8.0, bottom: 8.0), child: Text(comment.body)),
            if (comment.replies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 40.0, top: 8.0),
                child: Column(children: comment.replies.map((reply) => _buildCommentItem(reply)).toList()),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInputField() {
    final isReplying = _replyToCommentId != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isReplying)
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("وەڵامدانەوە...", style: TextStyle(color: Colors.grey[600])), IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => setState(() { _replyToCommentId = null; _commentFocusNode.unfocus(); }))]),
            Row(
              children: [
                Expanded(child: TextField(controller: _commentController, focusNode: _commentFocusNode, decoration: InputDecoration(hintText: isReplying ? "وەڵامەکەت بنووسە..." : "پرسیارێکت بنووسە...", border: InputBorder.none))),
                IconButton(icon: Icon(Icons.send, color: Theme.of(context).primaryColor), onPressed: _postComment)
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBidArea() {
    final isOwner = _auction?.user?.id == _currentUser?.id;
    if (!_isAuctionActive) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        color: Colors.grey[200],
        child: Text("ئەم مەزادە کۆتایی هاتووە.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
      );
    }
    if (isOwner) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        color: Colors.blue[50],
        child: Text("تۆ خاوەنی ئەم مەزادەیت.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800])),
      );
    }
    if (_token == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: FilledButton(onPressed: _navigateToLogin, child: const Text('بچۆ ژوورەوە بۆ زیادکردنی نرخ')),
      );
    }
    return _buildBidInputArea();
  }

// lib/screens/auction_detail_screen.dart -> _AuctionDetailScreenState

Widget _buildBidInputArea() {
  final theme = Theme.of(context);
  final highestBidder = _auction?.bids.isNotEmpty == true ? _auction!.bids.first.user : null;
  final isCurrentUserHighest = highestBidder?.id == _currentUser?.id;

  // ===== لۆجیکی نوێی کەمترین نرخ و ئامادەکاری =====

  final double minBid = _auction!.currentPrice + _auction!.bidIncrement;
  


    final double bidIncrement = _auction!.bidIncrement;
  final double currentPrice = _auction!.currentPrice;
  final double minAllowedBid = currentPrice + bidIncrement;
  // دڵنیادەبینەوە کە خانەکە بەتاڵ نییە بۆ یەکەمجار
  if (_bidController.text.isEmpty) {
    _bidController.text = minBid.toStringAsFixed(2);
  }

  return Material(
    elevation: 10,
    child: Container(
      padding: const EdgeInsets.all(16.0).copyWith(bottom: MediaQuery.of(context).padding.bottom + 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCurrentUserHighest)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.verified, size: 18, color: Colors.green), const SizedBox(width: 8), Text("تۆ براوەی ئێستایت!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
            ),
          
          Row(
            children: [
              // ===== ویجێتی نوێی Stepper (Plus/Minus) =====
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isCurrentUserHighest ? Colors.grey.shade300 : theme.primaryColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // --- دوگمەی کەمکردن (-) ---
                      IconButton(
                        icon: const Icon(Icons.remove),
                        color: theme.primaryColor,
                        onPressed: isCurrentUserHighest ? null : () {
                          final currentBid = double.tryParse(_bidController.text) ?? 0.0;
                          // مەرج: نابێت لە کەمترین نرخ کەمتر بێت
                          if ((currentBid - bidIncrement) >= minAllowedBid) {
                            setState(() => _bidController.text = (currentBid - bidIncrement).toStringAsFixed(2));
                          }
                        },
                      ),
                      
                      // --- نرخی ئێستا ---
                    Text(
                        NumberFormat.simpleCurrency().format(double.tryParse(_bidController.text) ?? 0.0),
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      
                      // --- دوگمەی زیادکردن (+) ---
                      IconButton(
                        icon: const Icon(Icons.add),
                        color: theme.primaryColor,
                        onPressed: isCurrentUserHighest ? null : () {
                          final currentBid = double.tryParse(_bidController.text) ?? 0.0;
                           setState(() => _bidController.text = (currentBid + bidIncrement).toStringAsFixed(2));
                        
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // --- دوگمەی ناردنی نرخ ---
              FilledButton.tonal(
                onPressed: isCurrentUserHighest || _isPlacingBid ? null : _placeBid,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24)
                ),
                child: _isPlacingBid 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.gavel),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: Container(height: 300, color: Colors.white)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 30, width: double.infinity, color: Colors.white, margin: const EdgeInsets.only(bottom: 12)),
                  Container(height: 60, width: double.infinity, color: Colors.white, margin: const EdgeInsets.only(bottom: 24)),
                  Container(height: 80, width: double.infinity, color: Colors.white, margin: const EdgeInsets.only(bottom: 24)),
                  Container(height: 150, width: double.infinity, color: Colors.white),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
          const SizedBox(height: 16),
          const Text('هەڵەیەک لە وەرگرتنی داتادا ڕوویدا', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          TextButton.icon(onPressed: _fetchAuctionDetails, icon: const Icon(Icons.refresh), label: const Text('دووبارە هەوڵبدەرەوە')),
        ],
      ),
    );
  }
}

extension on CarouselController {
  void animateToPage(int key) {}
}