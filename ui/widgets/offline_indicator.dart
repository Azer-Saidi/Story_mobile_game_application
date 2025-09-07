import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storyapp/providers/auth_provider.dart';

class OfflineIndicator extends StatelessWidget {
  final Widget child;

  const OfflineIndicator({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final banner = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.wifi_off,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You are currently offline. Some features may be limited.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );

        return Stack(
          children: [
            // Base content
            Positioned.fill(child: child),
            // Offline banner overlay at the top
            if (authProvider.isOffline)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: SafeArea(child: banner),
              ),
          ],
        );
      },
      child: child,
    );
  }
}
