import 'package:flutter/material.dart';

import '../../../../core/theme/portal_theme.dart';
import '../../../../core/theme/tokens/app_breakpoints.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/collar_widgets.dart';

/// The outcome of a single hardware/system check.
enum _Health { ok, attention }

/// One diagnostic system check.
class _Check {
  const _Check(this.icon, this.title, this.detail, this.health);

  final IconData icon;
  final String title;
  final String detail;
  final _Health health;
}

/// **Device Diagnostics** — `/owner/collar/diagnostics`.
///
/// The collar's health at a glance: a battery ring with charge state, a list of
/// system checks (GPS, signal, sensors, firmware) each with a health pill, and
/// diagnostic/firmware actions. Token-driven; one tree serves both themes.
class SmartCollarDiagnosticsScreen extends StatelessWidget {
  const SmartCollarDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final width = context.screenWidth;
    final margin = _horizontalMargin(width);

    const checks = [
      _Check(Icons.gps_fixed_rounded, 'GPS module',
          'Strong satellite lock · ±4 m', _Health.ok),
      _Check(Icons.signal_cellular_alt_rounded, 'Cellular signal',
          'Strong (5/5) on the LTE-M network', _Health.ok),
      _Check(Icons.sensors_rounded, 'Motion sensors',
          'Accelerometer & gyroscope nominal', _Health.ok),
      _Check(Icons.system_update_rounded, 'Firmware',
          'v2.4.1 — update available (v2.5.0)', _Health.attention),
    ];

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: collarAppBar(
        context,
        title: 'Diagnostics',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Re-run checks',
            onPressed: () => context.showSnackbar('Running diagnostics…'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                margin,
                AppSpacing.md,
                margin,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _BatteryHero(),
                  AppSpacing.vGapLg,
                  Text(
                    'System Checks',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  AppSpacing.vGapSm,
                  AppCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < checks.length; i++) ...[
                          if (i > 0)
                            Divider(
                              color:
                                  scheme.outlineVariant.withValues(alpha: 0.4),
                              height: AppSpacing.lg,
                            ),
                          _CheckRow(check: checks[i]),
                        ],
                      ],
                    ),
                  ),
                  AppSpacing.vGapLg,
                  AppButton(
                    label: 'Run Full Diagnostic',
                    icon: Icons.health_and_safety_rounded,
                    borderRadius: AppRadius.brPill,
                    onPressed: () =>
                        context.showSnackbar('Running full diagnostic…'),
                  ),
                  AppSpacing.vGapSm,
                  AppButton.outlined(
                    label: 'Update Firmware',
                    icon: Icons.system_update_rounded,
                    borderRadius: AppRadius.brPill,
                    onPressed: () =>
                        context.showSnackbar('Updating to v2.5.0…'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static double _horizontalMargin(double width) {
    if (width < AppBreakpoints.tablet) return AppSpacing.marginMobile;
    if (width < AppBreakpoints.desktop) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }
}
// __CONT_1__
/// The battery hero: a charge ring beside the collar's power state and a short
/// estimated-life readout.
class _BatteryHero extends StatelessWidget {
  const _BatteryHero();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final accent = palette.accent;

    final ring = CollarMetricRing(
      progress: 0.84,
      arcColor: accent,
      size: 148,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, color: accent, size: AppIconSizes.md),
          Text(
            '84%',
            style: context.textTheme.headlineMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: AppTypography.bold,
              height: 1,
            ),
          ),
          Text(
            'Battery',
            style: context.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    final readout = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Healthy charge',
          style: context.textTheme.titleMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: AppTypography.semiBold,
          ),
        ),
        AppSpacing.vGapXs,
        Text(
          'About 4 days of battery remaining at the current usage. Last charged '
          '2 days ago.',
          style: context.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return AppCard(
      child: context.screenWidth >= AppBreakpoints.tablet
          ? Row(
              children: [
                ring,
                AppSpacing.hGapLg,
                Expanded(child: readout),
              ],
            )
          : Column(
              children: [ring, AppSpacing.vGapMd, readout],
            ),
    );
  }
}

/// One system-check row: a glyph, the check name and detail, and a health pill.
class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check});

  final _Check check;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final palette = PortalPalettes.of(AppPortal.petOwner);
    final brightness = context.theme.brightness;

    final isOk = check.health == _Health.ok;
    final (pillBg, pillFg, pillIcon, pillLabel) = isOk
        ? (
            palette.accentContainer(brightness),
            palette.onAccentContainer(brightness),
            Icons.check_circle_rounded,
            'OK',
          )
        : (
            scheme.tertiaryContainer,
            scheme.onTertiaryContainer,
            Icons.info_rounded,
            'Action',
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(check.icon, color: scheme.primary, size: AppIconSizes.md),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                check.title,
                style: context.textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
              AppSpacing.vGapXs,
              Text(
                check.detail,
                style: context.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.hGapSm,
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: AppRadius.brPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(pillIcon, color: pillFg, size: AppIconSizes.sm),
              AppSpacing.hGapXs,
              Text(
                pillLabel,
                style: context.textTheme.labelMedium?.copyWith(
                  color: pillFg,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
