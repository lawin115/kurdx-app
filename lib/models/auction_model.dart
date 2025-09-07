// lib/models/auction_model.dart
import 'dart:convert';
import './user_model.dart';
import './bid_model.dart';
import './comment_model.dart';
import './auction_image_model.dart';
import './category_model.dart';

List<Auction> auctionFromJson(String str) {
  final jsonVal = json.decode(str);
  if (jsonVal is List) {
    return jsonVal.map((x) => Auction.fromJson(x as Map<String, dynamic>)).toList();
  }
  if (jsonVal is Map<String, dynamic> && jsonVal['data'] is List) {
    return (jsonVal['data'] as List)
        .map((x) => Auction.fromJson(x as Map<String, dynamic>))
        .toList();
  }
  return const <Auction>[];
}

class Auction {
  final int id;
  final String title;
  final String description;
  final double startingPrice;
  final double currentPrice;
  final DateTime endTime;
  final int userId;

  final User? user;          // خاوەنی مەزاد
  final Category? category;  // پۆلێن
  final List<AuctionImage> images;
  final List<Bid> bids;
  final List<Comment> comments;

  final DateTime createdAt;
  final double bidIncrement;

  // UI-state اختیاری
  final bool? isLiked;

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
    required this.bidIncrement,
    this.isLiked,
  });

  // ===== Helpers =====
  bool get isEnded => DateTime.now().isAfter(endTime);
  bool get isLive => !isEnded;

  String? get coverImageUrl =>
      images.isNotEmpty ? images.first.url : null;

  Duration get remaining {
    final now = DateTime.now();
    return endTime.isAfter(now) ? endTime.difference(now) : Duration.zero;
  }

  /// 0.0 → 1.0 (تەنها ئەگەر بتوانین زمان‌بندی بسنجین)
  double? get progress {
    // ئەگەر bids هەیە و createdAt/endTime دیارە، ئاسایییەک بسنجین
    final total = endTime.difference(createdAt).inSeconds;
    if (total <= 0) return null;
    final passed = DateTime.now().difference(createdAt).inSeconds;
    final p = passed / total;
    if (p.isNaN) return null;
    return p.clamp(0.0, 1.0);
  }

  // ===== Safe parsers =====
  static double _toDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  static DateTime _toDate(dynamic v, {DateTime? fallback}) {
    if (v == null) return fallback ?? DateTime.now();
    if (v is DateTime) return v;
    // پشتیوانی لە ISO8601
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return fallback ?? DateTime.now();
    }
  }

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      id: _toInt(json['id']),
      title: (json['title'] ?? 'No Title').toString(),
      description: (json['description'] ?? '').toString(),
      startingPrice: _toDouble(json['starting_price']),
      currentPrice: _toDouble(json['current_price']),
      endTime: _toDate(json['end_time']),
      userId: _toInt(json['user_id']),
      user: json['user'] == null ? null : User.fromJson(json['user']),
      category: json['category'] == null ? null : Category.fromJson(json['category']),
      images: (json['images'] as List?)
              ?.map((x) => AuctionImage.fromJson(x))
              .toList() ??
          const <AuctionImage>[],
      bids: (json['bids'] as List?)
              ?.map((x) => Bid.fromJson(x))
              .toList() ??
          const <Bid>[],
      comments: (json['comments'] as List?)
              ?.map((x) => Comment.fromJson(x))
              .toList() ??
          const <Comment>[],
      createdAt: _toDate(json['created_at']),
      bidIncrement: _toDouble(json['bid_increment'], fallback: 1.0),
      isLiked: json['is_liked'] is bool ? json['is_liked'] as bool : null,
    );
  }

  get bidCount => null;

  get viewCount => null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'starting_price': startingPrice,
        'current_price': currentPrice,
        'end_time': endTime.toIso8601String(),
        'user_id': userId,
        'user': user?.toJson(),
        'category': category?.toJson(),
        'images': images.map((e) => e.toJson()).toList(),
        'bids': bids.map((e) => e.toJson()).toList(),
        'comments': comments.map((e) => e.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'bid_increment': bidIncrement,
        if (isLiked != null) 'is_liked': isLiked,
      };

  Auction copyWith({
    int? id,
    String? title,
    String? description,
    double? startingPrice,
    double? currentPrice,
    DateTime? endTime,
    int? userId,
    User? user,
    Category? category,
    List<AuctionImage>? images,
    List<Bid>? bids,
    List<Comment>? comments,
    DateTime? createdAt,
    double? bidIncrement,
    bool? isLiked,
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
      isLiked: isLiked ?? this.isLiked,
    );
  }

  // یارمەتی بۆ paginateی Laravel
  static List<Auction> listFromPaginated(Map<String, dynamic> pageJson) {
    final list = (pageJson['data'] as List? ?? const []);
    return list.map((e) => Auction.fromJson(e as Map<String, dynamic>)).toList();
  }
}
