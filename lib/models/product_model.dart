// lib/models/product_model.dart

class Product {
  final int id;
  final int userId;
  final int? categoryId;
  final String title;
  final String description;
  final String imageUrl;
  final double price;
  final int quantity;
  final bool isSoldOut;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.isSoldOut,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Print the JSON structure for debugging
    print('Product JSON: $json');
    
    return Product(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      categoryId: _parseCategoryId(json['category_id']),
      title: json['title'] as String? ?? 'Untitled Product',
      description: json['description'] as String? ?? 'No description available',
      // Handle image URL - assuming it might be in a nested 'image' object or direct field
      imageUrl: _extractImageUrl(json),
      price: _parsePrice(json['price']),
      quantity: _parseQuantity(json['quantity']),
      isSoldOut: _parseBool(json['is_sold_out']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  static int? _parseCategoryId(dynamic categoryIdData) {
    try {
      if (categoryIdData == null) return null;
      if (categoryIdData is int) return categoryIdData;
      if (categoryIdData is String) return int.parse(categoryIdData);
      return null;
    } catch (e) {
      print('Error parsing category ID: $e, categoryIdData: $categoryIdData');
      return null;
    }
  }

  static int _parseQuantity(dynamic quantityData) {
    try {
      if (quantityData == null) return 1;
      if (quantityData is int) return quantityData;
      if (quantityData is String) return int.parse(quantityData);
      return 1;
    } catch (e) {
      print('Error parsing quantity: $e, quantityData: $quantityData');
      return 1;
    }
  }

  static bool _parseBool(dynamic boolData) {
    try {
      if (boolData == null) return false;
      if (boolData is bool) return boolData;
      if (boolData is String) return boolData.toLowerCase() == 'true';
      return false;
    } catch (e) {
      print('Error parsing boolean: $e, boolData: $boolData');
      return false;
    }
  }

  static double _parsePrice(dynamic priceData) {
    try {
      if (priceData == null) return 0.0;
      if (priceData is num) return priceData.toDouble();
      if (priceData is String) return double.parse(priceData);
      return 0.0;
    } catch (e) {
      print('Error parsing price: $e, priceData: $priceData');
      return 0.0;
    }
  }

  static String _extractImageUrl(Map<String, dynamic> json) {
    try {
      // Handle different possible image field structures
      if (json['images'] is List && (json['images'] as List).isNotEmpty) {
        // If images is an array, get the first image
        final images = json['images'] as List;
        final firstImage = images[0];
        if (firstImage is Map<String, dynamic>) {
          final path = firstImage['path'] as String?;
          if (path != null) {
            // Assuming images are served from the same base URL as the API
            return 'https://ubuntu.tail73d562.ts.net/storage/$path';
          }
        }
      } else if (json['image'] is String) {
        return json['image'] as String;
      } else if (json['image'] is Map<String, dynamic>) {
        // If image is an object, try to get URL from common fields
        final imageObj = json['image'] as Map<String, dynamic>;
        return imageObj['url'] as String? ?? 
               imageObj['path'] as String? ?? 
               imageObj['src'] as String? ?? 
               'https://via.placeholder.com/150';
      } else if (json['image_url'] is String) {
        return json['image_url'] as String;
      } else if (json['imageUrl'] is String) {
        return json['imageUrl'] as String;
      }
      return 'https://via.placeholder.com/150';
    } catch (e) {
      print('Error extracting image URL: $e');
      return 'https://via.placeholder.com/150';
    }
  }
}