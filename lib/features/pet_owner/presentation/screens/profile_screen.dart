import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/usecase/usecase.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/widgets.dart';
import 'package:petconnect_ai/features/storage/presentation/providers/storage_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/avatar/user_avatar.dart';

/// The Pet Owner **Profile** screen.
///
/// Displays real user data from [currentUserProfileProvider].
/// - Avatar, full name, email loaded live from Supabase.
/// - Edit Profile opens a bottom sheet that saves via [upsertUserProfileProvider].
/// - Settings icon in AppBar navigates to [SettingsScreen].
/// - Logout button visible directly from this screen.
/// - Pets section shows real pets from [petsProvider].
/// - NO hardcoded posts, badges, groups or events.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final profileAsync = ref.watch(currentUserProfileProvider);

    final avatarUrl = profileAsync.valueOrNull?.avatarUrl;

    final appBar = OwnerGlassAppBar(
      leading: UserAvatar(imageUrl: avatarUrl ?? '', size: 40),
      title: Text(
        'My Profile',
        style: context.textTheme.titleLarge?.copyWith(
          color: scheme.primary,
          fontWeight: AppTypography.bold,
        ),
      ),
      actions: [
        OwnerAppBarAction(
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          onPressed: () => context.goNamed(RouteNames.ownerSettings),
        ),
      ],
    );

    final topPad = context.viewPadding.top + appBar.preferredSize.height;
    final bottomPad =
        context.viewPadding.bottom + AppSpacing.xxl * 2 + AppSpacing.md;

    return OwnerScaffold(
      currentTab: OwnerTab.profile,
      appBar: appBar,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Unable to load profile: $e',
            style: context.textTheme.bodyMedium
                ?.copyWith(color: scheme.error),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Text(
                'Profile not found. Please sign out and sign in again.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium,
              ),
            );
          }
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              topPad + AppSpacing.md,
              AppSpacing.marginMobile,
              bottomPad,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeaderCard(profile: profile),
                    AppSpacing.vGapLg,
                    _MyPetsSection(),
                    AppSpacing.vGapXl,
                    _LogoutSection(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Profile Header Card
// ═══════════════════════════════════════════════════════════════════════════════

class _ProfileHeaderCard extends ConsumerStatefulWidget {
  const _ProfileHeaderCard({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_ProfileHeaderCard> createState() =>
      _ProfileHeaderCardState();
}

class _ProfileHeaderCardState extends ConsumerState<_ProfileHeaderCard> {
  bool _uploadingAvatar = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final profile = widget.profile;

    return Card(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brSection,
        side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: AppSpacing.cardPaddingPremium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with tap-to-upload
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      UserAvatar(
                          imageUrl: profile.avatarUrl ?? '', size: 88),
                      if (_uploadingAvatar)
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: AppIconSizes.xs),
                ),
              ],
            ),
            AppSpacing.vGapMd,

            // Full name
            Text(
              profile.fullName.isEmpty ? 'No name set' : profile.fullName,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            AppSpacing.vGapXs,

            // Email
            Text(
              profile.email,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            AppSpacing.vGapXs,

            // Phone number
            if (profile.phone != null && profile.phone!.trim().isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_outlined, size: 14, color: scheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    profile.phone!,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapXs,
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_call, size: 13, color: scheme.error),
                  const SizedBox(width: 4),
                  Text(
                    'No phone number • Tap Edit to add',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapXs,
            ],

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.30),
                borderRadius: AppRadius.brPill,
              ),
              child: Text(
                _roleLabel(profile.role.toDbRole()),
                style: context.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            AppSpacing.vGapLg,

            // Edit Profile Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profile'),
                onPressed: () => _showEditProfileSheet(context, profile),
                style: OutlinedButton.styleFrom(
                  foregroundColor: scheme.primary,
                  side: BorderSide(color: scheme.primary),
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.brCard),
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final storageRepo = ref.read(storageRepositoryProvider);
      final userId = widget.profile.id;

      // Upload to user-avatars bucket using the domain method
      final uploadResult = await storageRepo.uploadUserAvatar(
        userId: userId,
        bytes: bytes,
        fileName: 'avatar.jpg',
        mimeType: 'image/jpeg',
      );

      await uploadResult.fold(
        (failure) async {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: ${failure.message}')),
            );
          }
        },
        (newUrl) async {
          // Update profile with new avatar URL
          final upsert = ref.read(upsertUserProfileProvider);
          await upsert(widget.profile.copyWith(avatarUrl: newUrl));
          // Refresh profile provider
          ref.invalidate(currentUserProfileProvider);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showEditProfileSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (_) => _EditProfileSheet(profile: profile),
    );
  }

  static String _roleLabel(String dbRole) {
    return switch (dbRole) {
      'veterinarian' => 'Veterinarian',
      'volunteer_rescue' => 'Rescue Volunteer',
      'administrator' => 'Administrator',
      _ => 'Pet Owner',
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Edit Profile Bottom Sheet
// ═══════════════════════════════════════════════════════════════════════════════

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.profile.fullName);
    _phoneController =
        TextEditingController(text: widget.profile.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name cannot be empty.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final upsert = ref.read(upsertUserProfileProvider);
    final result = await upsert(
      widget.profile.copyWith(
        fullName: name,
        phone: phone.isNotEmpty ? phone : null,
      ),
    );

    result.fold(
      (failure) {
        setState(() {
          _error = failure.message;
          _saving = false;
        });
      },
      (_) {
        ref.invalidate(currentUserProfileProvider);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully.')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Edit Profile',
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          AppSpacing.vGapLg,
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Your display name',
              prefixIcon: const Icon(Icons.person_outline),
              errorText: _error,
              border: const OutlineInputBorder(
                  borderRadius: AppRadius.brCard),
            ),
            textInputAction: TextInputAction.next,
          ),
          AppSpacing.vGapMd,
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Emergency Contact Phone',
              hintText: 'e.g. +1 555-0199 or 9876543210',
              prefixIcon: Icon(Icons.phone_outlined),
              helperText: 'Displayed on Missing Pet Posters & Health Passports',
              border: OutlineInputBorder(
                  borderRadius: AppRadius.brCard),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          AppSpacing.vGapMd,
          Text(
            'Email: ${widget.profile.email}',
            style: context.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          AppSpacing.vGapLg,
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.brCard),
            ),
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// My Pets Section
// ═══════════════════════════════════════════════════════════════════════════════

class _MyPetsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final petsAsync = ref.watch(petsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Pets',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              onPressed: () => context.goNamed(RouteNames.ownerPetAdd),
            ),
          ],
        ),
        AppSpacing.vGapMd,
        petsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text(
            'Unable to load pets.',
            style: context.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          data: (pets) {
            if (pets.isEmpty) {
              return _EmptyPetsCard();
            }
            return Column(
              children: [
                for (final pet in pets) _PetProfileRow(pet: pet),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EmptyPetsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Card(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brCard,
        side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Icon(Icons.pets_rounded,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.50)),
            AppSpacing.hGapMd,
            Text(
              'No pets added yet.',
              style: context.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetProfileRow extends StatelessWidget {
  const _PetProfileRow({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brCard,
        side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.20)),
      ),
      child: ListTile(
        onTap: () =>
            context.goNamed(RouteNames.ownerPetDetail, pathParameters: {
          'petId': pet.id,
        }),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: scheme.secondaryContainer,
          backgroundImage: pet.imageUrl != null && pet.imageUrl!.isNotEmpty
              ? NetworkImage(pet.imageUrl!)
              : null,
          child:
              pet.imageUrl == null || pet.imageUrl!.isEmpty
                  ? Icon(Icons.pets_rounded,
                      color: scheme.onSecondaryContainer,
                      size: AppIconSizes.sm)
                  : null,
        ),
        title: Text(pet.name,
            style: context.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          pet.breedLine,
          style: context.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        trailing: Icon(Icons.chevron_right,
            color: scheme.onSurfaceVariant),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Logout Section
// ═══════════════════════════════════════════════════════════════════════════════

class _LogoutSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Settings row
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brCard,
            side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.20)),
          ),
          tileColor: scheme.surface,
          leading:
              Icon(Icons.settings_outlined, color: scheme.onSurfaceVariant),
          title: const Text('Settings'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.goNamed(RouteNames.ownerSettings),
        ),
        AppSpacing.vGapSm,

        // Sign out button
        OutlinedButton.icon(
          icon: Icon(Icons.logout, color: scheme.error),
          label: Text('Sign Out',
              style: TextStyle(color: scheme.error)),
          onPressed: () => _confirmSignOut(context, ref),
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error.withValues(alpha: 0.50)),
            shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.brCard),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content:
            const Text('Are you sure you want to sign out of PetConnect AI?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign Out',
                style: TextStyle(
                    color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final signOut = ref.read(signOutProvider);
    final result = await signOut(const NoParams());
    result.fold(
      (failure) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign out failed: ${failure.message}')),
          );
        }
      },
      (_) {
        if (context.mounted) {
          context.go(RoutePaths.login);
        }
      },
    );
  }
}
