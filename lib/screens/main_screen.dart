// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:kurdpoint/screens/driver_scan_screen.dart';
import 'package:kurdpoint/screens/explore_screen.dart';
import 'package:kurdpoint/screens/sold_auctions_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import './auction_list_screen.dart';
import './profile_screen.dart';
import './notifications_screen.dart';
import './add_auction_screen.dart';
import '../auction_detail_screen.dart';
import './my_orders_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _initializeData();

  }

  void _initializeData() {
    Future.delayed(Duration.zero, () {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        Provider.of<NotificationProvider>(context, listen: false).fetchNotifications(token);
      }
    });
  }

  void _openScanner() async {
    final orderId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (ctx) => const DriverScanScreen()),
    );
  }
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isVendor = authProvider.user?.role == 'vendor';
     final isDriver = Provider.of<AuthProvider>(context).user?.role == 'driver';
    // ===== لیستی لاپەڕەکان بەپێی ڕۆڵ =====
    final List<Widget> pages = [
      const AuctionListScreen(), // Index 0
      const MyOrdersScreen(),      // Index 1
      if (isVendor) const AddAuctionScreen(), // Index 2 (if vendor)
      if (isVendor) const SoldAuctionsScreen(),
     const ExploreScreen(),      // لاپەڕەی دووەم (Index 1) - نوێ!         
      const ProfileScreen(),       // Index 3 or 4
    ];

    // چارەسەری index کاتێک ڕۆڵ دەگۆڕدرێت
    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      // ===== گۆڕانکاری سەرەکی لێرەدایە =====
      // extendBody وا دەکات bodyـی Scaffold بچێتە ژێر NavigationBar
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      floatingActionButton: isDriver 
          ? FloatingActionButton(
              onPressed: _openScanner,
              child: const Icon(Icons.qr_code_scanner),
            )
          : null, // ئەگər شۆفێر نەبوو, دوگمەکە پیشان مەدە
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // ===== دیزاینی نوێی Bottom Navigation Bar =====
      bottomNavigationBar: _buildCustomBottomNavBar(isVendor, pages.length),
    );
  }

  Widget _buildCustomBottomNavBar(bool isVendor, int pageCount) {
    final theme = Theme.of(context);
    
    // دروستکردنی لیستی ئایکۆنەکان بە شێوەی داینامیک
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.favorite_border), activeIcon: Icon(Icons.favorite), label: 'Watchlist'), // Assuming MyOrders is Watchlist
       const BottomNavigationBarItem(icon: Icon(Icons.search), activeIcon: Icon(Icons.search_outlined), label: 'Watchlist'), // Assuming MyOrders is Watchlist
      if (isVendor) const BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), activeIcon: Icon(Icons.add_box), label: 'Add'),
       if (isVendor)const BottomNavigationBarItem(icon: Icon(Icons.sell_outlined), activeIcon: Icon(Icons.sell), label: 'sell'),
      const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
    ];
    
    // دڵنیابوونەوە لەوەی ژمارەی ئایکۆن و لاپەڕەکان وەک یەکن
    if(items.length != pageCount) {
        // This is a failsafe, should ideally not happen  =\
        // Let's rebuild the items list based on page list logic.
        items = [
            const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            const BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: 'Won'),
             const BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.emoji_events), label: 'Won'),
            if (isVendor) const BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), activeIcon: Icon(Icons.add_box), label: 'Add'),
             if (isVendor) const BottomNavigationBarItem(icon: Icon(Icons.sell_outlined), activeIcon: Icon(Icons.sell), label: 'Alerts'),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ];
    }
    
    return Container(
      // دیزاینی چوارچێوەکە
      margin: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      // ClipRRect بۆ خڕکردنی گۆشەکانی BottomNavigationBar
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BottomNavigationBar(
          items: items,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          
          // ستایلی مۆدێرن
          type: BottomNavigationBarType.fixed, // بۆ ئەوەی هەموو labelـەکان پیشان بدرێن
          backgroundColor: Colors.transparent, // ڕەنگی پشتەوەی Container بەکاردێت
          elevation: 0, // سێبەرەکە لە Container وەردەگرین
          
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.grey[500],
          
          showSelectedLabels: false, // شاردنەوەی نووسین
          showUnselectedLabels: false,
        ),
      ),
    );
  }
}