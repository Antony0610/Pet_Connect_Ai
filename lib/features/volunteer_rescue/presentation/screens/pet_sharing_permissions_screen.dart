import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_colors.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

/// Pet Sharing & Permissions Screen (Stitch ID: `9b1125312fa04a72bef88c32413a1be7`,
/// Dark Reference: `b4f6638e3a6149e2b0f73dd207a092b6`).
///
/// Access control and foster collaboration screen. Manages co-owner permissions,
/// temporary caretaker/foster access, vet record sharing, and invitation roles.
class PetSharingPermissionsScreen extends StatefulWidget {
  const PetSharingPermissionsScreen({super.key});

  @override
  State<PetSharingPermissionsScreen> createState() =>
      _PetSharingPermissionsScreenState();
}

class _PetSharingPermissionsScreenState
    extends State<PetSharingPermissionsScreen> {
  final List<Map<String, dynamic>> _collaborators = [
    {
      'name': 'Sarah Jenkins',
      'email': 'sarah.j@example.com',
      'role': 'Primary Owner',
      'access': 'Full Access',
      'color': AppColors.success,
    },
    {
      'name': 'Michael Jenkins',
      'email': 'mike.j@example.com',
      'role': 'Family Co-owner',
      'access': 'Full Access',
      'color': AppColors.info,
    },
    {
      'name': 'Alex Rivera (Rescue Lead)',
      'email': 'alex.r@rescueops.org',
      'role': 'Temporary Foster',
      'access': 'Emergency Only',
      'color': AppColors.warning,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sharing & Access Permissions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => _showInviteDialog(context, theme, colorScheme),
            tooltip: 'Add Collaborator',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Share Pet Profile Overview Banner ───────────────
                _buildShareBanner(theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Permission Role Selection Cards ─────────────────
                _buildRoleCategorySection(context, theme, colorScheme),

                AppSpacing.vGapLg,

                // ── Active Collaborators & Foster Roster ─────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Access Collaborators',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Invite Co-owner'),
                      onPressed: () =>
                          _showInviteDialog(context, theme, colorScheme),
                    ),
                  ],
                ),
                AppSpacing.vGapSm,
                ..._collaborators.map(
                  (c) => _buildCollaboratorCard(context, theme, colorScheme, c),
                ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: colorScheme.primary, size: 28),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pet Sharing & Emergency Permissions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppTypography.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  'Manage who has access to emergency tracking, medical vaults, and foster dispatch instructions.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCategorySection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preset Permission Roles',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        AppSpacing.vGapSm,
        Row(
          children: [
            Expanded(
              child: _buildRoleCard(
                theme,
                colorScheme,
                title: 'Family',
                desc: 'Full access & controls',
                icon: Icons.family_restroom,
              ),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: _buildRoleCard(
                theme,
                colorScheme,
                title: 'Vet',
                desc: 'Medical records focus',
                icon: Icons.local_hospital,
              ),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: _buildRoleCard(
                theme,
                colorScheme,
                title: 'Foster',
                desc: 'Temporary routine access',
                icon: Icons.directions_walk,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String desc,
    required IconData icon,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          AppSpacing.vGapXs,
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Map<String, dynamic> c,
  ) {
    final roleColor = c['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.person, color: colorScheme.primary),
            ),
            AppSpacing.hGapSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c['name'] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: AppTypography.bold,
                    ),
                  ),
                  Text(
                    '${c['email']} • ${c['role']}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AppChip(
              label: c['access'] as String,
              backgroundColor: roleColor.withValues(alpha: 0.15),
              textColor: roleColor,
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite Collaborator / Foster'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Collaborator Email',
                hintText: 'user@example.com',
              ),
            ),
            AppSpacing.vGapMd,
            DropdownButtonFormField<String>(
              initialValue: 'Foster',
              decoration: const InputDecoration(labelText: 'Permission Role'),
              items: const [
                DropdownMenuItem(
                  value: 'Family',
                  child: Text('Family Co-owner'),
                ),
                DropdownMenuItem(value: 'Vet', child: Text('Veterinarian')),
                DropdownMenuItem(
                  value: 'Foster',
                  child: Text('Temporary Foster'),
                ),
              ],
              onChanged: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            text: 'Send Invitation',
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Access invitation sent!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
