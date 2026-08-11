import 'package:flutter/material.dart';

/// A circular avatar displaying a user image, initials, or a default icon.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    this.imageUrl,
    this.initials,
    this.name,
    this.size = 40,
    this.radius,
    this.backgroundColor,
    super.key,
  });

  final String? imageUrl;
  final String? initials;
  final String? name;
  final double size;
  final double? radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveBackgroundColor =
        backgroundColor ?? colorScheme.primaryContainer;
    final effectiveSize = radius != null ? radius! * 2 : size;
    final effectiveInitials =
        initials ??
        (name != null && name!.isNotEmpty ? name![0].toUpperCase() : null);

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: effectiveSize / 2,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: effectiveBackgroundColor,
      );
    }

    if (effectiveInitials != null && effectiveInitials.isNotEmpty) {
      return CircleAvatar(
        radius: effectiveSize / 2,
        backgroundColor: effectiveBackgroundColor,
        child: Text(
          effectiveInitials,
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontSize: effectiveSize * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: effectiveSize / 2,
      backgroundColor: effectiveBackgroundColor,
      child: Icon(
        Icons.person_rounded,
        size: effectiveSize * 0.6,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}
