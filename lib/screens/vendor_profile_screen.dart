import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

import '../models/user_model.dart';
import '../models/auction_model.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/auction_list_card.dart';
import './edit_profile_screen.dart';
import './chat_screen.dart';
import './login_screen.dart';

class VendorProfileScreen extends StatefulWidget {
  final int vendorId;
  const VendorProfileScreen({super.key, required this.vendorId});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final ApiService _apiService = ApiService();
  User? _vendor;
  List<Auction> _auctions = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  int _followersCount = 0;
  User? _currentUser;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _currentUser = Provider.of<AuthProvider>(context, listen: false).user;
    _fetchVendorProfile();
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
print('Vendor profile response: $data');
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _toggleFollow() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (c) => const LoginScreen()));
      return;
    }


 

    final response = await _apiService.toggleFollow(widget.vendorId, auth.token!);


    if (mounted && response != null) {
      // دوای وەرگرتنی وەڵامی دروست لە سێرڤەر، UIـەکە نوێ بکەرەوە
      setState(() {
        _isFollowing = response['is_following'];
        // ژمارەی فۆڵۆوەرەکانیش دەتوانین نوێ بکەینەوە ئەگər API گەڕاندیەوە
        _stats?['followers_count'] += _isFollowing ? 1 : -1;
      });
    } else if (mounted) {
      // گەڕاندنەوە لە کاتی هەڵەدا
 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('هەڵەیەک ڕوویدا!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
      );
    }
  }

  Future<void> _startChat() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (c) => const LoginScreen()));
      return;
    }
    
    if (_vendor == null) return;
    
    showDialog(
      context: context, 
      barrierColor: Colors.black54,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator.adaptive(
          backgroundColor: Colors.white,
        ),
      )
    );
    
    final conversationId = await _apiService.startOrGetConversation(_vendor!.id, auth.token!);
    if (mounted) Navigator.of(context).pop();

    if (conversationId != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ChatScreen(conversationId: conversationId, otherUser: _vendor!),
        )
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('هەڵەیەک لە دەستپێکردنی چاتدا ڕوویدا'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
               ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator.adaptive(),
            )
          : _vendor == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'پێشانگاکە نەدۆزرایەوە',
                        style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.error),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "دەربارەی پێشانگا",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                               "بیرۆکەیەک نییە",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                            ),
                                 ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          "مەزادە چالاکەکان",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    _buildAuctionsList(),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
    );
  }
  
  Widget _buildSliverAppBar() {
    final bool isMyOwnProfile = _currentUser?.id == _vendor?.id;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      backgroundColor: colorScheme.surface,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        centerTitle: true,
        title: ElasticIn(
          child: Text(
            _vendor!.name,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: colorScheme.surface.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if(_vendor!.profilePhotoUrl != null)
              CachedNetworkImage(
                imageUrl: _vendor!.profilePhotoUrl!,
                fit: BoxFit.cover,
                colorBlendMode: BlendMode.darken,
                color: Colors.black.withOpacity(0.3),
               ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BounceInDown(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: colorScheme.surface,
                          backgroundImage: _vendor!.profilePhotoUrl != null
                              ? NetworkImage(_vendor!.profilePhotoUrl!)
                              : null,
                          child: _vendor!.profilePhotoUrl == null
                              ? Icon(Icons.store, size: 40, color: colorScheme.primary)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeIn(
                      child: Text(
                        _vendor!.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (_vendor!.location != null)
                      FadeIn(
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          _vendor!.location!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildStatColumn('فۆڵۆوەر', (_stats?['followers_count'] ?? 0).toString()),
              const VerticalDivider(indent: 8, endIndent: 8),
              _buildStatColumn('فرۆشراو', (_stats?['auctions_sold'] ?? 0).toString()),
              const VerticalDivider(indent: 8, endIndent: 8),
              _buildStatColumn('ڕێژەی سەرکەوتن', '${_stats?['success_rate'] ?? 0}%'),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    if (isMyOwnProfile)
                      FilledButton.icon(
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('گۆڕینی پرۆفایل'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.onPrimaryContainer,
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (c) => const EditProfileScreen()),
                          ),
                        )
                    else ...[
                      FilledButton.icon(
                        icon: Icon(
                          _isFollowing ? Icons.check : Icons.person_add_alt_1,
                          size: 18,
                        ),
                        label: Text(_isFollowing ? 'فۆڵۆو کراوە' : 'فۆڵۆو بکە'),
                        onPressed: _toggleFollow,
                        style: FilledButton.styleFrom(
                          backgroundColor: _isFollowing
                              ? Colors.grey.withOpacity(0.2)
                              : colorScheme.primary,
                          foregroundColor: _isFollowing
                              ? colorScheme.onSurface.withOpacity(0.8)
                              : colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.message, size: 18),
                        label: const Text('نامە بنێرە'),
                        onPressed: _startChat,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    final theme = Theme.of(context);
    
    return Expanded(
      flex: 1,
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionsList() {
    final theme = Theme.of(context);
    
    if (_auctions.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                "ئەم پێشانگایە هیچ مەزادێکی چالاکی نییە",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
                ),
              ),
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