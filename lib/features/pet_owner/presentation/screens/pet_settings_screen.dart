import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/widgets.dart';
import 'package:petconnect_ai/router/route_paths.dart';

class PetSettingsScreen extends ConsumerWidget {
  const PetSettingsScreen({super.key});

  static Widget _avatarPlaceholder(ColorScheme scheme) => Container(
        width: 40,
        height: 40,
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.pets,
          size: AppIconSizes.sm,
          color: scheme.onSurfaceVariant,
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final petId =
        GoRouterState.of(context).pathParameters['petId'] ??
        ref.watch(selectedPetIdProvider);
    final petAsync = petId != null
        ? ref.watch(petDetailProvider(petId))
        : const AsyncValue.data(null);
    final pet = petAsync.valueOrNull ?? ref.watch(selectedPetProvider);

    final appBar = OwnerGlassAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => GoRouter.of(context).pop(),
      ),
      title: Row(
        children: [
          ClipOval(
            child: pet?.imageUrl != null && pet!.imageUrl!.isNotEmpty
                ? Image.network(
                    pet.imageUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _avatarPlaceholder(scheme),
                  )
                : _avatarPlaceholder(scheme),
          ),
          AppSpacing.hGapSm,
          Flexible(
            child: Text(
              'Pet Settings',
              overflow: TextOverflow.ellipsis,
              style: text.headlineSmall?.copyWith(
                color: scheme.primary,
                fontWeight: AppTypography.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        OwnerAppBarAction(
          icon: Icons.smart_toy,
          tooltip: 'AI Assistant',
          onPressed: () => context.goNamed(RouteNames.ownerAiAssistant),
        ),
      ],
    );

    final topPad = context.viewPadding.top + appBar.preferredSize.height;
    final bottomPad = context.viewPadding.bottom + AppSpacing.xxl;

    final petName = pet?.name ?? 'Companion';
    final petBreed = pet?.breed ?? (pet?.species == 'cat' ? 'Domestic Cat' : 'Companion Dog');

    final items = <_SettingRowData>[
      _SettingRowData(
        icon: Icons.edit,
        title: 'Rename Pet',
        subtitle: 'Update $petName’s name',
        onTap: () => _openRenameDialog(context, ref, pet),
      ),
      _SettingRowData(
        icon: Icons.pets,
        title: 'Change Breed/Type',
        subtitle: 'Currently set to $petBreed',
        onTap: () => _openBreedDialog(context, ref, pet),
      ),
      _SettingRowData(
        icon: Icons.lock,
        title: 'Privacy Settings',
        subtitle: 'Manage who can see $petName',
        onTap: () => _openPrivacyDialog(context, ref, pet),
      ),
      _SettingRowData(
        icon: Icons.notifications_active,
        title: 'Notification Preferences',
        subtitle: 'Alerts for walks, meals, and vet for $petName',
        onTap: () => _openNotificationsDialog(context, ref, pet),
      ),
      _SettingRowData(
        icon: Icons.archive,
        title: 'Archive Pet',
        subtitle: 'Hide from main dashboard',
        onTap: () => _openArchiveDialog(context, ref, pet),
      ),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: appBar,
      body: SingleChildScrollView(
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
                // ── Settings list ──────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest,
                    borderRadius: AppRadius.brCard,
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.10),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        _SettingRow(data: items[i], onTap: items[i].onTap),
                        if (i != items.length - 1)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: scheme.outlineVariant.withValues(
                              alpha: 0.10,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                AppSpacing.vGapXl,

                // ── Danger zone ────────────────────────────────────────
                _DeleteButton(
                  onTap: () {
                    if (pet != null) {
                      context.goNamed(
                        RouteNames.ownerPetDelete,
                        pathParameters: {'petId': pet.id},
                      );
                    } else {
                      context.goNamed(RouteNames.ownerPetDelete);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openRenameDialog(BuildContext context, WidgetRef ref, Pet? pet) async {
    if (pet == null) return;
    final controller = TextEditingController(text: pet.name);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Pet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Pet Name',
            hintText: 'Enter new name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && controller.text.trim().isNotEmpty) {
      final updated = pet.copyWith(name: controller.text.trim());
      await ref.read(updatePetUseCaseProvider)(updated);
      await ref.read(petsProvider.notifier).refreshPets();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pet name updated to ${controller.text.trim()}')),
        );
      }
    }
  }

  void _openBreedDialog(BuildContext context, WidgetRef ref, Pet? pet) async {
    if (pet == null) return;
    final controller = TextEditingController(text: pet.breed ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Breed / Species'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Breed',
            hintText: 'e.g. Golden Retriever',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && controller.text.trim().isNotEmpty) {
      final updated = pet.copyWith(breed: controller.text.trim());
      await ref.read(updatePetUseCaseProvider)(updated);
      await ref.read(petsProvider.notifier).refreshPets();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Breed updated to ${controller.text.trim()}')),
        );
      }
    }
  }

  void _openPrivacyDialog(BuildContext context, WidgetRef ref, Pet? pet) async {
    final petId = pet?.id ?? 'default_pet';
    final prefs = ref.read(sharedPreferencesProvider);
    bool publicProfile = prefs.getBool('pet_public_$petId') ?? true;
    bool gpsSharing = prefs.getBool('pet_gps_sharing_$petId') ?? true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Pet Privacy Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.public),
                title: const Text('Public Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Visible in Local Community Hub'),
                value: publicProfile,
                onChanged: (val) {
                  setDlgState(() => publicProfile = val);
                  prefs.setBool('pet_public_$petId', val);
                },
              ),
              const Divider(),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.share_location),
                title: const Text('Emergency GPS Sharing', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Shared with Volunteers in Lost Mode'),
                value: gpsSharing,
                onChanged: (val) {
                  setDlgState(() => gpsSharing = val);
                  prefs.setBool('pet_gps_sharing_$petId', val);
                },
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (context.mounted) {
                  context.showSnackbar('Privacy settings updated for ${pet?.name ?? "companion"}');
                }
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  void _openNotificationsDialog(BuildContext context, WidgetRef ref, Pet? pet) async {
    final petId = pet?.id ?? 'default_pet';
    final prefs = ref.read(sharedPreferencesProvider);
    bool mealAlerts = prefs.getBool('pet_notif_meal_$petId') ?? true;
    bool walkAlerts = prefs.getBool('pet_notif_walk_$petId') ?? true;
    bool vetAlerts = prefs.getBool('pet_notif_vet_$petId') ?? true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Notification Preferences'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.restaurant),
                title: const Text('Meal & Feeding Alerts', style: TextStyle(fontWeight: FontWeight.w600)),
                value: mealAlerts,
                onChanged: (val) {
                  setDlgState(() => mealAlerts = val);
                  prefs.setBool('pet_notif_meal_$petId', val);
                },
              ),
              const Divider(),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.directions_walk),
                title: const Text('Daily Walk Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
                value: walkAlerts,
                onChanged: (val) {
                  setDlgState(() => walkAlerts = val);
                  prefs.setBool('pet_notif_walk_$petId', val);
                },
              ),
              const Divider(),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.medical_services),
                title: const Text('Vaccine & Vet Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
                value: vetAlerts,
                onChanged: (val) {
                  setDlgState(() => vetAlerts = val);
                  prefs.setBool('pet_notif_vet_$petId', val);
                },
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (context.mounted) {
                  context.showSnackbar('Preferences saved for ${pet?.name ?? "companion"}');
                }
              },
              child: const Text('Save Preferences'),
            ),
          ],
        ),
      ),
    );
  }

  void _openArchiveDialog(BuildContext context, WidgetRef ref, Pet? pet) {
    if (pet == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Archive ${pet.name}?'),
        content: const Text(
          'Archiving hides this companion from the main active dashboard without deleting medical records or history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${pet.name} archived.')),
              );
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}

class _SettingRowData {
  const _SettingRowData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.data, required this.onTap});

  final _SettingRowData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.secondaryContainer,
              ),
              child: Icon(
                data.icon,
                size: AppIconSizes.md,
                color: scheme.onSecondaryContainer,
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: text.titleMedium?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  Text(
                    data.subtitle,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: scheme.onSurfaceVariant,
              size: AppIconSizes.md,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Material(
      color: scheme.errorContainer.withValues(alpha: 0.30),
      borderRadius: AppRadius.brCard,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brCard,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brCard,
            border: Border.all(color: scheme.error.withValues(alpha: 0.20)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.error.withValues(alpha: 0.10),
                ),
                child: Icon(
                  Icons.delete_forever,
                  size: AppIconSizes.md,
                  color: scheme.error,
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delete Pet Profile',
                      style: text.titleMedium?.copyWith(
                        color: scheme.error,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    Text(
                      'Permanently remove this pet and data',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
