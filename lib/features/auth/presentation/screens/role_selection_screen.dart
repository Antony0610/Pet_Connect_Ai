import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/portal_theme.dart';
import '../../../../core/theme/tokens/app_durations.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../router/route_paths.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../providers/auth_providers.dart';

class _RoleOption {
  const _RoleOption({
    required this.portal,
    required this.title,
    required this.description,
    required this.icon,
  });

  final AppPortal portal;
  final String title;
  final String description;
  final IconData icon;
}

const _roleOptions = <_RoleOption>[
  _RoleOption(
    portal: AppPortal.petOwner,
    title: 'Pet Owner',
    description: "Manage your pet's health and tracking.",
    icon: Icons.pets,
  ),
  _RoleOption(
    portal: AppPortal.veterinarian,
    title: 'Veterinarian',
    description: 'Manage patients and medical records.',
    icon: Icons.local_hospital,
  ),
  _RoleOption(
    portal: AppPortal.volunteerRescue,
    title: 'Volunteer & Rescue',
    description: 'Help pets in need and coordinate rescues.',
    icon: Icons.volunteer_activism,
  ),
  _RoleOption(
    portal: AppPortal.administrator,
    title: 'Administrator',
    description: 'Manage the platform and analytics.',
    icon: Icons.admin_panel_settings,
  ),
];

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  void _continue() => context.go(RoutePaths.register);

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;
    final selected = ref.watch(selectedPortalProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.marginMobile,
            vertical: AppSpacing.xl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      children: [
                        Text(
                          'Choose Your Experience',
                          textAlign: TextAlign.center,
                          style: textTheme.displaySmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppSpacing.vGapSm,
                        Text(
                          "Select how you'll be using PetConnect AI to personalize "
                          'your dashboard and tools.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 768 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: AppSpacing.xl,
                          mainAxisSpacing: AppSpacing.xl,
                          mainAxisExtent: 260,
                        ),
                        itemCount: _roleOptions.length,
                        itemBuilder: (context, index) {
                          final option = _roleOptions[index];
                          return _RoleCard(
                            option: option,
                            isSelected: selected == option.portal,
                            onTap: () =>
                                ref
                                        .read(selectedPortalProvider.notifier)
                                        .state =
                                    option.portal,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: Column(
                      children: [
                        AppButton.filled(
                          label: 'Continue to Dashboard',
                          icon: Icons.arrow_forward,
                          iconAlignment: IconAlignment.end,
                          borderRadius: AppRadius.brPill,
                          isFullWidth: true,
                          size: AppButtonSize.large,
                          onPressed: _continue,
                        ),
                        AppSpacing.vGapLg,
                        Text(
                          'You can always change your role later in Settings.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
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
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _RoleOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final palette = PortalPalettes.of(option.portal);
    final accent = palette.accent;

    return AnimatedScale(
      scale: isSelected ? 1.02 : 1,
      duration: AppDurations.medium2,
      curve: AppDurations.standard,
      child: AnimatedContainer(
        duration: AppDurations.medium2,
        curve: AppDurations.standard,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.surfaceContainerLowest, scheme.surfaceContainerLow],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isSelected ? accent : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? accent.withValues(alpha: 0.18)
                  : scheme.shadow.withValues(alpha: 0.05),
              blurRadius: isSelected ? 30 : 15,
              offset: Offset(0, isSelected ? 12 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(32),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Stack(
                children: [
                  Positioned(
                    right: -8,
                    bottom: -8,
                    child: Icon(
                      option.icon,
                      size: 150,
                      color: accent.withValues(alpha: 0.10),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedRotation(
                        turns: isSelected ? 0.014 : 0,
                        duration: AppDurations.medium2,
                        child: AnimatedScale(
                          scale: isSelected ? 1.15 : 1,
                          duration: AppDurations.medium2,
                          child: Container(
                            width: 64,
                            height: 64,
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.xl,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.10),
                              borderRadius: AppRadius.brCard,
                            ),
                            child: Icon(option.icon, size: 36, color: accent),
                          ),
                        ),
                      ),
                      Text(
                        option.title,
                        style: context.textTheme.headlineSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        option.description,
                        style: context.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: isSelected ? 1 : 0,
                      duration: AppDurations.short4,
                      child: Icon(Icons.check_circle, size: 28, color: accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
