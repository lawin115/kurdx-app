// lib/models/auction_model.dart
import 'dart:convert';
import './user_model.dart';
import './bid_model.dart';
import './comment_model.dart';
import './auction_image_model.dart';
import './category_model.dart'; // <-- مۆدێلی پۆلێن زیادکرا
List<Auction> auctionFromJson(String str) => List<Auction>.from(json.decode(str).map((x) => Auction.fromJson(x)));
class Auction {
  final int id;
  final String title;
  final String description;
  final double startingPrice;
  final double currentPrice;
  final DateTime endTime;
  final int userId;
  final User? user; // خاوەنی مەزاد
  final Category? category; // پۆلێنی مەزاد
  final List<AuctionImage> images;
  final List<Bid> bids;
  final List<Comment> comments;
  final DateTime createdAt; // <-- ئەمە زیاد بکە
final double bidIncrement; // <-- زیاد بکە
  Auction({
    required this.id,
    required this.title,
    required this.description,
    required this.startingPrice,
    required this.currentPrice,
    required this.endTime,
    required this.userId,
    this.user,
    this.category,
    required this.images,
    required this.bids,
    required this.comments,
    required this.createdAt,
    required this.bidIncrement
  });

  // ===== Getter-ە یارمەتیدەرەکان =====
  bool get isEnded => DateTime.now().isAfter(endTime);
  bool get isLive => !isEnded;
  String? get coverImageUrl => images.isNotEmpty ? images.first.url : null;

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      bidIncrement: double.parse(json['bid_increment']?.toString() ?? '1.0'),
      id: json['id'],
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? '',
      startingPrice: double.parse(json['starting_price']?.toString() ?? '0.0'),
      currentPrice: double.parse(json['current_price']?.toString() ?? '0.0'),
      endTime: DateTime.parse(json['end_time']),
      userId: json['user_id'],
      user: json['user'] == null ? null : User.fromJson(json['user']),
      category: json['category'] == null ? null : Category.fromJson(json['category']),
      images: json['images'] == null ? [] : List<AuctionImage>.from(json['images'].map((x) => AuctionImage.fromJson(x))),
      bids: json['bids'] == null ? [] : List<Bid>.from(json['bids'].map((x) => Bid.fromJson(x))),
      comments: json['comments'] == null ? [] : List<Comment>.from(json['comments'].map((x) => Comment.fromJson(x))),
      createdAt: DateTime.parse(json['created_at']), // <-- ئەمە زیاد بکە
    );
  }

  set isLiked(bool isLiked) {}

  // ===== функцIAی copyWith-ی کامڵ =====
  Auction copyWith({
    int? id, String? title, String? description,
    double? startingPrice, double? currentPrice, DateTime? endTime,
    int? userId, User? user, Category? category,
    List<AuctionImage>? images, List<Bid>? bids, List<Comment>? comments,
    DateTime? createdAt,
    double? bidIncrement
  }) {
    return Auction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startingPrice: startingPrice ?? this.startingPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      endTime: endTime ?? this.endTime,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      category: category ?? this.category,
      images: images ?? this.images,
      bids: bids ?? this.bids,
      comments: comments ?? this.comments,
       createdAt: createdAt ?? this.createdAt,
      bidIncrement: bidIncrement ?? this.bidIncrement,
    );
  }
}