import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/cards/app_card.dart';
import 'package:petconnect_ai/shared/widgets/chips/app_chip.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';

class PatientMedicalRecordScreen extends StatefulWidget {
  final String patientId;

  const PatientMedicalRecordScreen({super.key, required this.patientId});

  @override
  State<PatientMedicalRecordScreen> createState() =>
      _PatientMedicalRecordScreenState();
}

class _PatientMedicalRecordScreenState extends State<PatientMedicalRecordScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
              context.go(RoutePaths.vetPatients);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buddy\'s Record',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Golden Retriever • Male Neutered',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
            tooltip: 'Share Record',
          ),
          IconButton(
            icon: const Icon(Icons.edit_note),
            onPressed: () => context.push('/vet/consultation/c1'),
            tooltip: 'Start Visit / Add Note',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Patient Metadata Card
              _buildPatientHeroCard(context, theme, colorScheme),
              const SizedBox(height: 16),

              // Smart Collar Live Telemetry Widget
              _buildLiveCollarWidget(context, theme, colorScheme),
              const SizedBox(height: 16),

              // Record Section Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: colorScheme.primary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicatorColor: colorScheme.primary,
                tabs: const [
                  Tab(text: 'History & Notes'),
                  Tab(text: 'Vaccines'),
                  Tab(text: 'Labs & Imaging'),
                  Tab(text: 'AI Insights'),
                ],
              ),
              const SizedBox(height: 16),

              // AI Clinical Insight Banner
              _buildAiInsightBanner(context, theme, colorScheme),
              const SizedBox(height: 16),

              // Clinical Timeline / Notes List
              Text(
                'Clinical History Timeline',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              _buildTimelineCard(
                context,
                theme,
                colorScheme,
                title: 'Annual Wellness Exam',
                doctor: 'Dr. Emily Chen • General Practice',
                date: 'Today, 10:00 AM',
                content:
                    'Patient presented for annual exam. BCS 5/9. Heart and lungs auscultate normally. Minor dental tartar (Grade 1). Discussed weight maintenance and dental chews. Administered annual vaccines.',
                badges: ['Rabies 3yr', 'Bloodwork Sent'],
              ),
              const SizedBox(height: 12),
              _buildTimelineCard(
                context,
                theme,
                colorScheme,
                title: 'Dermatology Consult',
                doctor: 'Dr. Mark Ruffalo • Specialist',
                date: 'Aug 14, 2023',
                content:
                    'Follow up on seasonal allergies. Owner reports less scratching since starting Apoquel. Ears clear. Continue current regimen.',
                badges: ['Apoquel 16mg'],
              ),
              const SizedBox(height: 20),

              // Health Passport Vaccines Summary
              _buildVaccinesSummaryCard(context, theme, colorScheme),
              const SizedBox(height: 24),

              // Primary Action Button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Start Visit / Open Consultation',
                  onPressed: () => context.push('/vet/consultation/c1'),
                  backgroundColor: colorScheme.primary,
                  textColor: colorScheme.onPrimary,
                  height: 48,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeroCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.pets, size: 32, color: colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Buddy',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AppChip(
                          label: 'Male Neutered',
                          backgroundColor: colorScheme.secondaryContainer,
                          textColor: colorScheme.onSecondaryContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Golden Retriever • DOB: Oct 12, 2020',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetaItem(theme, colorScheme, 'Age', '3y 2m'),
              _buildMetaItem(theme, colorScheme, 'Weight', '32.4 kg'),
              _buildMetaItem(theme, colorScheme, 'BCS', '5/9'),
              _buildMetaItem(theme, colorScheme, 'Owner', 'Sarah J.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveCollarWidget(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.tertiary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.watch_rounded, color: colorScheme.tertiary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Collar Live Telemetry',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.tertiary,
                  ),
                ),
                Text(
                  '78 BPM • Resting HR average normal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: colorScheme.tertiary),
        ],
      ),
    );
  }

  Widget _buildAiInsightBanner(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: colorScheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clinical Insight',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on Buddy\'s breed (Golden Retriever), age (3y), and recent weight trend (+1.2kg over 6mo), AI suggests monitoring for early signs of joint stress. Consider discussing proactive joint supplements.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String doctor,
    required String date,
    required String content,
    required List<String> badges,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(14),
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
              Text(
                date,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Text(
            doctor,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: badges
                .map(
                  (b) => AppChip(
                    label: b,
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    textColor: colorScheme.onSurface,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinesSummaryCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vaccination Status (Health Passport)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _buildVaccineItem('Rabies', 'Valid to Oct 2026', Colors.green),
          const Divider(height: 12),
          _buildVaccineItem('DHPP', 'Valid to Oct 2024', Colors.green),
          const Divider(height: 12),
          _buildVaccineItem('Bordetella', 'Due in 2 wks', Colors.amber),
        ],
      ),
    );
  }

  Widget _buildVaccineItem(String name, String status, Color color) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
