import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';

import '../models/message_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../auction_detail_screen.dart';

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

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final User otherUser;
  const ChatScreen({super.key, required this.conversationId, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final ApiService _apiService = ApiService();

  List<Message> _messages = [];
  User? _currentUser;
  String? _token;
  PusherChannelsClient? _pusherClient;

  bool _isLoading = true;
  bool _isSending = false;
  bool _isRetryingConnection = false;
  bool _showEmojiPicker = false;
  
  late AnimationController _animationController;
  late AnimationController _messageAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeChat();
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
    _messageAnimationController.dispose();
    _pusherClient?.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _currentUser = auth.user;
    _token = auth.token;
    await _fetchMessages();
    _initPusher();
  }

  Future<void> _fetchMessages() async {
    if (_token == null) return;
    try {
      final messages = await _apiService.getMessages(widget.conversationId, _token!);
      if (mounted && messages != null) setState(() => _messages = messages);
    } catch (_) {
      _showErrorSnackbar('Failed to load messages');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _initPusher() async {
    if (_isRetryingConnection || _token == null) return;
    _isRetryingConnection = true;

    try {
      const String domainHost = "10.0.2.2:8000"; // Use 10.0.2.2 for Android emulator to access localhost
      const String appKey = "qmkcqfx960e6h7q00qdp";
      final String channelName = 'private-chat.${widget.conversationId}';

      final hostOptions = PusherChannelsOptions.fromHost(
        scheme: 'ws', // Use ws instead of wss for local development
        host: domainHost,
        key: appKey,
      );

      _pusherClient = PusherChannelsClient.websocket(
        options: hostOptions,
        connectionErrorHandler: (_, __, refresh) => refresh(),
      );

      final channel = _pusherClient!.privateChannel(
        channelName,
        authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
          authorizationEndpoint: Uri.parse('http://$domainHost/api/broadcasting/auth'), // Use http instead of https
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json',
          },
        ),
      );

      channel.bind('MessageSent').listen((event) {
        if (mounted && event.data != null) _handleIncomingMessage(event.data!);
      });

      _pusherClient!.onConnectionEstablished.listen((_) {
        channel.subscribe();
      });

      await _pusherClient!.connect();
    } catch (e) {
      _retryConnection();
    } finally {
      _isRetryingConnection = false;
    }
  }

  void _handleIncomingMessage(String data) {
    if (!mounted) return;
    try {
      final messageData = jsonDecode(data)['message'];
      final newMessage = Message.fromJson(messageData);
      if (newMessage.user.id != _currentUser?.id) {
        setState(() {
          _messages.insert(0, newMessage);
        });
        _scrollToBottom();
      }
    } catch (_) {}
  }

  void _retryConnection() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _initPusher();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _token == null || _isSending) return;
    setState(() => _isSending = true);
    _messageController.clear();

    final tempMessage = Message(
      id: -1,
      body: message,
      user: _currentUser!,
      createdAt: DateTime.now(),
      type: 'text',
    );
    setState(() => _messages.insert(0, tempMessage));
    _scrollToBottom();

    try {
      final sentMessage = await _apiService.sendMessage(widget.conversationId, message, _token!);
      if (mounted) {
        if (sentMessage == null) _handleSendFailure(message);
        else _updateMessage(sentMessage);
      }
    } catch (_) {
      _handleSendFailure(message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _handleSendFailure(String originalMessage) {
    setState(() {
      _messages.removeWhere((m) => m.id == -1);
      _messageController.text = originalMessage;
    });
    _showErrorSnackbar('Failed to send message');
  }

  void _updateMessage(Message sentMessage) {
    final index = _messages.indexWhere((m) => m.id == -1);
    if (index != -1) setState(() => _messages[index] = sentMessage);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _navigateToAuction(int auctionId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AuctionDetailScreen(auctionId: auctionId)),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kModernSurface,
        extendBodyBehindAppBar: true,
        appBar: _buildModernAppBar(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _buildMessageList(),
                ),
                _buildModernMessageInput(),
              ],
            ),
          ),
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
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                automaticallyImplyLeading: true,
                iconTheme: const IconThemeData(color: Colors.white),
                toolbarHeight: 56,
                title: _buildModernUserInfo(),
                centerTitle: false,
                actions: [
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
                      icon: Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // TODO: Implement video call
                      },
                    ),
                  ),
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
                      icon: Icon(Icons.call_rounded, color: Colors.white, size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // TODO: Implement voice call
                      },
                    ),
                  ),
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
                      icon: Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        // TODO: Show options menu
                      },
                    ),
                  ),
                ],
              ),
              _buildConnectionStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernUserInfo() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: widget.otherUser.profilePhotoUrl != null
                ? CachedNetworkImageProvider(widget.otherUser.profilePhotoUrl!)
                : null,
            child: widget.otherUser.profilePhotoUrl == null
                ? Text(
                    widget.otherUser.name[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUser.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: kModernGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kModernGreen.withOpacity(0.5),
                          blurRadius: 3,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      "Active now",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_rounded,
            size: 12,
            color: Colors.white.withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              "End-to-end encrypted",
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Center(
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
              "Loading messages...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kModernTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return Container(
      margin: const EdgeInsets.only(top: 120),
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _messages.length,
        itemBuilder: (ctx, index) {
          final message = _messages[index];
          final isMe = message.user.id == _currentUser?.id;
          final showAvatar = index == 0 || 
              _messages[index - 1].user.id != message.user.id;
          
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 50)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                if (index < _messages.length - 1 &&
                    _daysBetween(_messages[index + 1].createdAt, message.createdAt) > 0)
                  _buildModernDateSeparator(message.createdAt),
                message.type == 'auction_share' && message.auction != null
                    ? _buildModernAuctionMessage(message, isMe)
                    : _buildModernTextMessage(message, isMe, showAvatar),
              ],
            ),
          );
        },
      ),
    );
  }

  int _daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  Widget _buildModernDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    kModernBorder,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: kModernCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: kModernBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _formatDateSeparator(date),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kModernTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    kModernBorder,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  Widget _buildModernTextMessage(Message message, bool isMe, bool showAvatar) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar) _buildMessageAvatar(),
          if (!isMe && !showAvatar) const SizedBox(width: 40),
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: isMe ? 60 : 8,
                right: isMe ? 8 : 60,
                bottom: 4,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                        colors: [kModernPrimary, kModernAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : kModernCard,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(6),
                  bottomRight: isMe ? const Radius.circular(6) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe 
                        ? kModernPrimary.withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: isMe ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.body ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : kModernTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(message.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isMe 
                              ? Colors.white.withOpacity(0.8) 
                              : kModernTextLight,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Icon(
                          message.id == -1 
                              ? Icons.schedule_rounded
                              : Icons.done_all_rounded,
                          size: 14,
                          color: message.id == -1
                              ? Colors.white.withOpacity(0.6)
                              : kModernGreen,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe && showAvatar) _buildMessageAvatar(),
          if (isMe && !showAvatar) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMessageAvatar() {
    final user = _currentUser!;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: kModernPrimary.withOpacity(0.1),
        backgroundImage: user.profilePhotoUrl != null
            ? CachedNetworkImageProvider(user.profilePhotoUrl!)
            : null,
        child: user.profilePhotoUrl == null
            ? Text(
                user.name[0].toUpperCase(),
                style: TextStyle(
                  color: kModernPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildModernAuctionMessage(Message message, bool isMe) {
    final auction = message.auction!;
    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 60 : 16,
        right: isMe ? 16 : 60,
        bottom: 8,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _navigateToAuction(auction.id);
        },
        child: Container(
          width: 280,
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
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: CachedNetworkImage(
                      imageUrl: auction.images.isNotEmpty
                          ? auction.images.first.url
                          : 'https://via.placeholder.com/280x140',
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 140,
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
                      errorWidget: (context, url, error) => Container(
                        height: 140,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              kModernPrimary.withOpacity(0.1),
                              kModernAccent.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: kModernTextLight,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            color: Colors.black.withOpacity(0.7),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.gavel_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Auction',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
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
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auction.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: kModernTextPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kModernGreen.withOpacity(0.1),
                            kModernAccent.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kModernGreen.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on_rounded,
                            color: kModernGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            NumberFormat.simpleCurrency().format(auction.currentPrice),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: kModernGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [kModernPrimary, kModernAccent],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'View Auction',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
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
    );
  }

  Widget _buildModernMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: kModernCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              _buildInputActionButton(
                Icons.add_rounded,
                () {
                  HapticFeedback.lightImpact();
                  _showAttachmentOptions();
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: kModernSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: kModernBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          focusNode: _messageFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: kModernTextLight,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          style: TextStyle(
                            color: kModernTextPrimary,
                            fontSize: 15,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 5,
                          minLines: 1,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      _buildInputActionButton(
                        Icons.emoji_emotions_outlined,
                        () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildSendButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputActionButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: kModernSurface,
        shape: BoxShape.circle,
        border: Border.all(
          color: kModernBorder,
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: kModernTextSecondary,
          size: 20,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSendButton() {
    final hasText = _messageController.text.trim().isNotEmpty;
    
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0.0, end: hasText ? 1.0 : 0.7),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasText
                      ? [kModernPrimary, kModernAccent]
                      : [kModernTextLight, kModernTextLight],
                ),
                shape: BoxShape.circle,
                boxShadow: hasText ? [
                  BoxShadow(
                    color: kModernPrimary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: _isSending
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        );
      },
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: kModernCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kModernBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Share Content',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kModernTextPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(
                      Icons.camera_alt_rounded,
                      'Camera',
                      kModernPrimary,
                      () {},
                    ),
                    _buildAttachmentOption(
                      Icons.photo_library_rounded,
                      'Gallery',
                      kModernAccent,
                      () {},
                    ),
                    _buildAttachmentOption(
                      Icons.gavel_rounded,
                      'Auction',
                      kModernOrange,
                      () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kModernTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
