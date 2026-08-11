import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';

class VetTreatmentPlanScreen extends StatelessWidget {
  const VetTreatmentPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.vetHome);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Treatment Plan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Buddy • Seasonal Atopic Dermatitis',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_document),
            onPressed: () {},
            tooltip: 'Edit Plan',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Plan Title & Diagnosis Banner
              _buildPlanHeader(context, theme, colorScheme),
              const SizedBox(height: 16),

              // Step-by-Step Protocol Timeline
              Text(
                'Treatment Protocol Timeline',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              _buildProtocolStep(
                context,
                theme,
                colorScheme,
                stepNumber: '1',
                badge: 'Active Stage • Current',
                badgeColor: colorScheme.primary,
                title: 'Symptom Relief (Medication)',
                desc:
                    'Administer prescribed Apoquel daily to manage acute pruritus and inflammation. Monitor for side effects.',
              ),
              const SizedBox(height: 10),
              _buildProtocolStep(
                context,
                theme,
                colorScheme,
                stepNumber: '2',
                badge: 'Next Phase',
                badgeColor: colorScheme.secondary,
                title: 'Allergen Avoidance',
                desc:
                    'Implement environmental controls based on allergy panel results. Wipe paws after outdoor walks.',
              ),
              const SizedBox(height: 10),
              _buildProtocolStep(
                context,
                theme,
                colorScheme,
                stepNumber: '3',
                badge: 'Milestone',
                badgeColor: colorScheme.tertiary,
                title: 'Follow-up Exam',
                desc:
                    'Scheduled check-in 14 days post-initiation to assess medication efficacy and skin barrier recovery.',
              ),
              const SizedBox(height: 20),

              // Owner Home Care Instructions Card
              _buildHomeCareCard(context, theme, colorScheme),
              const SizedBox(height: 20),

              // AI Prognosis & Recovery Tracking Tile
              _buildAiPrognosisCard(context, theme, colorScheme),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download PDF'),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      text: 'Prescribe Meds',
                      onPressed: () => context.push(RoutePaths.vetPrescription),
                      backgroundColor: colorScheme.primary,
                      textColor: colorScheme.onPrimary,
                      height: 44,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: colorScheme.primaryContainer.withOpacity(0.35),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: colorScheme.primary,
            child: Icon(Icons.pets, color: colorScheme.onPrimary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Treatment Plan: Buddy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Diagnosis: Seasonal Atopic Dermatitis',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolStep(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String stepNumber,
    required String badge,
    required Color badgeColor,
    required String title,
    required String desc,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              stepNumber,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppChip(
                      label: badge,
                      backgroundColor: badgeColor.withOpacity(0.15),
                      textColor: badgeColor,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeCareCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.home_repair_service_outlined,
                color: colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Owner Instructions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Bathing Routine:',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bathe twice weekly with medicated shampoo (Chlorhexidine 4%). Leave on for 10 minutes before rinsing thoroughly.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('Download PDF Sheet'),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAiPrognosisCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.tertiary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: colorScheme.tertiary, size: 22),
              const SizedBox(width: 8),
              Text(
                'AI Prognosis Tracking',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pruritus Score (VAS):', style: theme.textTheme.bodySmall),
              Text(
                '8/10 → Target 2/10',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Erythema Reduction:', style: theme.textTheme.bodySmall),
              AppChip(
                label: 'In Progress',
                backgroundColor: colorScheme.tertiaryContainer,
                textColor: colorScheme.onTertiaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Expected significant relief within 48-72 hrs.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
