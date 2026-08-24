import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        onTap: () => _openPrivacyDialog(context),
      ),
      _SettingRowData(
        icon: Icons.notifications_active,
        title: 'Notification Preferences',
        subtitle: 'Alerts for walks, meals, and vet for $petName',
        onTap: () => _openNotificationsDialog(context),
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

  void _openPrivacyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.public),
              title: Text('Public Profile'),
              subtitle: Text('Visible in Local Community Hub'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
            ListTile(
              leading: Icon(Icons.share_location),
              title: Text('Emergency GPS Sharing'),
              subtitle: Text('Shared with Volunteers in Lost Mode'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _openNotificationsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notification Preferences'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.restaurant),
              title: Text('Meal & Feeding Alerts'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
            ListTile(
              leading: Icon(Icons.directions_walk),
              title: Text('Daily Walk Reminders'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
            ListTile(
              leading: Icon(Icons.medical_services),
              title: Text('Vaccine & Vet Reminders'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Save Preferences'),
          ),
        ],
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
