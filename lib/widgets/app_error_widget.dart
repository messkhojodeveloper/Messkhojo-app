import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

enum AppErrorType {
  generic,
  network,
  notFound,
  auth,
}

class AppErrorWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final AppErrorType type;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final bool showHomeButton;
  final bool isCompact;

  const AppErrorWidget({
    super.key,
    this.title,
    this.message,
    this.type = AppErrorType.generic,
    this.onRetry,
    this.retryLabel,
    this.showHomeButton = false,
    this.isCompact = false,
  });

  factory AppErrorWidget.network({
    VoidCallback? onRetry,
    bool showHomeButton = false,
    bool isCompact = false,
  }) {
    return AppErrorWidget(
      title: 'Connection Issue',
      message: 'Unable to connect to the server. Please check your internet connection and try again.',
      type: AppErrorType.network,
      onRetry: onRetry,
      retryLabel: 'Try Again',
      showHomeButton: showHomeButton,
      isCompact: isCompact,
    );
  }

  factory AppErrorWidget.notFound({
    String? title,
    String? message,
    VoidCallback? onRetry,
    bool showHomeButton = true,
    bool isCompact = false,
  }) {
    return AppErrorWidget(
      title: title ?? 'Not Found',
      message: message ?? 'The item you are looking for does not exist or has been removed.',
      type: AppErrorType.notFound,
      onRetry: onRetry,
      showHomeButton: showHomeButton,
      isCompact: isCompact,
    );
  }

  IconData _getIcon() {
    switch (type) {
      case AppErrorType.network:
        return Icons.wifi_off_rounded;
      case AppErrorType.notFound:
        return Icons.search_off_rounded;
      case AppErrorType.auth:
        return Icons.lock_outline_rounded;
      case AppErrorType.generic:
        return Icons.error_outline_rounded;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case AppErrorType.network:
        return const Color(0xFF3B82F6); // Blue
      case AppErrorType.notFound:
        return const Color(0xFFF59E0B); // Amber
      case AppErrorType.auth:
        return AppTheme.primary;
      case AppErrorType.generic:
        return const Color(0xFFEF4444); // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor();
    final displayTitle = title ?? 'Something Went Wrong';
    final displayMessage = message ?? 'An unexpected error occurred. Please try again.';

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIcon(), size: 28, color: iconColor),
              ),
              const SizedBox(height: 12),
              Text(
                displayTitle,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                displayMessage,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(retryLabel ?? 'Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _getIcon(),
                  size: 44,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              displayTitle,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                displayMessage,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(retryLabel ?? 'Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                if (onRetry != null && showHomeButton)
                  const SizedBox(width: 12),
                if (showHomeButton)
                  OutlinedButton.icon(
                    onPressed: () {
                      if (context.mounted) {
                        context.go('/home');
                      }
                    },
                    icon: const Icon(Icons.home_rounded, size: 18),
                    label: const Text('Back to Home'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4B5563),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
