// lib/widgets/error_message_widget.dart

import 'package:flutter/material.dart';

// In your error_message_widget.dart file
class ErrorMessageWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData? icon;
  final Color? iconColor;
  
  const ErrorMessageWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: 64,
              color: iconColor ?? Theme.of(context).colorScheme.error,
            ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}