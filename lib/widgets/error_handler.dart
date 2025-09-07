import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../utils/ios26_theme.dart';

class ErrorHandler extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final bool showRetryButton;
  final String? errorType;

  const ErrorHandler({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.showRetryButton = true,
    this.errorType,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    IconData iconData = Icons.error_outline;
    Color iconColor = isDark ? iosRed : Colors.red;
    
    // Customize icon based on error type
    if (errorType == 'network') {
      iconData = Icons.wifi_off;
      iconColor = isDark ? iosRed : Colors.redAccent;
    } else if (errorType == 'auth') {
      iconData = Icons.lock_outline;
      iconColor = isDark ? iosOrange : Colors.orange;
    } else if (errorType == 'not_found') {
      iconData = Icons.search_off;
      iconColor = isDark ? Colors.grey : Colors.grey;
    }

    return Container(
      color: isDark ? darkBackground : lightBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                iconData,
                size: 80,
                color: iconColor,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? darkPrimaryText : lightPrimaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? darkSecondaryText : lightSecondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (showRetryButton)
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Navigate to settings or help page
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('For assistance, please contact support.'),
                      backgroundColor: isDark ? darkSurface : lightSurface,
                    ),
                  );
                },
                child: Text(
                  'Need Help?',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NetworkChecker {
  static Future<bool> hasNetworkConnection() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }
  
  // Enhanced network checking with more detailed results
  static Future<ConnectivityResult> getConnectivityStatus() async {
    try {
      final result = await Connectivity().checkConnectivity();
      // Return the first result if there are multiple, or none if empty
      if (result.isNotEmpty) {
        return result.first;
      }
      return ConnectivityResult.none;
    } catch (e) {
      return ConnectivityResult.none;
    }
  }
  
  // Check if connected to mobile data
  static Future<bool> isConnectedToMobile() async {
    final result = await getConnectivityStatus();
    return result == ConnectivityResult.mobile;
  }
  
  // Check if connected to WiFi
  static Future<bool> isConnectedToWiFi() async {
    final result = await getConnectivityStatus();
    return result == ConnectivityResult.wifi;
  }
}

// Enhanced error types for better categorization
class ErrorType {
  static const String NETWORK = 'network';
  static const String AUTH = 'auth';
  static const String NOT_FOUND = 'not_found';
  static const String SERVER = 'server';
  static const String UNKNOWN = 'unknown';
}

// Utility class for creating standardized error messages
class ErrorMessages {
  static Map<String, Map<String, String>> get messages => {
    ErrorType.NETWORK: {
      'title': 'No Internet Connection',
      'message': 'Please check your network connection and try again.'
    },
    ErrorType.AUTH: {
      'title': 'Authentication Required',
      'message': 'Please log in to continue.'
    },
    ErrorType.NOT_FOUND: {
      'title': 'Content Not Found',
      'message': 'The requested content could not be found.'
    },
    ErrorType.SERVER: {
      'title': 'Server Error',
      'message': 'Our servers are temporarily unavailable. Please try again later.'
    },
    ErrorType.UNKNOWN: {
      'title': 'Something Went Wrong',
      'message': 'An unexpected error occurred. Please try again.'
    }
  };
  
  static Map<String, String> getErrorDetails(String errorType) {
    return messages[errorType] ?? messages[ErrorType.UNKNOWN]!;
  }
}