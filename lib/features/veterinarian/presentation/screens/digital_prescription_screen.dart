import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';

class DigitalPrescriptionScreen extends StatelessWidget {
  const DigitalPrescriptionScreen({super.key});

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
              'Digital Prescription',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'RX-9824-A • Buddy',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Printing Prescription...')),
              );
            },
            tooltip: 'Print Rx',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
            tooltip: 'Share PDF',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clinic Letterhead Box
              _buildClinicHeader(context, theme, colorScheme),
              const SizedBox(height: 16),

              // Patient & Owner Info Card
              _buildPatientOwnerCard(context, theme, colorScheme),
              const SizedBox(height: 16),

              // Prescription Medication Details Card
              _buildMedicationCard(context, theme, colorScheme),
              const SizedBox(height: 16),

              // Digital Signature & Verification Box
              _buildSignatureCard(context, theme, colorScheme),
              const SizedBox(height: 24),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share PDF'),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      text: 'Send to Pharmacy',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Prescription sent to Oakridge Pharmacy!',
                            ),
                          ),
                        );
                        context.push(RoutePaths.vetPharmacy);
                      },
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

  Widget _buildClinicHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_hospital_rounded,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Oakridge Veterinary Clinic',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '123 Wellness Way, Suite 100, Metropolis, NY 10001',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Phone: (555) 123-4567 | DEA: AB1234567',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prescription #: RX-9824-A',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Date: Oct 24, 2023',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientOwnerCard(
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
              Icon(Icons.pets, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Patient: Buddy',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Canine • Golden Retriever • 4 yrs • Male (N)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            'Weight: 32 kg (70.5 lbs)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Divider(height: 20),
          Row(
            children: [
              Icon(Icons.person_outline, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Owner: Sarah Jenkins',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '456 Maple Drive, Metropolis, NY 10002 • (555) 987-6543',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.medication, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Apoquel 16mg',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              AppChip(
                label: 'Oral Tablet',
                backgroundColor: colorScheme.secondaryContainer,
                textColor: colorScheme.onSecondaryContainer,
              ),
            ],
          ),
          Text(
            '(Oclacitinib tablet)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRxMeta('Quantity', '28 Tablets'),
              _buildRxMeta('Refills', '2'),
              _buildRxMeta('Duration', '14 Days'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructions (Sig):',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Give 1 tablet by mouth twice daily for 14 days.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: colorScheme.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Warning: Give with food to minimize GI upset.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRxMeta(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSignatureCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.verified, color: colorScheme.primary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Electronically Signed',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Dr. Emily Chen, DVM (Lic # NY-987654)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Valid under state veterinary pharmacy regulations.',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
