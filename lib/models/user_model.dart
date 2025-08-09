// lib/models/user_model.dart

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phoneNumber;
  final String? location;
  final String? about;
  final String? vendorTerms;
  final String? profilePhotoUrl;
  final bool isFollowedByMe; // گرنگە بۆ لاپەڕەی Explore

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.location,
    this.about,
    this.vendorTerms,
    this.profilePhotoUrl,
    this.isFollowedByMe = false, // نرخی بنەڕەتی
  });

  // ===== چارەسەری سەرەki لێرەدایە =====
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      
      // پشکنینی null و دانانی نرخی بنەڕەتی
      name: json['name'] ?? 'User Not Found',
      email: json['email'] ?? '', // ئیمەیڵی بەتاڵ
      role: json['role'] ?? 'user', // ڕۆڵی بنەڕەتی
      
      // ئەم property-یانە هەر nullable بوون
      phoneNumber: json['phone_number'],
      location: json['location'],
      about: json['about'],
      vendorTerms: json['vendor_terms'],
      profilePhotoUrl: json['profile_photo_url'],
      
      isFollowedByMe: json['is_followed_by_me'] ?? false,
    );
  }

  // ===== функцIAی toJson-ی کامڵ =====
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,

 'phone_number': phoneNumber,
      'location': location,
      'about': about,
      'vendor_terms': vendorTerms,
      'profile_photo_url': profilePhotoUrl,
      'is_followed_by_me': isFollowedByMe,
    };
  }
}