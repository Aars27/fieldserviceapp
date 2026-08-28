import 'package:flutter/material.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppLoadingView extends StatelessWidget {
  final String? message;

  const AppLoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 32, color: cs.error),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
