import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:intl/intl.dart';

/// A comprehensive error logging utility for the application
class ErrorLogger {
  static final ErrorLogger _instance = ErrorLogger._internal();
  factory ErrorLogger() => _instance;
  ErrorLogger._internal();

  /// Log an error with detailed information
  void logError(
    String errorType,
    String message, {
    String? stackTrace,
    String? fileName,
    int? lineNumber,
    String? functionName,
    Map<String, dynamic>? additionalInfo,
  }) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final errorInfo = {
      'timestamp': timestamp,
      'errorType': errorType,
      'message': message,
      'stackTrace': stackTrace,
      'fileName': fileName,
      'lineNumber': lineNumber,
      'functionName': functionName,
      'additionalInfo': additionalInfo,
      'deviceInfo': {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
      }
    };

    // In debug mode, print to console
    if (kDebugMode) {
      print('=== ERROR LOG ===');
      print('Timestamp: $timestamp');
      print('Type: $errorType');
      print('Message: $message');
      if (stackTrace != null) print('Stack Trace: $stackTrace');
      if (fileName != null) print('File: $fileName${lineNumber != null ? ':$lineNumber' : ''}');
      if (functionName != null) print('Function: $functionName');
      if (additionalInfo != null) print('Additional Info: $additionalInfo');
      print('==================');
    }

    // In release mode, you might want to send to a remote logging service
    if (kReleaseMode) {
      // Example: Send to Firebase Crashlytics, Sentry, etc.
      // crashlytics.recordError(message, stackTrace, reason: errorType);
    }
  }

  /// Log a network error
  void logNetworkError(
    String url,
    int? statusCode,
    String message, {
    String? stackTrace,
    Map<String, dynamic>? requestDetails,
  }) {
    logError(
      'NetworkError',
      'Network request failed for URL: $url',
      stackTrace: stackTrace,
      additionalInfo: {
        'url': url,
        'statusCode': statusCode,
        'message': message,
        'requestDetails': requestDetails,
      },
    );
  }

  /// Log an authentication error
  void logAuthError(
    String operation,
    String message, {
    String? stackTrace,
    Map<String, dynamic>? authDetails,
  }) {
    logError(
      'AuthError',
      'Authentication failed during $operation',
      stackTrace: stackTrace,
      additionalInfo: {
        'operation': operation,
        'message': message,
        'authDetails': authDetails,
      },
    );
  }

  /// Log a database error
  void logDatabaseError(
    String operation,
    String message, {
    String? stackTrace,
    Map<String, dynamic>? dbDetails,
  }) {
    logError(
      'DatabaseError',
      'Database operation failed during $operation',
      stackTrace: stackTrace,
      additionalInfo: {
        'operation': operation,
        'message': message,
        'dbDetails': dbDetails,
      },
    );
  }

  /// Log a UI error
  void logUIError(
    String widgetName,
    String message, {
    String? stackTrace,
    Map<String, dynamic>? uiDetails,
  }) {
    logError(
      'UIError',
      'UI error in widget: $widgetName',
      stackTrace: stackTrace,
      additionalInfo: {
        'widgetName': widgetName,
        'message': message,
        'uiDetails': uiDetails,
      },
    );
  }

  /// Log a performance warning
  void logPerformanceWarning(
    String operation,
    Duration duration,
    String message,
  ) {
    logError(
      'PerformanceWarning',
      'Slow operation detected: $operation took ${duration.inMilliseconds}ms',
      additionalInfo: {
        'operation': operation,
        'durationMs': duration.inMilliseconds,
        'message': message,
      },
    );
  }
}

/// Extension methods for easier error logging
extension ErrorLoggingExtensions on Object {
  /// Log this exception with additional context
  void log({
    String? errorType,
    String? message,
    String? stackTrace,
    String? fileName,
    int? lineNumber,
    String? functionName,
    Map<String, dynamic>? additionalInfo,
  }) {
    ErrorLogger().logError(
      errorType ?? runtimeType.toString(),
      message ?? toString(),
      stackTrace: stackTrace,
      fileName: fileName,
      lineNumber: lineNumber,
      functionName: functionName,
      additionalInfo: additionalInfo,
    );
  }
}