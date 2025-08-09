import 'package:flutter/material.dart';
import 'package:kurdpoint/screens/sold_auctions_screen.dart';
import './blocked_users_screen.dart'; // <-- import بکە
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/auction_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

import './edit_profile_screen.dart';

import '../widgets/auction_list_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _stats;
  List<Auction> _activeAuctions = [];
  List<Order> _soldOrders = [];
  List<Auction> _participatedAuctions = [];
  List<Auction>? _watchedAuctions;
  bool _isLoading = true;
  
  // 1. TabController بکە nullable (دشێت null بیت)
  TabController? _tabController; 

  @override
  void initState() {
    super.initState();
    // TabController ل ڤێرێ ناهێتە دامەزراندن
    _fetchData();
  }

  @override
  void dispose() {
    // 2. پشتراست بە کو null نینە بەری کو ژناڤ ببەی
    _tabController?.dispose(); 
    super.dispose();
  }

  Future<void> _fetchData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    final isVendor = authProvider.user?.role == 'vendor';
    final futures = [
      _apiService.getMyActivity(token),
      _apiService.getWatchlist(token),
    ];
    if (isVendor) {
      futures.add(_apiService.getSoldAuctions(token));
    }

    try {
      final results = await Future.wait(futures);
      if (mounted) {
        final activityData = results[0] as Map<String, dynamic>?;
        _watchedAuctions = results[1] as List<Auction>?;

        if (activityData != null) {
          _stats = activityData['stats'];
          final allMyAuctions = (activityData['my_auctions'] as List? ?? []).map((d) => Auction.fromJson(d)).toList();
          _activeAuctions = allMyAuctions.where((a) => !a.isEnded).toList();
          _participatedAuctions = (activityData['participated_auctions'] as List? ?? []).map((d) => Auction.fromJson(d)).toList();
        }

        if (isVendor && results.length > 2) {
          _soldOrders = results[2] as List<Order>? ?? [];
        }

        // 3. ل ڤێرێ TabController دامەزرینە پشتی کو تە زانی چەند تاب هەنە
        final currentIsVendor = Provider.of<AuthProvider>(context, listen: false).user?.role == 'vendor';
        
        setState(() {
           _tabController = TabController(length: currentIsVendor ? 4 : 2, vsync: this);
           _isLoading = false;
        });

      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
        setState(() => _isLoading = false); // ل دەمێ خەلەتیێ ژی loading ب راوەستینە
      }
    }
  }

  void _onEditProfile() {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const EditProfileScreen()));
       
  }

 void _onblock() {

      Navigator.of(context).push(
        MaterialPageRoute(builder: (ctx) => const BlockedUsersScreen()),
      );
 
       
  }

  Widget _buildAuctionList(List<Auction> auctions, String emptyMessage) {
    if (auctions.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).disabledColor,
              ),
        ),
      );
    }

    return MasonryGridView.count(
      padding: const EdgeInsets.all(4),
      crossAxisCount: 3,
      mainAxisSpacing: 0,
      crossAxisSpacing: 0,
      itemCount: auctions.length,
      itemBuilder: (context, index) {
        final auction = auctions[index];
        return AuctionGridCard(
          auction: auction,
          isLarge: index % 5 == 0,
        );
      },
    );
  }

  Widget _buildSoldOrdersList(List<Order> orders, String emptyMessage) {
    final theme = Theme.of(context);
    if (orders.isEmpty) {
      return Center(
        
        child: Text(
          emptyMessage,
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor),
          
        ),
        
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (ctx, index) {
        final order = orders[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              AuctionGridCard(auction: order.auction),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, color: theme.colorScheme.primary, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'Sold to ${order.user?.name ?? "Unknown"}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Final price: \$${order.finalPrice}',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

Widget _buildProfileHeader(User? user) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  return Container(
    padding: const EdgeInsets.only(top: 72, bottom: 20),
    decoration: BoxDecoration(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(29),
        bottomRight: Radius.circular(24),
      ),
      boxShadow: [
      
      ],
    ),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
         ListView(
          padding: const EdgeInsets.fromLTRB(16, 7, 16, 20),
          physics: const NeverScrollableScrollPhysics(), // رێگری ل خشاندنێ دکەین چونکی NestedScrollView کارێ خۆ دکەت
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // وێنەیێ پرۆفایلێ
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: user?.profilePhotoUrl != null
                          ? Image.network(
                              user!.profilePhotoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, error, stackTrace) => Icon(
                                Icons.person,
                                size: 40,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            )
                          : Icon(
                              Icons.person_outline,
                              size: 40,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // ********* چارەسەری ل ڤێرێیە *********
                  // ئەم Flexible بکار دئینین دا کو رێگریێ ل Overflow بکەین
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'User',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // رێزا ئاماران (Stats Row)
              if (_stats != null)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatItem('Auctions', _stats?['total_auctions_created'] ?? 0),
                      const SizedBox(width: 16),
                      _buildStatItem('Bids', _stats?['auctions_sold'] ?? 0),
                      const SizedBox(width: 16),
                      _buildStatItem('Won', _stats?['won_count'] ?? 0),
                    ],
                  ),
                ),
            ],
          ),
      

        // دوگما "Edit"
     Positioned(
  top: -20,
  right: 0,
  child: Row(
    children: [
      if (user?.role == 'vendor') ...[
      IconButton(
        icon: const Icon(Icons.block_outlined),
        color: colorScheme.primary,
        tooltip: 'Block',
        onPressed: _onblock,
      ),
      ],
      IconButton(
        icon: const Icon(Icons.edit_outlined),
        color: colorScheme.primary,
        tooltip: 'Edit',
        onPressed: _onEditProfile,
      ),
    ],
  ),
)

      ],
    ),
  );
}
  
  
  
  Widget _buildStatItem(String label, dynamic value) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value.toString(),
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
   
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 2,
              ),
            )
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 250,
                    pinned: true,
                    floating: false,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    flexibleSpace: _buildProfileHeader(user),
 
                  ),
                                   
                ];
              },
              body: Column(
                children: [
                  // 4. پشتراست بە کو _tabController نەیێ null ە
                  if (_tabController != null)
                    Container(
                      color: colorScheme.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TabBar(
                        
                        controller: _tabController!, // نیشانا "!" بکاربینە
                        isScrollable: true,
                        indicatorSize: TabBarIndicatorSize.label,
                        indicator: UnderlineTabIndicator(
                          borderSide: BorderSide(
                            width: 3,
                            color: colorScheme.primary,
                          ),
                          
                          insets: const EdgeInsets.symmetric(horizontal: 16),
                          
                        ),
                        
                        labelColor: colorScheme.primary,
                        unselectedLabelColor: colorScheme.onSurface.withOpacity(0.5),
                        labelStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          
                        ),
                        tabs: [
                          if (user?.role == 'vendor') ...[
                            const Tab(text: 'Active'),
                            const Tab(text: 'Sold'),
                            
                           
                          ],
                          const Tab(text: 'Participated'),
                          const Tab(text: 'Watched'),
                        ],
                      ),
                    ),
                  
                  if (_tabController != null)
                    Expanded(
                      child: TabBarView(
                        controller: _tabController!, // نیشانا "!" بکاربینە
                        children: [
                           if (user?.role == 'vendor') ...[
                            _buildAuctionList(_activeAuctions, "No active auctions"),
                            _buildSoldOrdersList(_soldOrders, "No sold items yet"),
                          ],
                          _buildAuctionList(_participatedAuctions, "No participated auctions"),
                          _watchedAuctions == null
                              ? const Center(child: Text('Error loading data'))
                              : _buildAuctionList(_watchedAuctions!, "Watchlist is empty"),
                        ],
                      ),
                    ),
             
                ],
              ),
            ),
    );
  }
}