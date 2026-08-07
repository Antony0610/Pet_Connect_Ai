import 'package:flutter/material.dart';

import '../../core/utils/extensions/context_extensions.dart';

/// Foundation-stage stand-in for a not-yet-implemented screen.
///
/// Every route in `app_router.dart` currently points at one of these so the
/// full navigation graph is wired and traversable before any feature UI
/// exists. As each feature phase lands, its routes swap this out for the real
/// screen — the route contract in `route_paths.dart` never changes.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 48,
                color: context.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: context.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle ?? 'This screen is part of a later feature phase.',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
