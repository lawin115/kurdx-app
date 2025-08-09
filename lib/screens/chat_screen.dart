// lib/screens/chat_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';

import '../models/message_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../auction_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final User otherUser;
  const ChatScreen({super.key, required this.conversationId, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // --- Controllers, Services, etc. ---
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final ApiService _apiService = ApiService();

  // --- Data State ---
  List<Message> _messages = [];
  User? _currentUser;
  String? _token;
  PusherChannelsClient? _pusherClient;

  // --- UI State ---
  bool _isLoading = true;
  bool _isSending = false;
  bool _isRetryingConnection = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _pusherClient?.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  // --- Logic Methods ---

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
    } catch (e) {
      _showErrorSnackbar('Failed to load messages');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== کۆدی چاککراوی _initPusher =====
  Future<void> _initPusher() async {
    if (_isRetryingConnection || _token == null) return;
    _isRetryingConnection = true;

    try {
      const String laravelHost = "ubuntu.tail73d562.ts.net"; // IPی دروست دابنێ
      const String reverbPort = "8080";
      const String appKey = "qmkcqfx960e6h7q00qdp";
      final String channelName = 'private-chat.${widget.conversationId}';

      final hostOptions = PusherChannelsOptions.fromHost(
        scheme: 'wss', host: laravelHost, port: int.parse(reverbPort), key: appKey
      );

      // 1. دروستکردنی Client بەبێ authorizationDelegate
      _pusherClient = PusherChannelsClient.websocket(
        options: hostOptions,
        connectionErrorHandler: (_, __, refresh) => refresh(),
      );
      
      // 2. دروستکردنی Private Channel لەگەڵ authorizationDelegate
      final channel = _pusherClient!.privateChannel(
        channelName,
        // authorizationDelegate لێرە دادەنرێت
        authorizationDelegate: EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
          authorizationEndpoint: Uri.parse('http://$laravelHost:8000/api/broadcasting/auth'),
          headers: {'Authorization': 'Bearer $_token', 'Accept': 'application/json'},
        ),
      );

      channel.bind('MessageSent').listen((event) {
        if (mounted && event.data != null) _handleIncomingMessage(event.data!);
      });
      
      _pusherClient!.onConnectionEstablished.listen((_) {
        print("--- [ChatPusher] Connected. Subscribing to $channelName ---");
        channel.subscribe();
      });

      await _pusherClient!.connect();
    } catch (e) {
      print("!!! Failed to init chat pusher: $e");
      _retryConnection();
    } finally {
      _isRetryingConnection = false;
    }
  }

 void _handleIncomingMessage(String data) {
  // پشکنین دەکەین بزانین ویجێتەکە هێشتا لەسەر شاشەیە
  if (!mounted) return;

  try {
    final messageData = jsonDecode(data)['message'];
    final newMessage = Message.fromJson(messageData);
    
    // پشکنین دەکەین بزانین پەیامەکە هی خۆمان نییە
    if (newMessage.user.id != _currentUser?.id) {
      
      // ===== چارەسەرەکە لێرەدایە =====
      // 1. پیشاندانی SnackBar-ی ئاگادارکردنەوە
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // دیزاینێکی جوانتر بۆ SnackBar
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating, // وا دەکات لە خوارەوە جیاواز بێت
          margin: const EdgeInsets.all(12.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              CircleAvatar(
                backgroundImage: newMessage.user.profilePhotoUrl != null
                    ? NetworkImage(newMessage.user.profilePhotoUrl!)
                    : null,
                child: newMessage.user.profilePhotoUrl == null
                    ? Text(newMessage.user.name[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      newMessage.user.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      newMessage.body ?? '...',
                      style: TextStyle(color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      
      // 2. زیادکردنی پەیامەکە بۆ لیستەکە
      setState(() {
        _messages.insert(0, newMessage);
      });
      
      // 3. Scroll کردن بۆ خوارەوە
      _scrollToBottom();
    }
  } catch (e) {
    debugPrint("Error parsing incoming message: $e");
  }
}

  void _retryConnection() {
    Future.delayed(const Duration(seconds: 5), () { if (mounted) _initPusher(); });
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _token == null || _isSending) return;
    setState(() => _isSending = true);
    _messageController.clear();

    final tempMessage = Message(id: -1, body: message, user: _currentUser!, createdAt: DateTime.now(), type: 'text');
    setState(() => _messages.insert(0, tempMessage));
    _scrollToBottom();

    try {
      final sentMessage = await _apiService.sendMessage(widget.conversationId, message, _token!);
      if (mounted) {
        if (sentMessage == null) _handleSendFailure(message);
        else _updateMessage(sentMessage);
      }
    } catch (e) {
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  void _navigateToAuction(int auctionId) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AuctionDetailScreen(auctionId: auctionId)));
  }

  // --- Build Method and UI Helpers ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: _buildAppBar(theme),
        body: Column(
          children: [
            Expanded(child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildMessageList(theme)),
            _buildMessageInput(theme),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
      final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AppBar(
      
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: widget.otherUser.profilePhotoUrl != null ? NetworkImage(widget.otherUser.profilePhotoUrl!) : null,
            child: widget.otherUser.profilePhotoUrl == null ? Text(widget.otherUser.name[0].toUpperCase()) : null,
          ),
          const SizedBox(width: 12),
          Text(widget.otherUser.name),
        ],
      ),
    );
  }

  Widget _buildMessageList(ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (ctx, index) {
        final message = _messages[index];
        final isMe = message.user.id == _currentUser?.id;
        final showAvatar = index == _messages.length - 1 || _messages[index + 1].user.id != message.user.id;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: [
              if (index < _messages.length - 1 && _daysBetween(_messages[index + 1].createdAt, message.createdAt) > 0)
                _buildDateSeparator(_messages[index + 1].createdAt, theme),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (!isMe && showAvatar)
                    Padding(padding: const EdgeInsets.only(right: 8), child: CircleAvatar(radius: 14))
                  else if (!isMe)
                    const SizedBox(width: 36),
                  message.type == 'auction_share' && message.auction != null
                    ? _buildAuctionMessage(message, isMe, theme)
                    : _buildTextMessage(message, isMe, theme, showAvatar),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  int _daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  Widget _buildDateSeparator(DateTime date, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(12)),
        child: Text(DateFormat('MMMM d, y').format(date), style: theme.textTheme.labelSmall),
      ),
    );
  }
  
  Widget _buildTextMessage(Message message, bool isMe, ThemeData theme, bool showAvatar) {
    final colors = theme.colorScheme;
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? colors.primary : colors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.body ?? '', style: TextStyle(color: isMe ? colors.onPrimary : colors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('h:mm a').format(message.createdAt), style: theme.textTheme.labelSmall?.copyWith(color: (isMe ? colors.onPrimary : colors.onSurfaceVariant).withOpacity(0.6))),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(message.id == -1 ? Icons.access_time : Icons.done_all, size: 14, color: (isMe ? colors.onPrimary : colors.onSurfaceVariant).withOpacity(0.6)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionMessage(Message message, bool isMe, ThemeData theme) {
    final auction = message.auction!;
    return InkWell(
      onTap: () => _navigateToAuction(auction.id),
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: auction.images.isNotEmpty ? auction.images.first.url : 'https://via.placeholder.com/150',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auction.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(NumberFormat.simpleCurrency().format(auction.currentPrice)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessageInput(ThemeData theme) {
    return Material(
      elevation: 5,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  decoration: const InputDecoration(hintText: 'Type a message...', border: InputBorder.none),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: theme.primaryColor),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}