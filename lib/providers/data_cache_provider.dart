import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/auction_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class DataCacheProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Cache data
  List<Auction> _auctions = [];
  List<Order> _orders = [];
  List<User> _vendors = [];
  Map<String, dynamic> _categories = {};
  
  // Cache timestamps for expiry management
  DateTime? _auctionsLastFetch;
  DateTime? _ordersLastFetch;
  DateTime? _vendorsLastFetch;
  DateTime? _categoriesLastFetch;
  
  // Loading states
  bool _isLoadingAuctions = false;
  bool _isLoadingOrders = false;
  bool _isLoadingVendors = false;
  bool _isLoadingCategories = false;
  
  // Cache duration (2 minutes for more live feel like Instagram)
  static const Duration _cacheDuration = Duration(minutes: 2);
  
  // Getters
  List<Auction> get auctions => _auctions;
  List<Order> get orders => _orders;
  List<User> get vendors => _vendors;
  Map<String, dynamic> get categories => _categories;
  
  bool get isLoadingAuctions => _isLoadingAuctions;
  bool get isLoadingOrders => _isLoadingOrders;
  bool get isLoadingVendors => _isLoadingVendors;
  bool get isLoadingCategories => _isLoadingCategories;
  
  bool get isLoadingAny => _isLoadingAuctions || _isLoadingOrders || _isLoadingVendors || _isLoadingCategories;
  
  // Initialize and preload all data
  Future<void> initializeCache(String? token) async {
    print("🚀 Initializing data cache for fast app experience...");
    
    // Load cached data first for instant display
    await _loadCachedData();
    
    // Preload all data in parallel for maximum speed
    if (token != null) {
      await Future.wait([
        fetchAuctions(token, forceRefresh: false),
        fetchOrders(token, forceRefresh: false),
        fetchVendors(token, forceRefresh: false),
        fetchCategories(token, forceRefresh: false),
      ]);
    }
    
    print("✅ Data cache initialized successfully!");
  }
  
  // Load cached data from local storage
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load auctions from cache
      final auctionsJson = prefs.getString('cached_auctions');
      if (auctionsJson != null) {
        final auctionsList = json.decode(auctionsJson) as List;
        _auctions = auctionsList.map((a) => Auction.fromJson(a)).toList();
        
        final timestamp = prefs.getInt('auctions_timestamp');
        if (timestamp != null) {
          _auctionsLastFetch = DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      }
      
      // Load orders from cache (memory-only for now)
      // Skip persistent order caching to avoid serialization issues
      final timestamp = prefs.getInt('orders_timestamp');
      if (timestamp != null) {
        _ordersLastFetch = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      
      // Load vendors from cache
      final vendorsJson = prefs.getString('cached_vendors');
      if (vendorsJson != null) {
        final vendorsList = json.decode(vendorsJson) as List;
        _vendors = vendorsList.map((v) => User.fromJson(v)).toList();
        
        final timestamp = prefs.getInt('vendors_timestamp');
        if (timestamp != null) {
          _vendorsLastFetch = DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      }
      
      // Load categories from cache
      final categoriesJson = prefs.getString('cached_categories');
      if (categoriesJson != null) {
        _categories = json.decode(categoriesJson);
        
        final timestamp = prefs.getInt('categories_timestamp');
        if (timestamp != null) {
          _categoriesLastFetch = DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      }
      
      print("📦 Loaded cached data: ${_auctions.length} auctions, ${_orders.length} orders, ${_vendors.length} vendors");
      notifyListeners();
    } catch (e) {
      print("❌ Error loading cached data: $e");
    }
  }
  
  // Check if cache is expired
  bool _isCacheExpired(DateTime? lastFetch) {
    if (lastFetch == null) return true;
    return DateTime.now().difference(lastFetch) > _cacheDuration;
  }
  
  // Fetch auctions with caching
  Future<void> fetchAuctions(String token, {bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && !_isCacheExpired(_auctionsLastFetch) && _auctions.isNotEmpty) {
      print("📋 Using cached auctions (${_auctions.length} items)");
      return;
    }
    
    if (_isLoadingAuctions) return;
    
    _isLoadingAuctions = true;
    notifyListeners();
    
    try {
      final response = await _apiService.getAuctions(
        page: 1,
        limit: 100,
        liveOnly: false,
        apiToken: token,
      );
      
      if (response != null && response['data'] != null) {
        final auctionsList = response['data'] as List;
        _auctions = auctionsList.map((a) => Auction.fromJson(a)).toList();
        _auctionsLastFetch = DateTime.now();
        
        // Cache the data
        await _cacheAuctions();
        
        print("🎯 Fetched ${_auctions.length} auctions from API");
      }
    } catch (e) {
      print("❌ Error fetching auctions: $e");
    } finally {
      _isLoadingAuctions = false;
      notifyListeners();
    }
  }
  
  // Fetch orders with caching
  Future<void> fetchOrders(String token, {bool forceRefresh = false}) async {
    if (!forceRefresh && !_isCacheExpired(_ordersLastFetch) && _orders.isNotEmpty) {
      print("📦 Using cached orders (${_orders.length} items)");
      return;
    }
    
    if (_isLoadingOrders) return;
    
    _isLoadingOrders = true;
    notifyListeners();
    
    try {
      final fetchedOrders = await _apiService.getMyOrders(token);
      if (fetchedOrders != null) {
        _orders = fetchedOrders;
        _ordersLastFetch = DateTime.now();
        
        // Cache the data
        await _cacheOrders();
        
        print("📋 Fetched ${_orders.length} orders from API");
      }
    } catch (e) {
      print("❌ Error fetching orders: $e");
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }
  
  // Fetch vendors with caching
  Future<void> fetchVendors(String token, {bool forceRefresh = false}) async {
    if (!forceRefresh && !_isCacheExpired(_vendorsLastFetch) && _vendors.isNotEmpty) {
      print("👥 Using cached vendors (${_vendors.length} items)");
      return;
    }
    
    if (_isLoadingVendors) return;
    
    _isLoadingVendors = true;
    notifyListeners();
    
    try {
      final fetchedVendors = await _apiService.getFeaturedVendors();
      if (fetchedVendors != null) {
        _vendors = fetchedVendors;
        _vendorsLastFetch = DateTime.now();
        
        // Cache the data
        await _cacheVendors();
        
        print("👥 Fetched ${_vendors.length} vendors from API");
      }
    } catch (e) {
      print("❌ Error fetching vendors: $e");
    } finally {
      _isLoadingVendors = false;
      notifyListeners();
    }
  }
  
  // Fetch categories with caching
  Future<void> fetchCategories(String token, {bool forceRefresh = false}) async {
    if (!forceRefresh && !_isCacheExpired(_categoriesLastFetch) && _categories.isNotEmpty) {
      print("📂 Using cached categories (${_categories.length} items)");
      return;
    }
    
    if (_isLoadingCategories) return;
    
    _isLoadingCategories = true;
    notifyListeners();
    
    try {
      final fetchedCategories = await _apiService.getCategories();
      if (fetchedCategories != null) {
        _categories = {
          'categories': fetchedCategories.map((c) => c.toJson()).toList(),
        };
        _categoriesLastFetch = DateTime.now();
        
        // Cache the data
        await _cacheCategories();
        
        print("📂 Fetched ${fetchedCategories.length} categories from API");
      }
    } catch (e) {
      print("❌ Error fetching categories: $e");
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }
  
  // Cache auctions to local storage
  Future<void> _cacheAuctions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final auctionsJson = json.encode(_auctions.map((a) => a.toJson()).toList());
      await prefs.setString('cached_auctions', auctionsJson);
      await prefs.setInt('auctions_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print("❌ Error caching auctions: $e");
    }
  }
  
  // Cache orders to local storage (without requiring toJson)
  Future<void> _cacheOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // For now, just cache the timestamp to track when orders were last fetched
      // We'll keep orders in memory only to avoid serialization issues
      await prefs.setInt('orders_timestamp', DateTime.now().millisecondsSinceEpoch);
      print("📦 Orders timestamp cached (memory-only storage)");
    } catch (e) {
      print("❌ Error caching orders timestamp: $e");
    }
  }
  
  // Cache vendors to local storage
  Future<void> _cacheVendors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vendorsJson = json.encode(_vendors.map((v) => v.toJson()).toList());
      await prefs.setString('cached_vendors', vendorsJson);
      await prefs.setInt('vendors_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print("❌ Error caching vendors: $e");
    }
  }
  
  // Cache categories to local storage
  Future<void> _cacheCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = json.encode(_categories);
      await prefs.setString('cached_categories', categoriesJson);
      await prefs.setInt('categories_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print("❌ Error caching categories: $e");
    }
  }
  
  // Force refresh all data
  Future<void> refreshAllData(String token) async {
    print("🔄 Force refreshing all data...");
    
    await Future.wait([
      fetchAuctions(token, forceRefresh: true),
      fetchOrders(token, forceRefresh: true),
      fetchVendors(token, forceRefresh: true),
      fetchCategories(token, forceRefresh: true),
    ]);
    
    print("✅ All data refreshed successfully!");
  }
  
  // Clear all cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_auctions');
      await prefs.remove('auctions_timestamp');
      await prefs.remove('orders_timestamp'); // Only timestamp for orders
      await prefs.remove('cached_vendors');
      await prefs.remove('vendors_timestamp');
      await prefs.remove('cached_categories');
      await prefs.remove('categories_timestamp');
      
      _auctions.clear();
      _orders.clear();
      _vendors.clear();
      _categories.clear();
      
      _auctionsLastFetch = null;
      _ordersLastFetch = null;
      _vendorsLastFetch = null;
      _categoriesLastFetch = null;
      
      notifyListeners();
      print("🗑️ Cache cleared successfully");
    } catch (e) {
      print("❌ Error clearing cache: $e");
    }
  }
  
  // Add new auction to cache
  void addAuctionToCache(Auction auction) {
    _auctions.insert(0, auction);
    _cacheAuctions();
    notifyListeners();
  }
  
  // Update auction in cache
  void updateAuctionInCache(Auction updatedAuction) {
    final index = _auctions.indexWhere((a) => a.id == updatedAuction.id);
    if (index != -1) {
      _auctions[index] = updatedAuction;
      _cacheAuctions();
      notifyListeners();
    }
  }
  
  // Remove auction from cache
  void removeAuctionFromCache(int auctionId) {
    _auctions.removeWhere((a) => a.id == auctionId);
    _cacheAuctions();
    notifyListeners();
  }
  
  // Get cached auction by ID
  Auction? getCachedAuction(int auctionId) {
    try {
      return _auctions.firstWhere((a) => a.id == auctionId);
    } catch (e) {
      return null;
    }
  }
  
  // Search auctions in cache
  List<Auction> searchAuctions(String query) {
    if (query.isEmpty) return _auctions;
    
    return _auctions.where((auction) {
      return auction.title.toLowerCase().contains(query.toLowerCase()) ||
             auction.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }
  
  // Filter auctions by category
  List<Auction> filterAuctionsByCategory(String category) {
    if (category.isEmpty || category.toLowerCase() == 'all') return _auctions;
    
    return _auctions.where((auction) {
      return auction.category?.name.toLowerCase() == category.toLowerCase();
    }).toList();
  }
  
  // Check if any data is available in cache
  bool get hasAnyData => _auctions.isNotEmpty || _orders.isNotEmpty || _vendors.isNotEmpty;
  
  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'auctions': _auctions.length,
      'orders': _orders.length,
      'vendors': _vendors.length,
      'categories': _categories.length,
      'lastUpdated': {
        'auctions': _auctionsLastFetch?.toIso8601String(),
        'orders': _ordersLastFetch?.toIso8601String(),
        'vendors': _vendorsLastFetch?.toIso8601String(),
        'categories': _categoriesLastFetch?.toIso8601String(),
      },
    };
  }
  
  // Instagram-style instant loading - prioritize display over freshness
  Future<void> preloadForInstantDisplay(String? token) async {
    print("📱 Instagram-style preloading for instant display...");
    
    // Load cached data immediately for instant display
    await _loadCachedData();
    
    // Notify listeners immediately so UI shows cached data
    notifyListeners();
    
    if (token != null) {
      // Start background refresh without blocking UI
      _backgroundRefresh(token);
    }
  }
  
  // Background refresh without blocking UI
  void _backgroundRefresh(String token) {
    // Use separate method to avoid blocking main thread
    Future.microtask(() async {
      try {
        // Fetch fresh data in background
        await Future.wait([
          backgroundFetchAuctions(token),
          _backgroundFetchOrders(token),
          _backgroundFetchVendors(token),
          _backgroundFetchCategories(token),
        ]);
        print("✨ Background refresh completed");
      } catch (e) {
        print("❌ Background refresh error: $e");
      }
    });
  }
  
  // Background fetch methods that don't block UI - made public for instant access
  Future<void> backgroundFetchAuctions(String token) async {
    if (_isCacheExpired(_auctionsLastFetch)) {
      try {
        final response = await _apiService.getAuctions(
          page: 1,
          limit: 100,
          liveOnly: false,
          apiToken: token,
        );
        
        if (response != null && response['data'] != null) {
          final auctionsList = response['data'] as List;
          _auctions = auctionsList.map((a) => Auction.fromJson(a)).toList();
          _auctionsLastFetch = DateTime.now();
          await _cacheAuctions();
          notifyListeners(); // Update UI with fresh data
        }
      } catch (e) {
        print("❌ Background auction fetch error: $e");
      }
    }
  }
  
  Future<void> _backgroundFetchOrders(String token) async {
    if (_isCacheExpired(_ordersLastFetch)) {
      try {
        final fetchedOrders = await _apiService.getMyOrders(token);
        if (fetchedOrders != null) {
          _orders = fetchedOrders;
          _ordersLastFetch = DateTime.now();
          await _cacheOrders();
          notifyListeners(); // Update UI with fresh data
        }
      } catch (e) {
        print("❌ Background orders fetch error: $e");
      }
    }
  }
  
  Future<void> _backgroundFetchVendors(String token) async {
    if (_isCacheExpired(_vendorsLastFetch)) {
      try {
        final fetchedVendors = await _apiService.getFeaturedVendors();
        if (fetchedVendors != null) {
          _vendors = fetchedVendors;
          _vendorsLastFetch = DateTime.now();
          await _cacheVendors();
          notifyListeners(); // Update UI with fresh data
        }
      } catch (e) {
        print("❌ Background vendors fetch error: $e");
      }
    }
  }
  
  Future<void> _backgroundFetchCategories(String token) async {
    if (_isCacheExpired(_categoriesLastFetch)) {
      try {
        final fetchedCategories = await _apiService.getCategories();
        if (fetchedCategories != null) {
          _categories = {
            'categories': fetchedCategories.map((c) => c.toJson()).toList(),
          };
          _categoriesLastFetch = DateTime.now();
          await _cacheCategories();
          notifyListeners(); // Update UI with fresh data
        }
      } catch (e) {
        print("❌ Background categories fetch error: $e");
      }
    }
  }
}