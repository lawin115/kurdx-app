import 'package:flutter_test/flutter_test.dart';
import 'package:kurdpoint/services/api_service.dart';
import 'package:kurdpoint/widgets/error_handler.dart';
import 'package:kurdpoint/utils/error_logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  group('Error Handling Tests', () {
    test('NetworkException creation', () {
      final exception = NetworkException('No internet connection');
      expect(exception.message, 'No internet connection');
      expect(exception.toString(), 'NetworkException: No internet connection');
    });

    test('AuthenticationException creation', () {
      final exception = AuthenticationException('Unauthorized access');
      expect(exception.message, 'Unauthorized access');
      expect(exception.toString(), 'AuthenticationException: Unauthorized access');
    });

    test('ServerException creation', () {
      final exception = ServerException('Server error', 500);
      expect(exception.message, 'Server error');
      expect(exception.statusCode, 500);
      expect(exception.toString(), 'ServerException: Server error (Status: 500)');
    });

    test('TimeoutException creation', () {
      final duration = Duration(seconds: 15);
      final exception = TimeoutException('Request timeout', duration);
      expect(exception.message, 'Request timeout');
      expect(exception.timeout, duration);
      expect(exception.toString(), 'TimeoutException: Request timeout (Timeout: 15s)');
    });

    test('ErrorType constants', () {
      expect(ErrorType.NETWORK, 'network');
      expect(ErrorType.AUTH, 'auth');
      expect(ErrorType.NOT_FOUND, 'not_found');
      expect(ErrorType.SERVER, 'server');
      expect(ErrorType.UNKNOWN, 'unknown');
    });

    test('ErrorMessages retrieval', () {
      final networkError = ErrorMessages.getErrorDetails(ErrorType.NETWORK);
      expect(networkError['title'], 'No Internet Connection');
      expect(networkError['message'], 'Please check your network connection and try again.');

      final authError = ErrorMessages.getErrorDetails(ErrorType.AUTH);
      expect(authError['title'], 'Authentication Required');
      expect(authError['message'], 'Please log in to continue.');

      final unknownError = ErrorMessages.getErrorDetails('nonexistent');
      expect(unknownError['title'], 'Something Went Wrong');
      expect(unknownError['message'], 'An unexpected error occurred. Please try again.');
    });

    test('NetworkChecker methods', () async {
      // These tests just verify the methods exist and can be called
      // Actual connectivity testing would require mocking
      expect(NetworkChecker.hasNetworkConnection, isA<Future<bool> Function()>());
      expect(NetworkChecker.getConnectivityStatus, isA<Future<ConnectivityResult> Function()>());
      expect(NetworkChecker.isConnectedToMobile, isA<Future<bool> Function()>());
      expect(NetworkChecker.isConnectedToWiFi, isA<Future<bool> Function()>());
    });

    test('ErrorLogger singleton', () {
      final logger1 = ErrorLogger();
      final logger2 = ErrorLogger();
      expect(logger1, same(logger2)); // Should be the same instance
    });
  });
}