import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/auction_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';
import './auction_list_card.dart'; // Make sure this is in your widgets folder

// Helper function for the gradient background
BoxDecoration getInstagramGradient() {
  return const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xFFE1306C), // Instagram Pink
        Color(0xFF833AB4), // Instagram Purple
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}

// Custom widget for the profile header
class ProfileHeader extends StatelessWidget {
  final User? user;
  final Map<String, dynamic>? stats;

  const ProfileHeader({super.key, required this.user, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      decoration: getInstagramGradient(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: user?.profilePhotoUrl != null
                      ? NetworkImage(user!.profilePhotoUrl!)
                      : null,
                  child: user?.profilePhotoUrl == null
                      ? Icon(Icons.person_outline, size: 40, color: theme.colorScheme.primary)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'User',
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (stats != null) StatsRow(stats: stats!),
            const SizedBox(height: 16),
            const ThemeSwitcher(),
          ],
        ),
      ),
    );
  }
}

// Custom widget for the stats row
class StatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        StatItem(label: 'Auctions', value: stats['total_auctions_created'] ?? 0),
        StatItem(label: 'Bids', value: stats['auctions_sold'] ?? 0),
        StatItem(label: 'Won', value: stats['won_count'] ?? 0),
      ],
    );
  }
}

// Custom widget for a single stat item
class StatItem extends StatelessWidget {
  final String label;
  final dynamic value;

  const StatItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toString(),
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom widget for the theme switcher
class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            themeProvider.themeMode == ThemeMode.dark
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            'Theme',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const Spacer(),
          SizedBox(
            width: 120, // Constrain width for consistency
            child: DropdownButton<ThemeMode>(
              value: themeProvider.themeMode,
              underline: const SizedBox(),
              dropdownColor: colorScheme.surface,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
                ),
              ],
              onChanged: (value) {
                if (value != null) themeProvider.setThemeMode(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Custom widget for the Staggered Grid
class AuctionGrid extends StatelessWidget {
  final List<Auction> auctions;
  final String emptyMessage;

  const AuctionGrid({super.key, required this.auctions, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
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
    
    // Check screen size to determine crossAxisCount
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 5 : 3;

    return MasonryGridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 10,
      crossAxisSpacing: 0,
      itemCount: auctions.length,
      itemBuilder: (context, index) {
        final auction = auctions[index];
        return AuctionGridCard(
          auction: auction,
          isLarge: index % 5 == 0, // Make every 5th item larger
        );
      },
    );
  }
}

// Custom widget for the sold orders list
class SoldOrdersList extends StatelessWidget {
  final List<Order> orders;
  final String emptyMessage;

  const SoldOrdersList({super.key, required this.orders, required this.emptyMessage});

  @override
  Widget build(BuildContext context) {
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
}