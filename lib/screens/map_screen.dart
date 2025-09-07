// lib/screens/map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:maps_launcher/maps_launcher.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import './vendor_profile_screen.dart';
import '../providers/auth_provider.dart'; // importـی پێویست
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;


// Modern Color Palette - Consistent with your app
const Color kPrimaryColor = Color(0xFF6366F1); // Indigo
const Color kSecondaryColor = Color(0xFF8B5CF6); // Purple
const Color kAccentColor = Color(0xFF06D6A0); // Emerald
const Color kSurfaceColor = Color(0xFFF8FAFC); // Slate-50
const Color kTextPrimary = Color(0xFF0F172A); // Slate-900
const Color kTextSecondary = Color(0xFF64748B); // Slate-500
const Color kBorderColor = Color(0xFFE2E8F0); // Slate-200
const Color kWarningColor = Color(0xFFF59E0B); // Amber
const Color kDangerColor = Color(0xFFEF4444); // Red
const Color kSuccessColor = Color(0xFF10B981); // Emerald
const Color kInfoColor = Color(0xFF3B82F6); // Blue
const Color kDarkOverlay = Color(0x99000000); // 60% black overlay

// Enhanced route fetching with distance, duration and full route data
class RouteInfo {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMinutes;
  final String distanceText;
  final String durationText;
  final List<RouteStep> steps;

  RouteInfo({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.distanceText,
    required this.durationText,
    required this.steps,
  });
}

class RouteStep {
  final String instruction;
  final double distance;
  final double duration;
  final String maneuver;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuver,
  });
}

Future<RouteInfo?> fetchRouteWithDetails(LatLng start, LatLng end) async {
  final url = Uri.parse(
    'https://router.project-osrm.org/route/v1/driving/'
    '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
    '?overview=full&geometries=geojson&steps=true&annotations=true',
  );

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Check if routes exist
      if (data['routes'] == null || (data['routes'] as List).isEmpty) {
        debugPrint('No routes found in response');
        return null;
      }
      
      final route = data['routes'][0];
      
      // Extract coordinates safely
      final geometry = route['geometry'];
      if (geometry == null || geometry['coordinates'] == null) {
        debugPrint('No geometry coordinates found');
        return null;
      }
      
      final coords = geometry['coordinates'] as List;
      final points = coords.map((c) => LatLng(c[1], c[0])).toList();
      
      // Extract distance and duration with safe type conversion
      final distanceMeters = _safeToDouble(route['distance']) ?? 0.0;
      final durationSeconds = _safeToDouble(route['duration']) ?? 0.0;
      
      final distanceKm = distanceMeters / 1000;
      final durationMinutes = (durationSeconds / 60);
      
      // Format text
      final distanceText = distanceKm < 1 
          ? '${distanceMeters.round()} m'
          : '${distanceKm.toStringAsFixed(1)} km';
      
      final durationText = durationMinutes < 60
          ? '${durationMinutes.round()} min'
          : '${(durationMinutes / 60).floor()}h ${durationMinutes.round() % 60}min';
      
      // Extract steps safely
      final legs = route['legs'] as List? ?? [];
      final steps = <RouteStep>[];
      
      for (final leg in legs) {
        final legSteps = leg['steps'] as List? ?? [];
        for (final step in legSteps) {
          if (step['maneuver'] != null) {
            steps.add(RouteStep(
              instruction: step['maneuver']['type']?.toString() ?? 'continue',
              distance: _safeToDouble(step['distance']) ?? 0.0,
              duration: _safeToDouble(step['duration']) ?? 0.0,
              maneuver: step['maneuver']['modifier']?.toString() ?? 'straight',
            ));
          }
        }
      }
      
      return RouteInfo(
        points: points,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        distanceText: distanceText,
        durationText: durationText,
        steps: steps,
      );
    } else {
      debugPrint('Route API error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    debugPrint('Route fetch error: $e');
  }
  return null;
}

// Helper function to safely convert to double
double? _safeToDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with TickerProviderStateMixin {
  
  final MapController _mapController = MapController();
  final ApiService _apiService = ApiService();
  // Animation Controllers
  late AnimationController _loadingController;
  late AnimationController _markerController;
  late AnimationController _fabController;
  late Animation<double> _loadingAnimation;
  late Animation<double> _markerAnimation;
  late Animation<double> _fabAnimation;

  List<User> _vendors = [];
  Position? _currentPosition;
  bool _isLoading = false; // Changed to false for instant loading
  bool _locationPermissionGranted = false;
  User? _selectedVendor;
  String _currentMapStyle = 'light';
  List<LatLng> _routePoints = [];
  RouteInfo? _currentRoute;
  bool _showingDirections = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Snapchat-style instant loading - start everything in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchVendorsInBackground();
      _showMapTips();
    });
  }

  void _showMapTips() {
    // Show tips only once per session
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _vendors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('کرتە بکە لەسەر فرۆشیارێک بۆ ڕێنمایی'),
            backgroundColor: kPrimaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }
  
void _openDirections(double lat, double lng) {
  MapsLauncher.launchCoordinates(lat, lng, 'Vendor Location');
}
  void _initializeAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _markerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    _markerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _markerController, curve: Curves.elasticOut),
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack),
    );

    _loadingController.repeat();
    
    // Add a slight delay before showing FABs for smoother entrance
    Future.delayed(const Duration(milliseconds: 500), () {
      _fabController.forward();
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _markerController.dispose();
    _fabController.dispose();
    super.dispose();
  }

void _drawRouteToVendor(User vendor) async {
  if (_currentPosition == null || vendor.latitude == null || vendor.longitude == null) {
    _showErrorSnackBar("شوێن یان ناونیشانی فرۆشیار نییە");
    return;
  }

  final start = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
  final end = LatLng(vendor.latitude!, vendor.longitude!);

  try {
    // Show loading indicator for route calculation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            const Text('دەستپێکردنی ڕێنمایی...'),
          ],
        ),
        backgroundColor: kPrimaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );

    final routeInfo = await fetchRouteWithDetails(start, end);
    if (mounted && routeInfo != null && routeInfo.points.isNotEmpty) {
      setState(() {
        _routePoints = routeInfo.points;
        _currentRoute = routeInfo;
        _showingDirections = true;
      });
      
      // Show route information
      _showRouteInformation(routeInfo, vendor);
      
      // Fit map to show entire route
      _fitMapToRoute();
      
      HapticFeedback.lightImpact();
      
      // Hide loading snackbar and show success
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('ڕێنمایی ئامادەیە - ${routeInfo.distanceText}, ${routeInfo.durationText}'),
            ],
          ),
          backgroundColor: kSuccessColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Fallback: create simple straight line route
      if (mounted) {
        setState(() {
          _routePoints = [start, end];
          _showingDirections = true;
          // Create basic route info with calculated distance
          final distance = Geolocator.distanceBetween(
            start.latitude, start.longitude,
            end.latitude, end.longitude,
          );
          final distanceKm = distance / 1000;
          final estimatedTime = (distanceKm * 2); // Rough estimate: 2 min per km
          
          _currentRoute = RouteInfo(
            points: [start, end],
            distanceKm: distanceKm,
            durationMinutes: estimatedTime,
            distanceText: distanceKm < 1 
                ? '${distance.round()} m'
                : '${distanceKm.toStringAsFixed(1)} km',
            durationText: estimatedTime < 60
                ? '${estimatedTime.round()} min'
                : '${(estimatedTime / 60).floor()}h ${estimatedTime.round() % 60}min',
            steps: [],
          );
        });
        
        _fitMapToRoute();
        HapticFeedback.lightImpact();
        
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('ڕێنمایی سادە دەستەبەرە'),
              ],
            ),
            backgroundColor: kWarningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showErrorSnackBar("هەڵە لە بەدەستهێنانی ڕێنمایی: ${e.toString()}");
    }
  }
}

void _showRouteInformation(RouteInfo routeInfo, User vendor) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _buildRouteInfoSheet(routeInfo, vendor),
  );
}

void _fitMapToRoute() {
  if (_routePoints.isEmpty) return;
  
  // Calculate bounds with padding
  double minLat = double.infinity;
  double maxLat = double.negativeInfinity;
  double minLng = double.infinity;
  double maxLng = double.negativeInfinity;
  
  for (final point in _routePoints) {
    if (point.latitude < minLat) minLat = point.latitude;
    if (point.latitude > maxLat) maxLat = point.latitude;
    if (point.longitude < minLng) minLng = point.longitude;
    if (point.longitude > maxLng) maxLng = point.longitude;
  }
  
  // Add padding to bounds
  final latPadding = (maxLat - minLat) * 0.1;
  final lngPadding = (maxLng - minLng) * 0.1;
  
  minLat -= latPadding;
  maxLat += latPadding;
  minLng -= lngPadding;
  maxLng += lngPadding;
  
  final bounds = LatLngBounds(
    LatLng(minLat, minLng),
    LatLng(maxLat, maxLng),
  );
  
  // Animate to fit bounds with padding
  _mapController.fitCamera(
    CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.all(80),
    ),
    // duration: const Duration(milliseconds: 800),
    // curve: Curves.easeInOut,
  );
}

// Professional map interaction methods
void _onMapTap(TapPosition tapPosition, LatLng point) {
  // Close any open vendor info when tapping on map
  if (_selectedVendor != null) {
    setState(() {
      _selectedVendor = null;
    });
  }
}

void _onMapLongPress(TapPosition tapPosition, LatLng point) {
  // Show context menu on long press
  showModalBottomSheet(
    context: context,
    builder: (context) => _buildMapContextMenu(point),
  );
}

Widget _buildMapContextMenu(LatLng point) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: kBorderColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'هەڵبژاردن',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: Icon(Icons.place, color: kPrimaryColor),
          title: const Text('ڕێنمایی بۆ ئەم شوێنە'),
          onTap: () {
            Navigator.pop(context);
            // TODO: Implement navigation to custom point
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('ڕێنمایی بۆ شوێنی دیاریکراو بەردەست نییە'),
                backgroundColor: kInfoColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.share_location, color: kAccentColor),
          title: const Text('هاوبەشکردنی شوێن'),
          onTap: () {
            Navigator.pop(context);
            // TODO: Implement location sharing
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('هاوبەشکردنی شوێن بەردەست نییە'),
                backgroundColor: kInfoColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
        ),
      ],
    ),
  );
}

void _clearRoute() {
  setState(() {
    _routePoints.clear();
    _currentRoute = null;
    _showingDirections = false;
  });
}

  // Background fetch for instant loading like Snapchat
  Future<void> _fetchVendorsInBackground() async {
    // Start location and vendor fetching in parallel for instant loading
    _getCurrentLocationSilently();
    
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final vendors = await _apiService.getVendorMapLocations(token: token);
      
      if (mounted && vendors != null) {
        setState(() {
          _vendors = vendors;
        });
        
        // Animate markers after loading - check if controller is still valid
        if (_markerController.isDismissed || _markerController.isCompleted) {
          _markerController.forward();
        }
      }
    } catch (e) {
      debugPrint('Background vendor fetch error: $e');
    }
    
    // Animate floating buttons - check if controller is still valid
    if (_fabController.isDismissed || _fabController.isCompleted) {
      _fabController.forward();
    }
  }
  
  // Silent location fetch without UI blocking
  Future<void> _getCurrentLocationSilently() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _locationPermissionGranted = true;
        });
        
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          15.0,
        );
      }
    } catch (e) {
      // Silently handle errors without showing dialogs
      debugPrint('Location error: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermanentlyDeniedDialog();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _locationPermissionGranted = true;
        });
        
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          15.0,
        );
        
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('خەتایەک لە وەرگرتنی شوێنەکەتدا ڕوویدا');
      }
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: kWarningColor),
            const SizedBox(width: 12),
            Text('خزمەتگوزاری شوێن', style: TextStyle(color: kTextPrimary)),
          ],
        ),
        content: Text(
          'تکایە خزمەتگوزاری شوێن چالاک بکە بۆ بینینی شوێنەکەت لەسەر نەخشە',
          style: TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('باشە', style: TextStyle(color: kPrimaryColor)),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.location_disabled, color: kDangerColor),
            const SizedBox(width: 12),
            Text('مۆڵەتی شوێن', style: TextStyle(color: kTextPrimary)),
          ],
        ),
        content: Text(
          'ئەم ئەپە پێویستی بە مۆڵەتی شوێنە بۆ پیشاندانی فرۆشیارەکانی نزیکت',
          style: TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('دواتر', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _getCurrentLocation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('هەوڵبدەرەوە'),
          ),
        ],
      ),
    );
  }

  void _showPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.settings, color: kWarningColor),
            const SizedBox(width: 12),
            Text('ڕێکخستنەکان', style: TextStyle(color: kTextPrimary)),
          ],
        ),
        content: Text(
          'مۆڵەتی شوێن بە تەواوی ڕەتکراوەتەوە. تکایە لە ڕێکخستنەکاندا چالاکی بکە',
          style: TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('پاشگەز', style: TextStyle(color: kTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('ڕێکخستنەکان'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: kDangerColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _toggleMapStyle() {
    setState(() {
      _currentMapStyle = _currentMapStyle == 'light' ? 'dark' : 'light';
    });
    HapticFeedback.lightImpact();
  }

  String _getTileUrl() {
    switch (_currentMapStyle) {
      case 'dark':
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      default:
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildModernAppBar(),
      body: Stack(
        children: [
          _buildMap(),
          // Removed loading overlay for instant display
          _buildTopControls(),
          _buildBottomSheet(),
          // Route info overlay when directions are showing
          if (_showingDirections && _currentRoute != null)
            _buildRouteInfoOverlay(),
        ],
      ),
      floatingActionButton: _buildFloatingButtons(),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
   
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
     
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map, color: kPrimaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Map X',
              style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(_currentMapStyle == 'light' ? Icons.dark_mode : Icons.light_mode, color: kTextPrimary),
            onPressed: _toggleMapStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(36.1911, 44.0092), // Default Hewlêr
        initialZoom: 12.0,
        minZoom: 5.0,
        maxZoom: 19.0,
        backgroundColor: kSurfaceColor,
        onTap: _onMapTap,
        onLongPress: _onMapLongPress,
      ),
      children: [
        TileLayer(
          urlTemplate: _getTileUrl(),
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.buyx',
          retinaMode: true,
          // Optimizations for faster loading like Snapchat
          maxNativeZoom: 18,
          maxZoom: 22,
        ),
        MarkerLayer(
          markers: [
            ..._vendors.asMap().entries.map((entry) {
              final index = entry.key;
              final vendor = entry.value;
              return Marker(
                point: LatLng(vendor.latitude ?? 0, vendor.longitude ?? 0),
                width: 80,
                height: 80,
                child: AnimatedBuilder(
                  animation: _markerAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _markerAnimation.value,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showVendorInfo(vendor);
                        },
                        child: _buildModernMarker(vendor, index),
                      ),
                    );
                  },
                ),
              );
            }),
            if (_currentPosition != null)
              Marker(
                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                width: 60,
                height: 60,
                child: _buildCurrentLocationMarker(),
              ),
          ],
        ),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                strokeWidth: 6,
                color: kPrimaryColor,
                borderStrokeWidth: 2,
                borderColor: Colors.white,
                gradientColors: [kPrimaryColor, kSecondaryColor, kAccentColor],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildModernMarker(User vendor, int index) {
    final isSelected = _selectedVendor?.id == vendor.id;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isSelected ? 65 : 55,
                  height: isSelected ? 65 : 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [kAccentColor, kSuccessColor]
                          : [kPrimaryColor, kSecondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isSelected ? kAccentColor : kPrimaryColor).withOpacity(0.5),
                        blurRadius: isSelected ? 20 : 15,
                        offset: const Offset(0, 6),
                        spreadRadius: isSelected ? 3 : 0,
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: (vendor.profilePhotoUrl != null && vendor.profilePhotoUrl!.isNotEmpty && !vendor.profilePhotoUrl!.contains('null'))
                          ? CachedNetworkImage(
                              imageUrl: vendor.profilePhotoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Icon(Icons.store, color: Colors.white),
                              errorWidget: (context, url, error) => Icon(Icons.store, color: Colors.white),
                            )
                          : Icon(Icons.store, color: Colors.white),
                    ),
                  ),
                ),
                // Pulse indicator for selected vendor
                if (isSelected)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: kAccentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kAccentColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentLocationMarker() {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing circle
            Container(
              width: 50 + (30 * _loadingAnimation.value),
              height: 50 + (30 * _loadingAnimation.value),
              decoration: BoxDecoration(
                color: kAccentColor.withOpacity(0.4 * (1 - _loadingAnimation.value)),
                shape: BoxShape.circle,
              ),
            ),
            // Middle pulsing circle
            Container(
              width: 40 + (20 * _loadingAnimation.value),
              height: 40 + (20 * _loadingAnimation.value),
              decoration: BoxDecoration(
                color: kAccentColor.withOpacity(0.3 * (1 - _loadingAnimation.value)),
                shape: BoxShape.circle,
              ),
            ),
            // Main marker with shadow
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: kAccentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: kAccentColor.withOpacity(0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 3),
              const SizedBox(height: 20),
              Text(
                'بارکردنی فرۆشیارەکان...',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfoOverlay() {
    return Positioned(
      top: 120,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white.withOpacity(0.95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryColor, kSecondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.navigation, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ڕێنمایی بۆ ${_selectedVendor?.name ?? "فرۆشیار"}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.straighten, size: 16, color: kTextSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _currentRoute!.distanceText,
                        style: TextStyle(
                          fontSize: 13,
                          color: kTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: kTextSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _currentRoute!.durationText,
                        style: TextStyle(
                          fontSize: 13,
                          color: kTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryColor.withOpacity(0.1), kSecondaryColor.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: () => _showRouteInformation(_currentRoute!, _selectedVendor!),
                icon: Icon(Icons.info_outline, color: kPrimaryColor, size: 22),
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 100,
      right: 16,
      child: Column(
        children: [
          _buildControlButton(
            Icons.search,
            () {
              // Add search functionality
              _showSearchDialog();
            },
            tooltip: 'گەڕان',
          ),
          const SizedBox(height: 16),
          _buildControlButton(
            Icons.filter_list,
            () {
              // Add filter functionality
              _showFilterDialog();
            },
            tooltip: 'فلتەر',
          ),
          const SizedBox(height: 16),
          _buildControlButton(
            Icons.layers,
            _toggleMapStyle,
            tooltip: 'ستایلی نەخشە',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed, {String? tooltip}) {
    final button = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: kTextPrimary, size: 24),
        onPressed: onPressed,
        splashRadius: 24,
      ),
    );
    
    return tooltip != null
        ? Tooltip(
            message: tooltip,
            child: button,
          )
        : button;
  }

  Widget _buildBottomSheet() {
    if (_selectedVendor == null) return const SizedBox();

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.25,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildVendorHeader(_selectedVendor!),
                    const SizedBox(height: 20),
                    _buildActionButtons(_selectedVendor!),
                    
                  ],
                  
                ),
                
              ),
              
            ],
           
          ),
          
        );
        
      },
      
    );
    
  }

  Widget _buildVendorHeader(User vendor) {
    return Row(
      children: [
        Hero(
          tag: 'vendor-map-${vendor.id}',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kPrimaryColor, kSecondaryColor],
              ),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white,
                backgroundImage: vendor.profilePhotoUrl != null
                    ? NetworkImage(vendor.profilePhotoUrl!)
                    : null,
                child: vendor.profilePhotoUrl == null
                    ? Icon(Icons.store, size: 30, color: kPrimaryColor)
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vendor.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: kTextSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      vendor.location ?? 'ناونیشان دیارینەکراوە',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kSuccessColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: kSuccessColor),
                    const SizedBox(width: 4),
                    Text(
                      'پەسەندکراو',
                      style: TextStyle(
                        color: kSuccessColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(User vendor) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kPrimaryColor, kSecondaryColor]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _selectedVendor = null);
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          VendorProfileScreen(vendorId: vendor.id),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: animation.drive(Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          )),
                          child: child,
                        );
                      },
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'بینینی پرۆفایل',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kAccentColor),
          ),
          child: IconButton(
            icon: Icon(Icons.directions, color: kAccentColor, size: 24),
            onPressed: () {
    _drawRouteToVendor(vendor); // ← ئەمە هێڵی شین بۆ Map زیاد دەکات
  },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingButtons() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clear route button (show only when directions are active)
              if (_showingDirections) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kDangerColor, Colors.redAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kDangerColor.withOpacity(0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: 'clearRoute',
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    onPressed: _clearRoute,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
              
              // Map style button
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kSecondaryColor, kPrimaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  heroTag: 'style',
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  onPressed: _toggleMapStyle,
                  child: Icon(
                    _currentMapStyle == 'light' ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              
              // Location button with enhanced design
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kAccentColor, kSuccessColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kAccentColor.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  heroTag: 'location',
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  onPressed: _getCurrentLocation,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
              
          ),
        );
      },
    );
  }

  void _showVendorInfo(User vendor) {
    setState(() => _selectedVendor = vendor);
    HapticFeedback.lightImpact();
  }

  Widget _buildRouteInfoSheet(RouteInfo routeInfo, User vendor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.98)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 16, bottom: 20),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryColor, kSecondaryColor],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with vendor info
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kPrimaryColor, kSecondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kPrimaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipOval(
                          child: vendor.profilePhotoUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: vendor.profilePhotoUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Icon(Icons.store, color: Colors.white),
                                  errorWidget: (context, url, error) => Icon(Icons.store, color: Colors.white),
                                )
                              : Icon(Icons.store, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ڕێنمایی بۆ ${vendor.name}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vendor.location ?? 'ناونیشان دیارینەکراوە',
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 28),
                
                // Distance and time info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryColor.withOpacity(0.05), kSecondaryColor.withOpacity(0.05)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildRouteInfoItem(
                          Icons.straighten,
                          'دووری',
                          routeInfo.distanceText,
                          kPrimaryColor,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, kBorderColor, Colors.transparent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildRouteInfoItem(
                          Icons.access_time,
                          'کات',
                          routeInfo.durationText,
                          kAccentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 28),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openDirections(vendor.latitude!, vendor.longitude!);
                        },
                        icon: const Icon(Icons.navigation, size: 22),
                        label: const Text('دەستپێکردنی ڕێنمایی', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                          shadowColor: kPrimaryColor.withOpacity(0.4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [kDangerColor.withOpacity(0.1), kDangerColor.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kDangerColor.withOpacity(0.2)),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearRoute();
                        },
                        icon: Icon(Icons.close, color: kDangerColor, size: 24),
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Route steps (if available)
                if (routeInfo.steps.isNotEmpty) ...[
                  Text(
                    'هەنگاوەکانی ڕێگا',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: math.min(routeInfo.steps.length, 6), // Show max 6 steps
                      itemBuilder: (context, index) {
                        final step = routeInfo.steps[index];
                        return _buildRouteStep(step, index + 1);
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: kTextSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteStep(RouteStep step, int stepNumber) {
    IconData getManeuverIcon(String maneuver, String instruction) {
      switch (instruction.toLowerCase()) {
        case 'turn':
          return maneuver.contains('left') ? Icons.turn_left : Icons.turn_right;
        case 'continue':
        case 'straight':
          return Icons.straight;
        case 'merge':
          return Icons.merge;
        case 'roundabout':
          return Icons.roundabout_left;
        default:
          return Icons.navigation;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimaryColor, kSecondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kPrimaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            getManeuverIcon(step.maneuver, step.instruction),
            color: kTextSecondary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getInstructionText(step.instruction, step.maneuver),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(step.distance / 1000).toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 14,
                    color: kTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInstructionText(String instruction, String maneuver) {
    switch (instruction.toLowerCase()) {
      case 'turn':
        return maneuver.contains('left') ? 'پێچی چەپ' : 'پێچی ڕاست';
      case 'continue':
      case 'straight':
        return 'بەردەوامبە بەڕێگادا';
      case 'merge':
        return 'تێکەڵ بە ڕێگاکەوە ببە';
      case 'roundabout':
        return 'بچۆ ناو بازاڕدانەوە';
      case 'arrive':
        return 'گەیشتووی بە مەبەست';
      default:
        return 'بەردەوامبە';
    }
  }

  void _showSearchDialog() {
    // TODO: Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('گەڕان بەردەست نییە'),
        backgroundColor: kInfoColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showFilterDialog() {
    // TODO: Implement filter functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('فلتەر بەردەست نییە'),
        backgroundColor: kInfoColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}