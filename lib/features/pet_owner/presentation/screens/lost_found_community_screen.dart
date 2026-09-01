import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/features/volunteer_rescue/domain/entities/lost_pet_alert.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// The **Lost & Found Hub** screen connecting pet owners with real-time missing pet alerts,
/// community sightings, and AI-driven match review.
class LostFoundCommunityScreen extends ConsumerStatefulWidget {
  const LostFoundCommunityScreen({super.key});

  @override
  ConsumerState<LostFoundCommunityScreen> createState() =>
      _LostFoundCommunityScreenState();
}

class _LostFoundCommunityScreenState
    extends ConsumerState<LostFoundCommunityScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedTab = 'All Alerts';

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final alertsAsync = ref.watch(activeLostPetAlertsProvider);

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Lost & Found Hub',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Alert Map',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push(RoutePaths.ownerCommunitySightings);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeLostPetAlertsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header CTA Bar ─────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showReportPetDialog(context, isFound: true),
                          icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                          label: const Text('Report Found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showReportPetDialog(context, isFound: false),
                          icon: const Icon(Icons.campaign_rounded, size: 18),
                          label: const Text('Report Lost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: scheme.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.vGapLg,

                  // ── AI Match Suggestion Card ───────────────────────
                  AiGradientBorderCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: scheme.primary,
                              size: AppIconSizes.md,
                            ),
                            AppSpacing.hGapSm,
                            Text(
                              'AI Physical Match Engine',
                              style: context.textTheme.titleMedium?.copyWith(
                                color: scheme.primary,
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            const Spacer(),
                            const AiConfidenceBadge(percentage: 'Active'),
                          ],
                        ),
                        AppSpacing.vGapSm,
                        Text(
                          'Our vision AI continuously scans nearby community sightings and rescue shelter intakes to detect coat color, breed, and distinctive collar matches in real time.',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface,
                            height: 1.35,
                          ),
                        ),
                        AppSpacing.vGapMd,
                        AppButton.filled(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.push(RoutePaths.ownerCommunitySightings);
                          },
                          size: AppButtonSize.small,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map_rounded, size: 14),
                              SizedBox(width: 4),
                              Text('Open Live Radar Map'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.vGapLg,

                  // ── Urgent Search Section ──────────────────────────
                  alertsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (_, __) => Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline, size: 36, color: scheme.error),
                            AppSpacing.vGapSm,
                            const Text('Unable to load active lost pet alerts.'),
                            TextButton(
                              onPressed: () => ref.invalidate(activeLostPetAlertsProvider),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (alerts) {
                      final activeAlerts = alerts.where((a) => a.alertStatus.toUpperCase() == 'ACTIVE').toList();

                      // Count labels
                      final tabs = [
                        'All Alerts (${alerts.length})',
                        'Active Lost (${activeAlerts.length})',
                        'Resolved (${alerts.length - activeAlerts.length})',
                      ];

                      final displayedAlerts = _selectedTab.startsWith('Active')
                          ? activeAlerts
                          : (_selectedTab.startsWith('Resolved')
                              ? alerts.where((a) => a.alertStatus.toUpperCase() != 'ACTIVE').toList()
                              : alerts);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Filter Tabs ────────────────────────────
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: tabs.map((tab) {
                                final isSelected = _selectedTab.startsWith(tab.split(' ').first);
                                return Padding(
                                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                                  child: ChoiceChip(
                                    label: Text(tab),
                                    selected: isSelected,
                                    selectedColor: scheme.primary,
                                    backgroundColor: scheme.surfaceContainerHigh,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? scheme.onPrimary
                                          : scheme.onSurface,
                                      fontWeight: AppTypography.semiBold,
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        HapticFeedback.lightImpact();
                                        setState(() => _selectedTab = tab);
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          AppSpacing.vGapLg,

                          const SectionHeader(title: 'Active Community Alerts'),
                          AppSpacing.vGapSm,

                          if (displayedAlerts.isEmpty)
                            AppCard(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      decoration: BoxDecoration(
                                        color: scheme.primaryContainer.withValues(alpha: 0.4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.pets_rounded,
                                        size: 36,
                                        color: scheme.primary,
                                      ),
                                    ),
                                    AppSpacing.vGapMd,
                                    Text(
                                      'No Active Lost Pet Alerts',
                                      style: context.textTheme.titleMedium?.copyWith(
                                        fontWeight: AppTypography.bold,
                                      ),
                                    ),
                                    AppSpacing.vGapXs,
                                    Text(
                                      'All community pets in your radius are currently safe and accounted for.',
                                      textAlign: TextAlign.center,
                                      style: context.textTheme.bodyMedium?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            for (final alert in displayedAlerts) ...[
                              _buildAlertCard(context, alert),
                              AppSpacing.vGapMd,
                            ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, LostPetAlert alert) {
    final scheme = context.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final isUrgent = alert.alertStatus.toUpperCase() == 'ACTIVE';

    return AppCard(
      backgroundColor: isUrgent
          ? scheme.errorContainer.withValues(alpha: isDark ? 0.25 : 0.15)
          : scheme.surfaceContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isUrgent ? scheme.error : scheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUrgent ? Icons.campaign : Icons.check_circle,
                      size: 13,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUrgent ? 'ACTIVE ALERT' : 'RESOLVED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (alert.rewardAmount != null && alert.rewardAmount!.isNotEmpty) ...[
                AppSpacing.hGapSm,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.amber, width: 0.8),
                  ),
                  child: Text(
                    'Reward: ${alert.rewardAmount}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                DateFormat('MMM d • h:mm a').format(alert.lastSeenTime),
                style: context.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            alert.description ?? 'Missing Pet Alert',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: AppTypography.bold,
            ),
          ),
          AppSpacing.vGapXs,
          Row(
            children: [
              Icon(Icons.place, size: 14, color: scheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Last seen: ${alert.lastSeenLocation}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Row(
            children: [
              Expanded(
                child: AppButton.filled(
                  onPressed: () => _showReportSightingDialog(context, alert),
                  size: AppButtonSize.small,
                  child: const Text('Report Sighting'),
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: AppButton.outlined(
                  onPressed: () => _contactOwner(context, alert),
                  size: AppButtonSize.small,
                  child: const Text('Contact Owner'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportSightingDialog(BuildContext context, LostPetAlert alert) {
    final locationController = TextEditingController();
    final notesController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Sighting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Provide location or details where you spotted this companion:'),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Sighting Location',
                hintText: 'e.g. Near Main St. Bakery',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes / Appearance',
                hintText: 'e.g. Wearing red collar, seemed calm...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sighting report submitted to owner and rescue network!')),
              );
            },
            child: const Text('Submit Sighting'),
          ),
        ],
      ),
    );
  }

  void _contactOwner(BuildContext context, LostPetAlert alert) {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contact Pet Owner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Owner Contact Phone: ${alert.contactPhone ?? 'Direct In-App Contact'}'),
            const SizedBox(height: 8),
            const Text('You can also send a direct instant message through PetConnect AI.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.chat_bubble_outline, size: 16),
            label: const Text('Direct Chat'),
            onPressed: () {
              Navigator.pop(ctx);
              context.push(RoutePaths.ownerAiChat);
            },
          ),
        ],
      ),
    );
  }

  void _showReportPetDialog(BuildContext context, {required bool isFound}) {
    final title = isFound ? 'Report Found Pet' : 'Report Lost Pet';
    final descController = TextEditingController();
    final locController = TextEditingController();
    final contactController = TextEditingController();
    final rewardController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: locController,
                decoration: const InputDecoration(
                  labelText: 'Last Seen / Sighting Location',
                  hintText: 'e.g. Near Market Rd, Kochi',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Pet Breed & Description',
                  hintText: 'e.g. Pug with fawn coat, black collar, very friendly...',
                  prefixIcon: Icon(Icons.pets_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Phone (Optional)',
                  hintText: 'e.g. +91 98765 43210',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              if (!isFound) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: rewardController,
                  decoration: const InputDecoration(
                    labelText: 'Reward Amount (Optional)',
                    hintText: 'e.g. ₹5,000',
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final loc = locController.text.trim();
              final desc = descController.text.trim();
              if (loc.isEmpty || desc.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter location and description')),
                );
                return;
              }

              Navigator.pop(ctx);
              await HapticFeedback.mediumImpact();

              try {
                final client = ref.read(supabaseClientProvider);
                final currentUserId = client.auth.currentUser?.id;
                final pet = ref.read(selectedPetProvider);

                await client.from('lost_pet_alerts').insert({
                  'pet_id': pet?.id,
                  'owner_id': currentUserId,
                  'alert_status': 'ACTIVE',
                  'last_seen_location': loc,
                  'description': desc,
                  'contact_phone': contactController.text.trim().isNotEmpty
                      ? contactController.text.trim()
                      : null,
                  'reward_amount': rewardController.text.trim().isNotEmpty
                      ? rewardController.text.trim()
                      : null,
                  'last_seen_time': DateTime.now().toIso8601String(),
                });

                ref.invalidate(activeLostPetAlertsProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$title broadcasted successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to publish alert: $e')),
                  );
                }
              }
            },
            child: const Text('Publish Alert'),
          ),
        ],
      ),
    );
  }
}
