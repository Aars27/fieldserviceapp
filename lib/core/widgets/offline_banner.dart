import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityServiceProvider);
    return StreamBuilder<bool>(
      stream: connectivity.onConnectivityChanged,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: isOnline ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF991B1B) : const Color(0xFFFECACA),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'You\'re offline — changes will sync automatically',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFFEE2E2) : const Color(0xFF991B1B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
