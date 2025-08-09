// lib/models/product_model.dart

class Product {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final double startPrice;
  final DateTime auctionEndTime;
  

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.startPrice,
    required this.auctionEndTime,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      // دڵنیابە لەوەی کە ناوی ستوونی وێنە لە لاراولدا چییە
      imageUrl: json['image_url'] ?? 'https://via.placeholder.com/150',
      startPrice: double.parse(json['start_price'].toString()),
      auctionEndTime: DateTime.parse(json['auction_end_time']),
    );
  }
}