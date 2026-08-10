import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/owner_app_bar.dart';

/// A faithful Flutter rendering of the frozen Stitch **Pet Sharing & Permissions**
/// (Light Theme design authority, ID `9b11253106194b159b35b62b1a8d051f`).
///
/// Enables pet owners to invite co-owners, manage pet sitter access levels,
/// grant veterinary record permissions, and revoke access tokens.
class PetSharingScreen extends StatefulWidget {
  const PetSharingScreen({super.key});

  @override
  State<PetSharingScreen> createState() => _PetSharingScreenState();
}

class _PetSharingScreenState extends State<PetSharingScreen> {
  static const double _maxContentWidth = 1000;
  final _emailController = TextEditingController();
  String _selectedRole = 'Co-Owner';

  final List<_SharingMemberItem> _members = const [
    _SharingMemberItem(
      name: 'Sarah Jenkins',
      role: 'Primary Owner',
      access: 'Full Access (Manage profile, health, collar)',
      isPrimary: true,
    ),
    _SharingMemberItem(
      name: 'David Chen',
      role: 'Co-Owner',
      access: 'Edit Access (Log medications, telemetry, posts)',
      isPrimary: false,
    ),
    _SharingMemberItem(
      name: 'Dr. Emily Carter',
      role: 'Veterinarian',
      access: 'Medical Access (Health passport, lab reports)',
      isPrimary: false,
    ),
    _SharingMemberItem(
      name: 'Metro Pet Sitters',
      role: 'Pet Sitter',
      access: 'Temporary Access (Expires in 3 days • Collar & feeding)',
      isPrimary: false,
    ),
  ];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Pet Sharing & Permissions',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              children: [
                // ── Subtitle ──────────────────────────────────────
                Text(
                  "Manage who can view, edit, or track Buddy's health passport, smart collar telemetry, and daily activities.",
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Invite New Member Card ─────────────────────────
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Text(
                        'Invite New Co-Owner or Caregiver',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapSm,
                      AppTextField(
                        controller: _emailController,
                        hintText: 'Enter email address or phone number...',
                        prefixIcon: const Icon(Icons.person_add_outlined),
                      ),
                      AppSpacing.vGapSm,
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: InputDecoration(
                                labelText: 'Permission Level',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Co-Owner',
                                  child: Text('Co-Owner (Edit)'),
                                ),
                                DropdownMenuItem(
                                  value: 'Veterinarian',
                                  child: Text('Veterinarian (Medical)'),
                                ),
                                DropdownMenuItem(
                                  value: 'Pet Sitter',
                                  child: Text('Pet Sitter (Temporary)'),
                                ),
                                DropdownMenuItem(
                                  value: 'Read Only',
                                  child: Text('View Only'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedRole = val);
                              },
                            ),
                          ),
                          AppSpacing.hGapSm,
                          AppButton.filled(
                            onPressed: () {
                              if (_emailController.text.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Invitation sent to ${_emailController.text}',
                                    ),
                                  ),
                                );
                                _emailController.clear();
                              }
                            },
                            child: const Text('Send Invite'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapXl,

                // ── Active Shared Members List ─────────────────────
                const SectionHeader(title: 'Active Shared Members'),
                AppSpacing.vGapSm,
                ..._members.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: Row(
                        children: [
                          UserAvatar(name: item.name, radius: 20),
                          AppSpacing.hGapSm,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.name,
                                      style: context.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: AppTypography.bold,
                                          ),
                                    ),
                                    AppSpacing.hGapXs,
                                    Chip(
                                      label: Text(item.role),
                                      backgroundColor: item.isPrimary
                                          ? scheme.primaryContainer
                                          : scheme.surfaceContainerHigh,
                                      labelStyle: TextStyle(
                                        color: item.isPrimary
                                            ? scheme.onPrimaryContainer
                                            : scheme.onSurface,
                                        fontSize: 10,
                                        fontWeight: AppTypography.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  item.access,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!item.isPrimary)
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: scheme.error,
                              ),
                              tooltip: 'Revoke Access',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Access revoked for ${item.name}',
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SharingMemberItem {
  const _SharingMemberItem({
    required this.name,
    required this.role,
    required this.access,
    required this.isPrimary,
  });

  final String name;
  final String role;
  final String access;
  final String isPrimary;
}
