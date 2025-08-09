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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2),
      ),
      margin: const EdgeInsets.all(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(2),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => AuctionDetailScreen(auctionId: auction.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
         ClipRRect(
  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
  child: AspectRatio(
    aspectRatio: 1, // Square aspect ratio
    child: CachedNetworkImage(
      imageUrl: auction.images.isNotEmpty
          ? auction.images.first.url
          : '', // Provide an empty string or dummy URL if no image.
                // This will intentionally trigger the errorWidget.
      fit: BoxFit.cover,
      placeholder: (context, url) => Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary, // Use Theme.of(context)
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: const Color.fromARGB(255, 238, 238, 238),
        child: Image.asset(
          'assets/bid.png', // This is your local asset fallback
          fit: BoxFit.cover, // Ensure it covers the container
        ),
      ),
    ),
  ),
),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with max width constraint
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150), // Adjust as needed
                    child: Text(
                      auction.title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Price and Time Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price - Flexible to prevent overflow
                      Flexible(
                        child: Text(
                          '\$${auction.currentPrice.toStringAsFixed(2)}',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Time remaining - Flexible with minimum width
                      Flexible(
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 60),
                          child: TimerBuilder.periodic(
                            const Duration(seconds: 1),
                            builder: (context) {
                              final remaining = auction.endTime.difference(DateTime.now());
                              return Text(
                                remaining.isNegative 
                                    ? 'Ended'
                                    : '${remaining.inDays}d ${remaining.inHours.remainder(24)}h',
                                style: textTheme.bodySmall?.copyWith(
                                  color: remaining.isNegative
                                      ? Colors.red
                                      : colorScheme.onSurface,
                                      fontSize: 8
                                ),
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
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
    );
  }
}