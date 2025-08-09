// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io'; // بۆ بەکارهێنانی File
import 'package:flutter/src/widgets/editable_text.dart';
import 'package:http/http.dart' as http;
import 'package:kurdpoint/models/category_model.dart';
import 'package:kurdpoint/models/comment_model.dart';
import 'package:kurdpoint/models/conversation_model.dart';
import 'package:kurdpoint/models/notification_model.dart';
import 'package:kurdpoint/models/order_model.dart';
import '../models/auction_model.dart';
import '../models/user_model.dart';
import '../models/comment_model.dart';
import '../models/message_model.dart'; // <-- دڵنیابە ئەمە import کراوە#
import '../models/auction_model.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../models/comment_model.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../models/category_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // تکایە دڵنیابە ئەمە IP دروستەکەیە
  final String _baseUrl = "https://ubuntu.tail73d562.ts.net/api";

  // ===== функцیای یەکەم: وەرگرتنی هەموو مەزادەکان =====
// lib/services/api_service.dart


Future<Auction?> createAuction({
  required String token,
  required Map<String, String> data,
  required List<File> images, // <-- گۆڕدرا بۆ لیستی فایل

}) async {
  final url = Uri.parse("$_baseUrl/auctions");
  try {
    var request = http.MultipartRequest('POST', url);

    // Add headers
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // Add form fields (auction data)
    request.fields.addAll(data);

    // Check if image file is provided
      for (var i = 0; i < images.length; i++) {
      // Add image file to the request
      request.files.add(await http.MultipartFile.fromPath('images[]', images[i].path));
    } 

    // Send request
    var response = await request.send();

    if (response.statusCode == 201) { // Created successfully
      final responseBody = await response.stream.bytesToString();
      return Auction.fromJson(json.decode(responseBody));
    } else {
      final responseBody = await response.stream.bytesToString();
      print("Failed to create auction: $responseBody");
    }
  } catch (e) {
    print("Error in createAuction: $e");
  }
  return null;
} 


Future<Map<String, dynamic>?> getAuctions({
  required int page,
  String? searchTerm,
  int? categoryId,
  String? apiToken, required int limit, // <-- تۆکنی بەکارهێنەری لۆگین بوو
}) async {

  // ===== 1. دیاریکردنی Endpointـی دروست =====
  // ئەگەر بەکارهێنەر لۆگین بوو, داواکاری بۆ ڕێگا پارێزراوەکە دەنێرین.
  // ئەگەرنا, بۆ ڕێگا گشتییەکە.
  final String endpoint = (apiToken != null && apiToken.isNotEmpty) 
      ? "/auctions/authenticated" 
      : "/auctions/guest";
      
  // ===== 2. ئامادەکردنی پارامەترەکان =====
  final Map<String, String> queryParameters = {
    'page': page.toString(),
  };
  if (searchTerm != null && searchTerm.isNotEmpty) {
    queryParameters['search'] = searchTerm;
  }
  if (categoryId != null) {
    queryParameters['category'] = categoryId.toString();
  }

  // دروستکردنی URLـی کۆتایی
  final url = Uri.parse("$_baseUrl$endpoint").replace(queryParameters: queryParameters);

  print("Fetching auctions from: $url");
  print("Authenticated: ${apiToken != null}");

  try {
    // ===== 3. ئامادەکردنی Headerـەکان =====
    final Map<String, String> headers = {
      'Accept': 'application/json',
      'Cache-Control': 'no-cache', // بۆ دڵنیابوون لەوەی هەمیشە داتای نوێ دێت
    };
    // ئەگەر تۆکن هەبوو, زیادی دەکەین بۆ header
    if (apiToken != null && apiToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiToken';
    }

    final response = await http.get(
      url,
      headers: headers,
    ).timeout(const Duration(seconds: 15));

    print("Paginated auctions response status: ${response.statusCode}");
    
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      print("Failed to fetch auctions. Body: ${response.body}");
    }
  } catch (e) {
    print("!!! ERROR in paginated getAuctions: ${e.toString()}");
  }

  return null;
}


Future<bool> applyToBeVendor(Map<String, String> data, String token) async {
  final url = Uri.parse("$_baseUrl/profile/apply-vendor");
  try {
    final response = await http.post(url, headers: {'Authorization': 'Bearer $token'}, body: data);
    return response.statusCode == 201;
  } catch (e) { return false; }
}
Future<List<Order>?> getMyOrders(String token) async {
  final url = Uri.parse("$_baseUrl/profile/orders");
  try {
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((d) => Order.fromJson(d)).toList();
    }
  } catch (e) { /* ... */ }
  return null;
}
Future<List<NotificationModel>?> getNotifications(String token) async {
  final url = Uri.parse("$_baseUrl/notifications");

  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final List<dynamic> data = jsonData['data'];

      return data.map((item) => NotificationModel.fromJson(item)).toList();
    } else {
      print("Failed to fetch notifications: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Error getting notifications: $e");
  }

  return null;
}


// نیشانکردنی ئاگادارکردنەوە وەک خوێندراوە
Future<bool> markNotificationAsRead(String notificationId, String token) async {
  final url = Uri.parse("$_baseUrl/notifications/$notificationId/mark-as-read");

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 204) {
      print("✅ Notification $notificationId marked as read.");
      return true;
    } else {
      print("❌ Failed to mark as read: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Error marking notification as read: $e");
  }

  return false;
}

// lib/services/api_service.dart

Future<User?> updateUserProfile({
  required String token,
  required String name,
  required String email,
  // ===== گۆڕانکاری لێرەدایە: پارامەترە نوێیەکان =====
  required String phone,
  required String location,
  required String about,
  File? photoFile, 
  required String vendorTerms,
}) async {
  final url = Uri.parse("$_baseUrl/profile/update");
  print("--- Updating profile for user... ---");
  try {
    var request = http.MultipartRequest('POST', url);
    
    // زیادکردنی Header
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // ===== چارەسەرەکە لێرەدایە: زیادکردنی هەموو field-ەکان =====
    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['phone_number'] = phone; // دڵنیابە ناوی keyـەکە وەک Laravel-ە
    request.fields['location'] = location;
    request.fields['about'] = about;
    request.fields['vendor_terms'] = vendorTerms;
    
    // زیادکردنی وێنەکە (ئەگەر هەبوو)
    if (photoFile != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));
    }

    var response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    print("--- Update profile response status: ${response.statusCode} ---");

    if (response.statusCode == 200) {
      print("--- Profile updated successfully. Response: $responseBody ---");
      return User.fromJson(json.decode(responseBody));
    } else {
      print("!!! Failed to update profile. Response: $responseBody");
    }
  } catch (e) {
    print("!!! ERROR in updateUserProfile: $e");
  }
  return null;
}

Future<Comment?> postComment(int auctionId, String body, int? parentId, String token) async {
  final url = Uri.parse("$_baseUrl/auctions/$auctionId/comments");
  try {
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json', 'Content-Type': 'application/json'},
      body: json.encode({'body': body, 'parent_id': parentId}),
    );
    if (response.statusCode == 201) {
      return Comment.fromJson(json.decode(response.body));
    }
  } catch (e) { /* ... */ }
  return null;
}

Future<List<Category>?> getCategories() async {
  final url = Uri.parse("$_baseUrl/categories");
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((d) => Category.fromJson(d)).toList();
    }
  } catch (e) { /* ... */ }
  return null;
}

  // ===== функцیای دووەم: وەرگرتنی زانیاری یەک مەزاد =====
  Future<Auction?> getAuctionDetails(int id, String? token) async { // <-- String? token زیاد بکە
  final url = Uri.parse("$_baseUrl/auctions/$id");
  try {
    // ===== چارەسەرەکە لێرەدایە: زیادکردنی Header =====
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        // ئەگەر تۆکن هەبوو، بینێرە
        if (token != null) 'Authorization': 'Bearer $token', 
      },
    ).timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      return Auction.fromJson(json.decode(response.body));
    }
  } catch (e) {
    print("Error in getAuctionDetails: $e");
  }
  return null;
}
Future<Map<String, dynamic>?> getMyActivity(String token) async {
  final url = Uri.parse("$_baseUrl/profile/activity");
  print("Fetching user activity from: $url"); // -- بۆ تێست

  try {
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    print("getMyActivity response status: ${response.statusCode}"); // -- بۆ تێست
    print("getMyActivity response body: ${response.body}"); // -- بۆ تێست

    if (response.statusCode == 200) {
      print("Successfully fetched activity."); // -- بۆ تێست
      return json.decode(response.body);
    }
  } catch (e) {
    print("!!! FATAL ERROR in getMyActivity: ${e.toString()}"); // -- بۆ تێست
  }
  
  print("getMyActivity failed and returned null."); // -- بۆ تێست
  return null;
}

Future<bool> toggleWatchlist(int auctionId, String token) async {
  final url = Uri.parse("$_baseUrl/auctions/$auctionId/toggle-watchlist");
  try {
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

Future<List<Auction>?> getWatchlist(String token) async {
  final url = Uri.parse("$_baseUrl/watchlist");
  try {
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      return auctionFromJson(response.body);
    }
  } catch (e) {
    // ...
  }
  return null;
}
  // ===== функцیای سێیەم: زیادکردنی نرخ =====
  Future<bool> placeBid(int auctionId, String amount, String token) async {
    final url = Uri.parse("$_baseUrl/auctions/$auctionId/bids");
    print("Placing bid for auction ID $auctionId with amount $amount");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'amount': amount}),
      ).timeout(const Duration(seconds: 15));
      
      print("Place bid response status: ${response.statusCode}");
      print("Place bid response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      print("!!! ERROR in placeBid: ${e.toString()}");
    }
    return false;
  }

 Future<Map<String, dynamic>?> login(String email, String password) async {
  final url = Uri.parse("$_baseUrl/login");
  try {
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {'email': email, 'password': password},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
  } catch (e) {
    print("Error in login service: $e");
  }
  return null;
}


// lib/services/api_service.dart

Future<Map<String, dynamic>?> toggleFollow(int vendorId, String token) async {
  final url = Uri.parse("$_baseUrl/vendors/$vendorId/toggle-follow");
  try {
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
  } catch (e) { print("Error toggling follow: $e"); }
  return null;
}


 Future<List<Order>?> getSoldAuctions(String token) async {
    final url = Uri.parse("$_baseUrl/profile/sold");
    print("--- Fetching sold auctions from: $url ---");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      print("--- Sold auctions response status: ${response.statusCode} ---");
      
      if (response.statusCode == 200) {
        // وەڵامەکە لیستێکە لە ئۆبجێکتەکانی Order
        final List<dynamic> data = json.decode(response.body);
        
        // گۆڕینی هەر ئۆبجێکتێکی JSON بۆ ئۆبجێکتی Order
        return data.map((jsonOrder) => Order.fromJson(jsonOrder)).toList();
      }
    } catch (e) {
      print("!!! ERROR in getSoldAuctions: $e");
    }
    
    // لە کاتی هەڵەدا, null بگەڕێنەرەوە
    return null;
  }
Future<Map<String, dynamic>?> scanOrder(String orderId, String token) async {
  final url = Uri.parse("$_baseUrl/driver/scan-order");
  try {
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      body: {'order_id': orderId},
    );
    if (response.statusCode == 200) return json.decode(response.body);
  } catch (e) { /*...*/ }
  return null;
}
Future<Order?> updateOrderStatus(int orderId, String newStatus, String token) async {
  final url = Uri.parse("$_baseUrl/orders/$orderId/update-status");
  try {
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      body: {'status': newStatus},
    );
    if (response.statusCode == 200) {
      return Order.fromJson(json.decode(response.body));
    }
  } catch (e) { /* ... */ }
  return null;
}
Future<Map<String, dynamic>?> register(Map<String, String> data) async {
  final url = Uri.parse("$_baseUrl/register");
  try {
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: data,
    );
    
    // ئەگەر سەرکەوتوو بوو یان هەڵەی validation هەبوو، وەڵامەکە بگەڕێنەرەوە
    if (response.statusCode == 201 || response.statusCode == 422) {
      return json.decode(response.body);
    }
  } catch (e) { print("Error in register service: $e"); }
  return null;
}

  Future<Map<String, dynamic>?> getOrderPaymentDetails(int orderId, String token) async {
    final url = Uri.parse("$_baseUrl/orders/$orderId/payment-details");
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Error in getOrderPaymentDetails: $e");
    }
    return null;
  }
  Future<bool> confirmPayment(int orderId, String token) async {
    final url = Uri.parse("$_baseUrl/orders/$orderId/confirm-payment");
    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      // ئەگەر سەرکەوتوو بوو، true دەگەڕێنینەوە
      return response.statusCode == 200;
    } catch (e) {
      print("Error in confirmPayment: $e");
    }
    // ئەگەر هەڵەیەک ڕوویدا، false دەگەڕێنینەوە
    return false;
  }


Future<Map<String, dynamic>?> getVendorProfile(int vendorId, String? token) async {
  final url = Uri.parse("$_baseUrl/vendors/$vendorId");
  try {
    // زیادکردنی Header تەنها ئەگەر لۆگین بوو
    final headers = {'Accept': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
  } catch (e) { /* ... */ }
  return null;
}

Future<int?> startOrGetConversation(int otherUserId, String token) async {
    final url = Uri.parse("$_baseUrl/chat/start/$otherUserId");
    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['conversation_id'];
      }
    } catch (e) {
      print("Error in startOrGetConversation: $e");
    }
    return null;
  }

 Future<List<Message>?> getMessages(int conversationId, String token) async {
    final url = Uri.parse("$_baseUrl/chat/$conversationId/messages");
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> paginatedData = json.decode(response.body);
        final List<dynamic> data = paginatedData['data'];
        return data.map((d) => Message.fromJson(d)).toList();
      }
    } catch (e) {
      print("Error in getMessages: $e");
    }
    return null;
  }

// lib/services/api_service.dart

Future<Message?> sendMessage(int conversationId, String body, String token) async {
  final url = Uri.parse("$_baseUrl/chat/$conversationId/messages");
  
  print("--- Sending message to Laravel ---");
  print("URL: $url");
  print("Body: $body");

  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',

 'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      // تەنها text دەنێرین، چونکە مەزاد نییە
      body: json.encode({'body': body, 'type': 'text'}),
    );

    print("--- Send message response status: ${response.statusCode} ---");
    print("--- Response body: ${response.body} ---");

    if (response.statusCode == 201) {
      return Message.fromJson(json.decode(response.body));
    }
  } catch (e) {
    print("!!! ERROR in sendMessage: $e");
  }
  return null;
}

Future<List<Conversation>?> getConversations(String token) async {
  final url = Uri.parse("$_baseUrl/chat/conversations");
  try {
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((d) => Conversation.fromJson(d)).toList();
    }
  } catch (e) { /* ... */ }
  return null;
}

// ===== функцIAی نوێ بۆ وەرگرتنی پێشانگا دیارەکان =====
  Future<List<User>?> getFeaturedVendors() async {
    final url = Uri.parse("$_baseUrl/vendors/featured");
    print("--- Fetching featured vendors from: $url ---");

    try {
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );
      
      print("--- Featured vendors response status: ${response.statusCode} ---");
      
      if (response.statusCode == 200) {
        // وەڵامەکە لیستێکە لە ئۆبجێکتەکانی User
        final List<dynamic> data = json.decode(response.body);
        
        // گۆڕینی هەر ئۆبجێکتێکی JSON بۆ ئۆبجێکتی User
        return data.map((jsonUser) => User.fromJson(jsonUser)).toList();
      }
    } catch (e) {
      print("!!! ERROR in getFeaturedVendors: $e");
    }
    
    // لە کاتی هەڵەدا, null بگەڕێنەرەوە
    return null;
  }

// lib/services/api_service.dart

Future<Message?> shareAuctionInChat(int conversationId, int auctionId, String token) async {
  final url = Uri.parse("$_baseUrl/chat/$conversationId/messages");
  
  // داتاکان بە شێوازی دروست ئامادە دەکەین
  final Map<String, dynamic> body = {
    'type': 'auction_share',
    'metadata': {
      'auction_id': auctionId, // وەک integer دەینێرین، Laravel خۆی مامەڵەی لەگەڵ دەکات
    },
    'body': 'مەزاد هاوبەشی پێکرا' // یان هەر پەیامێکی تر
  };
print("===== SENDING REQUEST TO LARAVEL =====");
  print("URL: $url");
  print("METHOD: POST");
  print("TOKEN: Bearer $token");
  print("BODY (JSON): ${json.encode(body)}");
  print("======================================");
  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(body),
    );

      if (response.statusCode == 201 || response.statusCode == 200) {
      return Message.fromJson(json.decode(response.body));
    } else {
      // چیتر "Failed to share..." print ناکەین ئەگەر 200 بوو
      print("Failed to share auction. Status: ${response.statusCode}");
      print("Response Body: ${response.body}");
    }
  } catch (e) {
    print("!!! ERROR in shareAuctionInChat: $e");
  }
  return null;
}
Future<bool> toggleBlockUser(int userId, String token) async {
  final url = Uri.parse("$_baseUrl/users/$userId/toggle-block");
  try {
    final response = await http.post(url, headers: {'Authorization': 'Bearer $token'});
    return response.statusCode == 200;
  } catch (e) { return false; }
}
Future<List<User>?> getBlockedUsers(String token) async {
  final url = Uri.parse("$_baseUrl/blocked-users");
  try {
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      final Map<String, dynamic> paginatedData = json.decode(response.body);
      final List<dynamic> data = paginatedData['data'];
      return data.map((d) => User.fromJson(d)).toList();
    }
  } catch (e) { /* ... */ }
  return null;
}
Future<bool> updateFCMToken(String fcmToken, String apiToken) async {
  final url = Uri.parse("$_baseUrl/fcm-token");
  print("--- Sending FCM Token to Server: $fcmToken ---");
  try {
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $apiToken',
      },
      body: {'fcm_token': fcmToken},
    );
    
    if (response.statusCode == 200) {
      print("--- FCM Token updated successfully on server. ---");
      return true;
    } else {
      print("--- Failed to update FCM Token on server. Status: ${response.statusCode}, Body: ${response.body} ---");
    }
  } catch (e) {
    print("!!! ERROR sending FCM token: $e");
  }
  return false;
}

    Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        print("⚠️ No auth token found in SharedPreferences.");
        return null;
      }

      return token;
    } catch (e) {
      print("❌ Error retrieving auth token: $e");
      return null;
    }
  }
Future<List<Auction>?> getFeaturedAuctions() async {
  final url = Uri.parse("$_baseUrl/auctions/featured");
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return auctionFromJson(response.body);
    }
  } catch (e) { print("Error getting featured auctions: $e"); }
  return null;
}
  
  // ===== функцIAی دووەم: گەڕان بۆ بەکارهێنەران =====
  Future<Map<String, dynamic>?> searchUsers({
    required String role, 
    String? searchTerm, 
    String? token
  }) async {
    var uri = Uri.parse("$_baseUrl/explore/users").replace(
      queryParameters: { 'role': role, 'search': searchTerm ?? '' }
    );
    
    try {
      final headers = {'Accept': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) {
      print("Error searching users: $e");
    }
    return null;
  }

}