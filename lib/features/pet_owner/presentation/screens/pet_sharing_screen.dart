import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// A faithful Flutter rendering of the frozen Stitch **Pet Sharing & Permissions**
/// (Light Theme design authority, ID `1c015bbf71cb46c5a0890bf6216960d7`).
///
/// Multi-user pet management screen allowing owners to invite co-owners,
/// family members, pet sitters, or veterinarians with granular RBAC permissions.
class PetSharingScreen extends ConsumerStatefulWidget {
  const PetSharingScreen({super.key});

  @override
  ConsumerState<PetSharingScreen> createState() => _PetSharingScreenState();
}

class _PetSharingScreenState extends ConsumerState<PetSharingScreen> {
  static const double _maxContentWidth = 1000;
  final _emailController = TextEditingController();
  String _selectedRole = 'Co-Owner';

  late List<_SharingMemberItem> _members;

  @override
  void initState() {
    super.initState();
    _members = [
      const _SharingMemberItem(
        name: 'Sarah Jenkins',
        role: 'Primary Owner',
        access: 'Full Access (Manage profile, health, collar)',
        isPrimary: true,
      ),
      const _SharingMemberItem(
        name: 'David Chen',
        role: 'Co-Owner',
        access: 'Edit Access (Log medications, telemetry, posts)',
        isPrimary: false,
      ),
      const _SharingMemberItem(
        name: 'Dr. Emily Carter',
        role: 'Veterinarian',
        access: 'Medical Access (Health passport, lab reports)',
        isPrimary: false,
      ),
      const _SharingMemberItem(
        name: 'Metro Pet Sitters',
        role: 'Pet Sitter',
        access: 'Temporary Access (Expires in 3 days • Collar & feeding)',
        isPrimary: false,
      ),
    ];
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final selectedPet = ref.watch(selectedPetProvider);
    final allPets = ref.watch(petsProvider).asData?.value;
    final pet = selectedPet ?? (allPets != null && allPets.isNotEmpty ? allPets.first : null);
    final petName = pet?.name ?? 'Companion';

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Subtitle ──────────────────────────────────────
                Text(
                  "Manage who can view, edit, or track $petName's health passport, smart collar telemetry, and daily activities.",
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Invite New Member Card ─────────────────────────
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              initialValue: _selectedRole,
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
                                if (val != null) {
                                  setState(() => _selectedRole = val);
                                }
                              },
                            ),
                          ),
                          AppSpacing.hGapSm,
                          AppButton.filled(
                            onPressed: () {
                              final text = _emailController.text.trim();
                              if (text.isNotEmpty) {
                                final accessDesc = switch (_selectedRole) {
                                  'Veterinarian' => 'Medical Access (Health passport, lab reports)',
                                  'Pet Sitter' => 'Temporary Access (Collar & feeding)',
                                  'Read Only' => 'View Only Access',
                                  _ => 'Edit Access (Log medications, telemetry, posts)',
                                };

                                setState(() {
                                  _members.add(
                                    _SharingMemberItem(
                                      name: text,
                                      role: _selectedRole,
                                      access: accessDesc,
                                      isPrimary: false,
                                    ),
                                  );
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Invitation sent to $text for $petName as $_selectedRole.',
                                    ),
                                    backgroundColor: Colors.green.shade700,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
  final bool isPrimary;
}
