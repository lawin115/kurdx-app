// lib/models/shipment_model.dart
import './order_model.dart';

class Shipment {
  final int id;
  final String status;
  final List<Order> orders;
  final double totalValue;
  // ... zanyari vendor ...

  Shipment({
    required this.id,
    required this.status,
    required this.orders,
    required this.totalValue,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['id'],
      status: json['status'],
      totalValue: double.parse(json['total_value'].toString()),
      orders: (json['orders'] as List).map((o) => Order.fromJson(o)).toList(),
    );
  }
}