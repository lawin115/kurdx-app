// lib/models/order_model.dart
import './auction_model.dart';
import './user_model.dart'; // <-- importـی نوێس

class Order {
  final int id;
  final String status;
  final double finalPrice;
  final Auction auction;
  final User? user; // <-- چارەسەرەکە لێرەدایە

  final User? vendor;  // فرۆشیار - Vendor (دەکرێت nullable بێت)
  Order({required this.id, required this.status, required this.finalPrice, required this.auction, this.user ,this.vendor});

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'],
    status: json['status'],
    finalPrice: double.parse(json['final_price'].toString()),
    auction: Auction.fromJson(json['auction']),
    user: json['user'] != null ? User.fromJson(json['user']) : null,
      vendor: json['vendor'] == null ? null : User.fromJson(json['vendor']),
  );
  Order copyWith({String? status}) {
    return Order(
      id: this.id, status: status ?? this.status, finalPrice: this.finalPrice,
      auction: this.auction, user: this.user, vendor: this.vendor,
    );
  }
 
}