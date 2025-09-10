// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:kurdpoint/models/driver_dashboard_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kurdpoint/models/category_model.dart';
import 'package:kurdpoint/models/comment_model.dart';
import 'package:kurdpoint/models/conversation_model.dart';
import 'package:kurdpoint/models/notification_model.dart';
import 'package:kurdpoint/models/order_model.dart';
import 'package:kurdpoint/models/auction_model.dart';
import 'package:kurdpoint/models/user_model.dart';
import 'package:kurdpoint/models/message_model.dart';
import '../models/product_model.dart'; // <-- مۆدێلی نوێ

class ApiService {
  final String _baseUrl = "https://ubuntu.tail73d562.ts.net/api";

  // Helper method to get headers with optional token
  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // ===== AUCTION METHODS =====
  Future<Auction?> createAuction({
    required String token,
    required Map<String, String> data,
    required List<File> images,
  }) async {
    final url = Uri.parse("$_baseUrl/auctions");
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(_getHeaders(token: token));
      request.fields.addAll(data);

      for (var i = 0; i < images.length; i++) {
        request.files.add(await http.MultipartFile.fromPath(
          'images[]', 
          images[i].path
        ));
      }

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        return Auction.fromJson(json.decode(responseBody));
      } else {
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
  String? apiToken, required int limit, required bool liveOnly, // تەنها بۆ ناردنی Header
}) async {
  // ===== چارەسەرەکە لێرەدایە: تەنها یەک URL بەکاردەهێنین =====
  final Map<String, String> queryParameters = {
    'page': page.toString(),
  };
  
  if (searchTerm != null && searchTerm.isNotEmpty) {
    queryParameters['search'] = searchTerm;
  }
  if (categoryId != null) {
    queryParameters['category'] = categoryId.toString();
  }

  final url = Uri.parse("$_baseUrl/auctions").replace(queryParameters: queryParameters);

  try {
    final response = await http.get(
      url,
      // ===== Headerـەکە بەپێی بوونی تۆکن دادەنرێت =====
      headers: {
        'Accept': 'application/json',
        if (apiToken != null) 'Authorization': 'Bearer $apiToken',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      print("Failed to fetch auctions. Status: ${response.statusCode}, Body: ${response.body}");
    }
  } catch (e) {
    print("Error in getAuctions: $e");
  }
  return null;
}
  Future<Auction?> getAuctionDetails(int id, String? token) async {
    final url = Uri.parse("$_baseUrl/auctions/$id");
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return Auction.fromJson(json.decode(response.body));
      } else {
        print("Failed to fetch auction details. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getAuctionDetails: $e");
    }
    return null;
  }

  Future<bool> toggleWatchlist(int auctionId, String token) async {
    final url = Uri.parse("$_baseUrl/auctions/$auctionId/toggle-watchlist");
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error in toggleWatchlist: $e");
      return false;
    }
  }

  Future<List<Auction>?> getWatchlist(String token) async {
    final url = Uri.parse("$_baseUrl/watchlist");
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token: token),
      );
      if (response.statusCode == 200) {
        return auctionFromJson(response.body);
      } else {
        print("Failed to fetch watchlist. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getWatchlist: $e");
    }
    return null;
  }

  Future<List<Auction>?> getFeaturedAuctions() async {
    final url = Uri.parse("$_baseUrl/auctions/featured");
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        return auctionFromJson(response.body);
      } else {
        print("Failed to fetch featured auctions. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getFeaturedAuctions: $e");
    }
    return null;
  }

  Future<bool> placeBid(int auctionId, String amount, String token) async {
    final url = Uri.parse("$_baseUrl/auctions/$auctionId/bids");
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          ..._getHeaders(token: token),
        },
        body: json.encode({'amount': amount}),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Failed to place bid. Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      print("Error in placeBid: $e");
    }
    return false;
  }

  // ===== AUTHENTICATION METHODS =====
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse("$_baseUrl/login");
    try {
      print("Attempting login with email: $email");
      print("API URL: $url");
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: {'email': email, 'password': password},
      ).timeout(const Duration(seconds: 30));
      print("Login response status: ${response.statusCode}");
      print("Login response body: ${response.body}");
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Login failed. Status: ${response.statusCode}, Body: ${response.body}");
      }
    } on SocketException catch (e) {
      print("Network error in login: $e");
    } on TimeoutException catch (e) {
      print("Timeout error in login: $e");
    } catch (e) {
      print("Error in login: $e");
      if (e is FormatException) {
        print("JSON parsing error: ${e.message}");
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> register(Map<String, String> data) async {
    final url = Uri.parse("$_baseUrl/register");
    try {
      print("Attempting registration with data: ${data.toString()}");
      print("API URL: $url");
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: data,
      ).timeout(const Duration(seconds: 30));
      
      print("Registration response status: ${response.statusCode}");
      print("Registration response body: ${response.body}");
      if (response.statusCode == 201 || response.statusCode == 422) {
        return json.decode(response.body);
      } else {
        print("Registration failed. Status: ${response.statusCode}, Body: ${response.body}");
      }
    } on SocketException catch (e) {
      print("Network error in register: $e");
    } on TimeoutException catch (e) {
      print("Timeout error in register: $e");
    } catch (e) {
      print("Error in register: $e");
      if (e is FormatException) {
        print("JSON parsing error: ${e.message}");
      }
    }
    return null;
  }

  // ===== USER PROFILE METHODS =====
  Future<User?> updateUserProfile({
    required String token,
    required String name,
    required String email,
    required String phone,
    required String location,
    required String about,
    required String vendorTerms,
    File? photoFile,
  }) async {
    final url = Uri.parse("$_baseUrl/profile/update");
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(_getHeaders(token: token));
      
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['phone_number'] = phone;
      request.fields['location'] = location;
      request.fields['about'] = about;
      request.fields['vendor_terms'] = vendorTerms;
      
      if (photoFile != null) {
        request.files.add(await http.MultipartFile.fromPath('photo', photoFile.path));
      }

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        return User.fromJson(json.decode(responseBody));
      } else {
        print("Failed to update profile. Status: ${response.statusCode}, Body: $responseBody");
      }
    } catch (e) {
      print("Error in updateUserProfile: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getMyActivity(String token) async {
    final url = Uri.parse("$_baseUrl/profile/activity");
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token: token),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Failed to fetch activity. Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      print("Error in getMyActivity: $e");
    }
    return null;
  }

  Future<bool> applyToBeVendor(Map<String, String> data, String token) async {
    final url = Uri.parse("$_baseUrl/profile/apply-vendor");
    try {
      final response = await http.post(
        url, 
        headers: _getHeaders(token: token), 
        body: data
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error in applyToBeVendor: $e");
      return false;
    }
  }

  // ===== VENDOR METHODS =====
  Future<Map<String, dynamic>?> getVendorProfile(int vendorId, String? token) async {
    final url = Uri.parse("$_baseUrl/vendors/$vendorId");
    try {
      final response = await http.get(url, headers: _getHeaders(token: token));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Failed to fetch vendor profile. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getVendorProfile: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> toggleFollow(int vendorId, String token) async {
    final url = Uri.parse("$_baseUrl/vendors/$vendorId/toggle-follow");
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Failed to toggle follow. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in toggleFollow: $e");
    }
    return null;
  }

  Future<List<User>?> getFeaturedVendors() async {
    final url = Uri.parse("$_baseUrl/vendors/featured");
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((jsonUser) => User.fromJson(jsonUser)).toList();
      } else {
        print("Failed to fetch featured vendors. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getFeaturedVendors: $e");
    }
    return null;
  }

  // ===== ORDER METHODS =====
  Future<List<Order>?> getMyOrders(String token) async {
    final url = Uri.parse("$_baseUrl/profile/orders");
    try {
      final response = await http.get(url, headers: _getHeaders(token: token));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((d) => Order.fromJson(d)).toList();
      } else {
        print("Failed to fetch orders. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getMyOrders: $e");
    }
    return null;
  }

  Future<List<Order>?> getSoldAuctions(String token) async {
    final url = Uri.parse("$_baseUrl/profile/sold");
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token: token),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((jsonOrder) => Order.fromJson(jsonOrder)).toList();
      } else {
        print("Failed to fetch sold auctions. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getSoldAuctions: $e");
    }
    return null;
  }

  Future<Order?> updateOrderStatus(int orderId, String newStatus, String token) async {
    final url = Uri.parse("$_baseUrl/orders/$orderId/update-status");
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: {'status': newStatus},
      );
      if (response.statusCode == 200) {
        return Order.fromJson(json.decode(response.body));
      } else {
        print("Failed to update order status. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in updateOrderStatus: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getOrderPaymentDetails(int orderId, String token) async {
    final url = Uri.parse("$_baseUrl/orders/$orderId/payment-details");
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token: token),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Failed to fetch payment details. Status: ${response.statusCode}");
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
        headers: _getHeaders(token: token),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error in confirmPayment: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> scanOrder(String orderId, String token) async {
    final url = Uri.parse("$_baseUrl/driver/scan-order");
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: {'order_id': orderId},
      );
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) {
      print("Error in scanOrder: $e");
    }
    return null;
  }

  // ===== COMMENT METHODS =====
  Future<Comment?> postComment(int auctionId, String body, int? parentId, String token) async {
    final url = Uri.parse("$_baseUrl/auctions/$auctionId/comments");
    try {
      final response = await http.post(
        url,
        headers: {
          ..._getHeaders(token: token),
          'Content-Type': 'application/json',
        },
        body: json.encode({'body': body, 'parent_id': parentId}),
      );
      if (response.statusCode == 201) {
        return Comment.fromJson(json.decode(response.body));
      } else {
        print("Failed to post comment. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in postComment: $e");
    }
    return null;
  }

  // ===== CATEGORY METHODS =====
  Future<List<Category>?> getCategories() async {
    final url = Uri.parse("$_baseUrl/categories");
    try {
      final response = await http.get(url, headers: _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((d) => Category.fromJson(d)).toList();
      } else {
        print("Failed to fetch categories. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getCategories: $e");
    }
    return null;
  }

  // ===== NOTIFICATION METHODS =====
  Future<List<NotificationModel>?> getNotifications(String token) async {
    final url = Uri.parse("$_baseUrl/notifications");
    try {
      final response = await http.get(url, headers: _getHeaders(token: token));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData['data'];
        return data.map((item) => NotificationModel.fromJson(item)).toList();
      } else {
        print("Failed to fetch notifications. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getNotifications: $e");
    }
    return null;
  }

  Future<bool> markNotificationAsRead(String notificationId, String token) async {
    final url = Uri.parse("$_baseUrl/notifications/$notificationId/mark-as-read");
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print("Failed to mark notification as read. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in markNotificationAsRead: $e");
    }
    return false;
  }

  // ===== CHAT METHODS =====
  Future<int?> startOrGetConversation(int otherUserId, String token) async {
    final url = Uri.parse("$_baseUrl/chat/start/$otherUserId");
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['conversation_id'];
      } else {
        print("Failed to start conversation. Status: ${response.statusCode}");
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
        headers: _getHeaders(token: token),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> paginatedData = json.decode(response.body);
        final List<dynamic> data = paginatedData['data'];
        return data.map((d) => Message.fromJson(d)).toList();
      } else {
        print("Failed to fetch messages. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getMessages: $e");
    }
    return null;
  }

  Future<Message?> sendMessage(int conversationId, String body, String token) async {
    final url = Uri.parse("$_baseUrl/chat/$conversationId/messages");
    try {
      final response = await http.post(
        url,
        headers: {
          ..._getHeaders(token: token),
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({'body': body, 'type': 'text'}),
      );

      if (response.statusCode == 201) {
        return Message.fromJson(json.decode(response.body));
      } else {
        print("Failed to send message. Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      print("Error in sendMessage: $e");
    }
    return null;
  }

  Future<List<Conversation>?> getConversations(String token) async {
    final url = Uri.parse("$_baseUrl/chat/conversations");
    try {
      final response = await http.get(url, headers: _getHeaders(token: token));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((d) => Conversation.fromJson(d)).toList();
      } else {
        print("Failed to fetch conversations. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getConversations: $e");
    }
    return null;
  }

  Future<Message?> shareAuctionInChat(int conversationId, int auctionId, String token) async {
    final url = Uri.parse("$_baseUrl/chat/$conversationId/messages");
    final Map<String, dynamic> body = {
      'type': 'auction_share',
      'metadata': {
        'auction_id': auctionId,
      },
      'body': 'مەزاد هاوبەشی پێکرا'
    };

    try {
      final response = await http.post(
        url,
        headers: {
          ..._getHeaders(token: token),
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Message.fromJson(json.decode(response.body));
      } else {
        print("Failed to share auction. Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      print("Error in shareAuctionInChat: $e");
    }
    return null;
  }

  // ===== USER MANAGEMENT METHODS =====
  Future<Map<String, dynamic>?> searchUsers({
    required String role, 
    String? searchTerm, 
    String? token
  }) async {
    final uri = Uri.parse("$_baseUrl/explore/users").replace(
      queryParameters: {'role': role, 'search': searchTerm ?? ''}
    );
    
    try {
      final response = await http.get(uri, headers: _getHeaders(token: token));
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) {
      print("Error in searchUsers: $e");
    }
    return null;
  }

  Future<bool> toggleBlockUser(int userId, String token) async {
    final url = Uri.parse("$_baseUrl/users/$userId/toggle-block");
    try {
      final response = await http.post(url, headers: _getHeaders(token: token));
      return response.statusCode == 200;
    } catch (e) {
      print("Error in toggleBlockUser: $e");
      return false;
    }
  }

  Future<List<User>?> getBlockedUsers(String token) async {
    final url = Uri.parse("$_baseUrl/blocked-users");
    try {
      final response = await http.get(url, headers: _getHeaders(token: token));
      if (response.statusCode == 200) {
        final Map<String, dynamic> paginatedData = json.decode(response.body);
        final List<dynamic> data = paginatedData['data'];
        return data.map((d) => User.fromJson(d)).toList();
      } else {
        print("Failed to fetch blocked users. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getBlockedUsers: $e");
    }
    return null;
  }

  // ===== DRIVER METHODS =====
  Future<List<User>?> getDrivers(String token) async {
    final url = Uri.parse("$_baseUrl/drivers");
    try {
      final response = await http.get(url, headers: _getHeaders(token: token));
      if (response.statusCode == 200) {
        final Map<String, dynamic> paginatedData = json.decode(response.body);
        final List<dynamic> data = paginatedData['data'];
        return data.map((d) => User.fromJson(d)).toList();
      } else {
        print("Failed to fetch drivers. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getDrivers: $e");
    }
    return null;
  }

  Future<User?> createDriver(Map<String, String> data, String token) async {
    final url = Uri.parse("$_baseUrl/drivers");
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token: token),
        body: data,
      );
      if (response.statusCode == 201) {
        return User.fromJson(json.decode(response.body));
      } else {
        print("Failed to create driver. Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      print("Error in createDriver: $e");
    }
    return null;
  }

  // ===== FCM TOKEN METHODS =====
  Future<bool> updateFCMToken(String fcmToken, String apiToken) async {
    final url = Uri.parse("$_baseUrl/fcm-token");
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token: apiToken),
        body: {'fcm_token': fcmToken},
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        print("Failed to update FCM token. Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      print("Error in updateFCMToken: $e");
    }
    return false;
  }

  // ===== TOKEN MANAGEMENT =====
  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print("Error in getAuthToken: $e");
      return null;
    }
  }
Future<DriverDashboardStats?> getDriverDashboard(String token) async {
  final url = Uri.parse("$_baseUrl/driver/dashboard");
  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // 👇 لەوێ پێویستە دڵنیابیت structure چۆنە
      return DriverDashboardStats.fromJson(data);
    } else {
      print("Failed to fetch dashboard: ${response.statusCode}");
    }
  } catch (e) {
    print("Error in getDriverDashboard: $e");
  }
  return null;
}


Future<List<Order>?> getDriverOrders(String token) async {
  final url = Uri.parse("$_baseUrl/driver/orders");
  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((d) => Order.fromJson(d)).toList();
    } else {
      print("Failed to fetch orders: ${response.statusCode}");
    }
  } catch (e) {
    print("Error in getDriverOrders: $e");
  }
  return null;
}
Future<Order?> updateDriverOrderStatus(int orderId, String newStatus, String token) async {
  final url = Uri.parse("$_baseUrl/driver/orders/$orderId/status");
  print("--- Updating DRIVER order status ---");
  print("URL: $url");
  print("New Status: $newStatus");

  try {
    final response = await http.post(
      url,
      // ===== چارەسەرەکە لێرەدایە =====
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        // دڵنیادەبینەوە کە Content-Type دروستە
        'Content-Type': 'application/json; charset=UTF-8', 
      },
      // Laravel چاوەڕێی 'status' دەکات, نەک 'body'
      body: json.encode({'status': newStatus}), 
    );
    
    print("--- Update status response: ${response.statusCode} ---");
    if (response.statusCode != 200) {
      print("--- Update status error body: ${response.body} ---");
    }

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Order.fromJson(data);
    }
  } catch (e) {
    print("Error in updateDriverOrderStatus: $e");
  }
  return null;
}
Future<Order?> updateOrderStatusByVendor(int orderId, String newStatus, String token) async {
  final url = Uri.parse("$_baseUrl/orders/$orderId/status");
  try {
    final response = await http.post(
      url,
      headers: _getHeaders(token: token),
      body: json.encode({'status': newStatus}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Order.fromJson(data);
    } else {
      print("Failed to update order status: ${response.statusCode}");
    }
  } catch (e) {
    print("Error in updateOrderStatusByVendor: $e");
  }
  return null;
}

// ئەمە بۆ شۆفێرە
Future<Order?> updateOrderStatusByDriver(int orderId, String newStatus, String token) async {
  final url = Uri.parse("$_baseUrl/driver/orders/$orderId/status");
  try {
    final response = await http.post(
      url,
      headers: _getHeaders(token: token),
      body: json.encode({'status': newStatus}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Order.fromJson(data);
    } else {
      print("Failed to update order status: ${response.statusCode}");
    }
  } catch (e) {
    print("Error in updateOrderStatusByDriver: $e");
  }
  return null;
}

Future<List<User>?> getVendorMapLocations({String? token}) async {
  final url = Uri.parse("$_baseUrl/vendors/map-locations");
  print("--- Fetching vendor map locations from: $url ---");

  try {
    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    print("--- Vendor map locations response status: ${response.statusCode} ---");

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((jsonUser) => User.fromJson(jsonUser)).toList();
    } else {
      print("--- Failed to fetch vendor locations. Body: ${response.body} ---");
    }
  } catch (e) {
    print("!!! ERROR in getVendorMapLocations: $e");
  }

  return null;
}



Future<bool> handoverOrdersToDriver(List<int> orderIds, int driverId, String token) async {
    final url = Uri.parse("$_baseUrl/orders/handover-to-driver");
    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: json.encode({'order_ids': orderIds, 'driver_id': driverId}),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // Add this new method for creating social media posts
  Future<Map<String, dynamic>?> createPost({
    required String token,
    required String caption,
    required List<File> images,
  }) async {
    final url = Uri.parse("$_baseUrl/posts");
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(_getHeaders(token: token));
      request.fields['caption'] = caption;

      for (var i = 0; i < images.length; i++) {
        request.files.add(await http.MultipartFile.fromPath(
          'images[]', 
          images[i].path
        ));
      }

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        return json.decode(responseBody);
      } else {
        print("Failed to create post: $responseBody");
      }
    } catch (e) {
      print("Error in createPost: $e");
    }
    return null;
  }

  // 2. بۆ وەرگرتنی لیستی شۆفێرەکان
  Future<Map<String, dynamic>?> getProducts({
    required int page,
    String? searchTerm,
    int? categoryId,
  }) async {
    final queryParameters = {
      'page': page.toString(),
      if (searchTerm != null && searchTerm.isNotEmpty) 'search': searchTerm,
      if (categoryId != null) 'category': categoryId.toString(),
    };
    
    final url = Uri.parse("$_baseUrl/products").replace(queryParameters: queryParameters);
    print("Fetching products from: $url");
    try {
      final response = await http.get(url, headers: _getHeaders());
      print("Products API response status: ${response.statusCode}");
      print("Products API response body: ${response.body}");
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        print("Decoded products response: $decoded");
        return decoded;
      } else {
        print("Failed to fetch products. Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) { 
      print("Error in getProducts: $e"); 
    }
    return null;
  }

   Future<Product?> createProduct({
    required String token,
    required Map<String, String> data,
    required List<File> images,
  }) async {
    final url = Uri.parse("$_baseUrl/products");
    try {
      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(_getHeaders(token: token));
      request.fields.addAll(data);

      for (var imageFile in images) {
        request.files.add(await http.MultipartFile.fromPath('images[]', imageFile.path));
      }

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print("Product creation response status: ${response.statusCode}");
      print("Product creation response body: $responseBody");
      
      if (response.statusCode == 201) {
        return Product.fromJson(json.decode(responseBody));
      } else {
        print("Failed to create product. Status: ${response.statusCode}, Body: $responseBody");
      }
    } catch (e) { 
      print("Error in createProduct: $e"); 
    }
    return null;
  }

}
