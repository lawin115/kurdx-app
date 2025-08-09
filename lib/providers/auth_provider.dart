import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart'; // <-- importـی نوێ
import 'package:kurdpoint/services/notification_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/auction_model.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  String? _token;
  User? _user;
  Set<int> _watchlistIds = {};

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  User? get user => _user;

  get currentUser => null;
  bool isInWatchlist(int auctionId) => _watchlistIds.contains(auctionId);

  // ===== функцIAیەکی نوێی یارمەتیدەر =====
  Future<void> _onLoginSuccess() async {
    // دوای ئەوەی لۆگین سەرکەوتوو بوو، ئەم کارانە بکە
       await NotificationService().initialize(_token);
    await fetchWatchlist();
    await _registerDeviceForNotifications();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final response = await _apiService.login(email, password);
    if (response != null) {
      _token = response['token'];
      _user = User.fromJson(response['user']);
      await _storage.write(key: 'token', value: _token);
      await _storage.write(key: 'user', value: json.encode(response['user']));
      await _onLoginSuccess(); // <-- بانگکردنی функцIA نوێیەکە
      return true;
    }
    return false;
  }
  
  Future<bool> tryAutoLogin() async {
    final storedToken = await _storage.read(key: 'token');
    final storedUserJson = await _storage.read(key: 'user');
    if (storedToken != null && storedUserJson != null) {
      _token = storedToken;
      _user = User.fromJson(json.decode(storedUserJson));
      await _onLoginSuccess(); // <-- لێرەشدا بانگی بکە
      return true;
    }
    return false;
  }
  
  // ===== функцIAی سەرەکی بۆ تۆمارکردنی ئامێر =====
  Future<void> _registerDeviceForNotifications() async {
    if (_token == null) return;
    
    try {
      // داواکردنی ڕێگەپێدان لە بەکارهێنەر (بۆ iOS و ئەندرۆیدی نوێ گرنگە)
      await FirebaseMessaging.instance.requestPermission();
      
      // وەرگرتنی FCM Token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      
      if (fcmToken != null) {
        print("=========================================");
        print("========= My FCM Token is: ==========");
        print(fcmToken);
        print("=========================================");
        
        // ناردنی تۆکنەکە بۆ سێرڤەری Laravel
        await _apiService.updateFCMToken(fcmToken, _token!);
      } else {
        print("--- Could not get FCM token. ---");
      }

      // گوێگرتن لە نوێبوونەوەی تۆکن لە داهاتوودا
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        print("--- FCM Token refreshed. Sending new token to server... ---");
        _apiService.updateFCMToken(newToken, _token!);
      });
    } catch (e) {
      print("!!! An error occurred during notification setup: $e");
    }
  }
  
  Future<void> logout() async {
    _token = null;
    _user = null;
    _watchlistIds = {};
    await _storage.deleteAll();
    print("--- All data DELETED from secure storage on logout. ---");
    notifyListeners();
  }

  Future<void> fetchWatchlist() async {
    if (_token == null) return;
    final watchlist = await _apiService.getWatchlist(_token!);
    if (watchlist != null) {
      _watchlistIds = watchlist.map((auction) => auction.id).toSet();
    }
    notifyListeners();
  }

  // ===== چاکسازی لە updateUser =====
  void updateUser(User newUser) {
    _user = newUser;
    // پێویستە ئۆبجێکتەکە بکەین بە Map پێش encode کردن
    _storage.write(key: 'user', value: json.encode(newUser.toJson()));
    notifyListeners();
  }

    Future<void> _handleLoginSuccess() async {
    // وەرگرتنی FCM Token و ناردنی بۆ سێرڤەر
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null && _token != null) {
      print("FCM Token found: $fcmToken");
      await _apiService.updateFCMToken(fcmToken, _token!);
    }
    await fetchWatchlist();
    notifyListeners();
  }
 Future<void> loginWithData(Map<String, dynamic> data) async {
    print("--- Logging in with pre-fetched data... ---");
    
    _token = data['token'];
    _user = User.fromJson(data['user']);

    // دڵنیابوونەوە لەوەی داتاکان بە دروستی پاشەکەوت دەکرێن
    await _storage.write(key: 'token', value: _token);
    await _storage.write(key: 'user', value: json.encode(data['user']));
    
    print("--- Token and User SAVED successfully after registration. ---");

    // دوای لۆگین، لیستی چاودێری و FCM Token وەربگرە
    await fetchWatchlist();
    await _registerDeviceForNotifications(); // فرضاً این تابع از قبل تعریف شده است
    
    // ئاگاداری ویجێتەکان بکەرەوە کە دۆخی لۆگین گۆڕاوە
    notifyListeners();
  }
  Future<void> toggleWatchlist(int auctionId) async {
    if (_token == null) return;
    if (_watchlistIds.contains(auctionId)) {
      _watchlistIds.remove(auctionId);
    } else {
      _watchlistIds.add(auctionId);
    }
    notifyListeners();
    final success = await _apiService.toggleWatchlist(auctionId, _token!);
    if (!success) {
      // ئەگەر API هەڵەی دا، دۆخەکە بگەڕێنەرەوە
      if (_watchlistIds.contains(auctionId)) {
        _watchlistIds.remove(auctionId);
      } else {
        _watchlistIds.add(auctionId);
      }
      notifyListeners();
    }
  }
}