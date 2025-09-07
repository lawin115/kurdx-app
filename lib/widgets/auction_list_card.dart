import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:timer_builder/timer_builder.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/auction_model.dart';
import '../providers/auth_provider.dart';
import '../auction_detail_screen.dart';

class AuctionGridCard extends StatelessWidget {
  final Auction auction;
  final bool isLarge;
  
  const AuctionGridCard({
    super.key, 
    required this.auction,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final priceText = NumberFormat.simpleCurrency().format(auction.currentPrice);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => AuctionDetailScreen(auctionId: auction.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min, // Prevent overflow
          children: [
            // 🖼️ Image with Hero + Badge
            Stack(
              children: [
                Hero(
                  tag: "auction-${auction.id}",
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: auction.images.isNotEmpty
                          ? auction.images.first.url
                          : '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Image.asset(
                          'assets/bid.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildStatusBadge(colorScheme),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildTimeBadge(auction.endTime, colorScheme),
                ),
              ],
            ),

            // 📄 Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Prevent overflow
                children: [
                  // 🏷️ Title
                  Text(
                    auction.title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // 💰 Price
                  Text(
                    priceText,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔖 Status Badge (Live/Ended/Featured)
  Widget _buildStatusBadge(ColorScheme colors) {
    final isEnded = auction.endTime.isBefore(DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isEnded ? Colors.redAccent : colors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isEnded ? "Ended" : "Live",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ⏳ Time Remaining Badge
  Widget _buildTimeBadge(DateTime endTime, ColorScheme colors) {
    return TimerBuilder.periodic(
      const Duration(seconds: 1),
      builder: (context) {
        final remaining = endTime.difference(DateTime.now());
        if (remaining.isNegative) {
          return _timeChip("0s", Colors.redAccent);
        }

        final text = _formatRemaining(remaining);
        final urgent = remaining.inMinutes < 10;

        return _timeChip(
          text,
          urgent ? Colors.orange : colors.primary,
        );
      },
    );
  }

  Widget _timeChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatRemaining(Duration d) {
    if (d.inDays > 0) return "${d.inDays}d ${d.inHours.remainder(24)}h";
    if (d.inHours > 0) return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
    if (d.inMinutes > 0) return "${d.inMinutes}m";
    return "${d.inSeconds}s";
  }
}