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
        if (isOnline) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          color: Theme.of(context).colorScheme.errorContainer,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 14,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 6),
              Text(
                'You\'re offline — changes will sync when you reconnect',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
