import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kurdpoint/models/conversation_model.dart';
import 'package:kurdpoint/providers/auth_provider.dart';
import 'package:kurdpoint/screens/chat_screen.dart';
import 'package:kurdpoint/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin {
  late Future<List<Conversation>?> _conversationsFuture;
  late AnimationController _animationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Conversation> _allConversations = [];
  List<Conversation> _filteredConversations = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _conversationsFuture = ApiService().getConversations(token!);
    _searchController.addListener(_onSearchChanged);
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
  
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = _allConversations;
      } else {
        _filteredConversations = _allConversations
            .where((conv) => conv.otherUser.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }
  
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredConversations = _allConversations;
      }
    });
    
    if (_isSearching) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
    }
    
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
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
          child: _buildChatList(),
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
                toolbarHeight: 56,
                title: _isSearching 
                    ? _buildSearchField()
                    : Text(
                        "Messages",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 24,
                          letterSpacing: -0.5,
                        ),
                      ),
                centerTitle: !_isSearching,
                actions: [
                  _buildSearchButton(),
                  const SizedBox(width: 8),
                  _buildNewChatButton(),
                  const SizedBox(width: 16),
                ],
              ),
              if (!_isSearching) _buildChatStats(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSearchField() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(_searchAnimationController),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: "Search conversations...",
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withOpacity(0.8),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: _toggleSearch,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _isSearching ? Icons.close : Icons.search,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
  
  Widget _buildNewChatButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Navigate to new chat screen
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.edit_outlined,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
  
  Widget _buildChatStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem("Active", "12", Icons.circle, kModernGreen),
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStatItem("Unread", "3", Icons.mark_unread_chat_alt, kModernOrange),
          Container(
            width: 1,
            height: 20,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStatItem("Total", "24", Icons.chat_bubble_outline, Colors.white),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildChatList() {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: FutureBuilder<List<Conversation>?>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          _allConversations = snapshot.data!;
          if (_filteredConversations.isEmpty && _searchController.text.isEmpty) {
            _filteredConversations = _allConversations;
          }
          
          final conversations = _filteredConversations;
          
          if (conversations.isEmpty && _searchController.text.isNotEmpty) {
            return _buildNoSearchResults();
          }
          
          return _buildConversationsList(conversations);
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
            "Loading conversations...",
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
              Icons.chat_bubble_outline_rounded,
              size: 60,
              color: kModernTextLight,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No conversations yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kModernTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start a conversation to see it here",
            style: TextStyle(
              fontSize: 14,
              color: kModernTextSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildStartChatButton(),
        ],
      ),
    );
  }
  
  Widget _buildNoSearchResults() {
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
                  kModernOrange.withOpacity(0.1),
                  kModernPink.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 50,
              color: kModernTextLight,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No results found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kModernTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try searching with different keywords",
            style: TextStyle(
              fontSize: 14,
              color: kModernTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStartChatButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Navigate to contact selection or new chat
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kModernPrimary, kModernAccent],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: kModernPrimary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_comment_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "Start New Chat",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConversationsList(List<Conversation> conversations) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: conversations.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final convo = conversations[index];
        return _buildModernConversationTile(convo, index);
      },
    );
  }
  
  Widget _buildModernConversationTile(Conversation convo, int index) {
    final lastMsg = convo.latestMessage?.body ?? "No messages yet";
    final lastTime = convo.latestMessage?.createdAt != null
        ? _formatTime(convo.latestMessage!.createdAt!)
        : "";
    final hasUnread = convo.unreadCount > 0;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
                conversationId: convo.id,
                otherUser: convo.otherUser,
              ),
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kModernCard,
            borderRadius: BorderRadius.circular(20),
            border: hasUnread 
                ? Border.all(
                    color: kModernPrimary.withOpacity(0.2),
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: hasUnread 
                    ? kModernPrimary.withOpacity(0.15)
                    : Colors.black.withOpacity(0.08),
                blurRadius: hasUnread ? 20 : 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildModernAvatar(convo),
              const SizedBox(width: 16),
              Expanded(
                child: _buildConversationContent(convo, lastMsg, lastTime, hasUnread),
              ),
              if (hasUnread) _buildUnreadBadge(convo.unreadCount),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildModernAvatar(Conversation convo) {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kModernPrimary.withOpacity(0.1),
                kModernAccent.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: kModernBorder,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: convo.otherUser.profilePhotoUrl != null
                ? Image.network(
                    convo.otherUser.profilePhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildAvatarFallback(convo.otherUser.name);
                    },
                  )
                : _buildAvatarFallback(convo.otherUser.name),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kModernGreen, kModernAccent],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAvatarFallback(String name) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kModernPrimary, kModernAccent],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
  
  Widget _buildConversationContent(Conversation convo, String lastMsg, String lastTime, bool hasUnread) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                convo.otherUser.name,
                style: TextStyle(
                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 16,
                  color: kModernTextPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              lastTime,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: hasUnread ? kModernPrimary : kModernTextLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          lastMsg,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: hasUnread ? kModernTextSecondary : kModernTextLight,
            fontSize: 14,
            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
  
  Widget _buildUnreadBadge(int count) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kModernPrimary, kModernAccent],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kModernPrimary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(messageDate).inDays < 7) {
      return DateFormat('EEE').format(dateTime);
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }
}