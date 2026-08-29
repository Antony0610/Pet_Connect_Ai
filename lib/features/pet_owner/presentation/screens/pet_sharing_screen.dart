import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

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
  bool _isInviting = false;

  final Map<String, String> _rolePermissions = {
    'Co-Owner': 'Full Access (Health, collar telemetry, profile editing)',
    'Veterinarian': 'Medical Access (Health passport, lab results, prescriptions)',
    'Pet Sitter': 'Daily Care Access (Feeding schedules, collar tracking)',
    'Family Member': 'View Access (Photos, timeline updates, activity stats)',
  };

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _inviteCaregiver(Pet? pet) async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      context.showSnackbar('Please enter a valid email address.');
      return;
    }
    if (pet == null) return;

    setState(() => _isInviting = true);
    await HapticFeedback.mediumImpact();

    try {
      final repo = ref.read(petRepositoryProvider);
      final permission = _rolePermissions[_selectedRole] ?? 'Edit Access';
      await repo.inviteCaregiver(
        petId: pet.id,
        email: email,
        role: _selectedRole,
        permissionLevel: permission,
      );

      ref.invalidate(petSharesProvider(pet.id));
      _emailController.clear();

      if (mounted) {
        context.showSnackbar('✅ Invitation sent to $email as $_selectedRole!');
      }
    } catch (e) {
      if (mounted) context.showSnackbar('Failed to invite: $e');
    } finally {
      if (mounted) setState(() => _isInviting = false);
    }
  }

  Future<void> _revokeCaregiver(String shareId, String name, String petId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Revoke Access for $name?'),
        content: const Text('This will immediately remove their access to this pet\'s health passport and collar tracking.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Revoke Access'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(petRepositoryProvider);
      await repo.revokeCaregiver(shareId);
      ref.invalidate(petSharesProvider(petId));
      if (mounted) context.showSnackbar('Access revoked for $name.');
    } catch (e) {
      if (mounted) context.showSnackbar('Failed to revoke access: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedPet = ref.watch(selectedPetProvider);
    final allPets = ref.watch(petsProvider).asData?.value;
    final pet = selectedPet ?? (allPets != null && allPets.isNotEmpty ? allPets.first : null);
    final petName = pet?.name ?? 'Companion';
    final petId = pet?.id ?? '';

    final currentProfile = ref.watch(currentUserProfileProvider).valueOrNull;
    final primaryOwnerName = currentProfile?.fullName.isNotEmpty == true ? currentProfile!.fullName : 'You (Primary Owner)';
    final primaryOwnerEmail = currentProfile?.email ?? 'owner@petconnect.ai';

    final sharesAsync = petId.isNotEmpty ? ref.watch(petSharesProvider(petId)) : null;

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Family & Caregiver Access',
          style: theme.textTheme.titleMedium?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
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
                // ── Banner Header ──────────────────────────────────
                Text(
                  'Manage shared permissions for $petName. Grant family members, veterinarians, and pet sitters customized access to health logs and collar tracking.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Invite Caregiver Card ──────────────────────────
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person_add_alt_1_rounded, color: scheme.primary),
                          AppSpacing.hGapSm,
                          Text(
                            'Invite New Caregiver',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapMd,
                      AppTextField(
                        controller: _emailController,
                        hintText: 'Enter caregiver email address...',
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      AppSpacing.vGapSm,
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        decoration: InputDecoration(
                          labelText: 'Assigned Role',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        items: _rolePermissions.keys.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                      AppSpacing.vGapSm,
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 16, color: scheme.primary),
                            AppSpacing.hGapSm,
                            Expanded(
                              child: Text(
                                _rolePermissions[_selectedRole] ?? '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.vGapMd,
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _isInviting ? null : () => _inviteCaregiver(pet),
                          icon: _isInviting
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send_rounded, size: 16),
                          label: const Text('Send Caregiver Invitation'),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Active Caregivers Section ──────────────────────
                Text(
                  'Active Pet Caregivers & Permissions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                AppSpacing.vGapSm,

                // Primary Owner Card (Always Present)
                _buildMemberCard(
                  context,
                  theme,
                  scheme,
                  name: primaryOwnerName,
                  email: primaryOwnerEmail,
                  role: 'Primary Owner',
                  access: 'Full Administrative & Health Access',
                  isPrimary: true,
                  onRevoke: null,
                ),
                AppSpacing.vGapSm,

                // Live Shared Caregivers
                if (sharesAsync != null)
                  sharesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text('Could not load shared caregivers: $e'),
                    ),
                    data: (shares) {
                      if (shares.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: shares.map((s) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _buildMemberCard(
                              context,
                              theme,
                              scheme,
                              name: s.userName,
                              email: s.userEmail,
                              role: s.role,
                              access: s.permissionLevel,
                              isPrimary: false,
                              onRevoke: () => _revokeCaregiver(s.id, s.userName, petId),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),

                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme, {
    required String name,
    required String email,
    required String role,
    required String access,
    required bool isPrimary,
    VoidCallback? onRevoke,
  }) {
    final roleColor = switch (role) {
      'Primary Owner' => const Color(0xFFEAB308),
      'Co-Owner' => const Color(0xFF6366F1),
      'Veterinarian' => const Color(0xFF0D9488),
      _ => const Color(0xFFF97316),
    };

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: roleColor, width: 2),
            ),
            child: CircleAvatar(
              backgroundColor: roleColor.withValues(alpha: 0.2),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        role,
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  email,
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  access,
                  style: theme.textTheme.labelSmall?.copyWith(color: scheme.primary),
                ),
              ],
            ),
          ),
          if (!isPrimary && onRevoke != null)
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: scheme.error),
              tooltip: 'Revoke Access',
              onPressed: onRevoke,
            ),
        ],
      ),
    );
  }
}
