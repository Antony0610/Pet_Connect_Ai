import 'package:flutter/material.dart';

import '../../../core/theme/tokens/app_radius.dart';

/// A circular avatar displaying a user image, initials, or a default icon.
///
/// Pass [imageUrl] for a network image, [initials] for a text fallback, or
/// neither for a default icon. The [size] determines both width and height.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    this.imageUrl,
    this.initials,
    this.size = 40,
    this.backgroundColor,
    super.key,
  });

  final String? imageUrl;
  final String? initials;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBackgroundColor =
        backgroundColor ?? colorScheme.primaryContainer;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: effectiveBackgroundColor,
      );
    }

    if (initials != null && initials!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: effectiveBackgroundColor,
        child: Text(
          initials!,
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: effectiveBackgroundColor,
      child: Icon(
        Icons.person_rounded,
        size: size * 0.6,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}

/// A rounded-square avatar for pets, displaying an image or a paw icon.
class PetAvatar extends StatelessWidget {
  const PetAvatar({this.imageUrl, this.size = 48, super.key});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: AppRadius.brMd,
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(colorScheme),
        ),
      );
    }

    return _buildPlaceholder(colorScheme);
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: AppRadius.brMd,
      ),
      child: Icon(
        Icons.pets_rounded,
        size: size * 0.5,
        color: colorScheme.onSecondaryContainer,
      ),
    );
  }
}
