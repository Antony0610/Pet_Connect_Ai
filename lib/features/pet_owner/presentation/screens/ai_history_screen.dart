import 'package:flutter/material.dart';

import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';

/// The kind of AI interaction, used to tint the row and filter the log.
enum _EntryKind {
  chat('Chat', Icons.forum_rounded),
  analysis('Analysis', Icons.image_search_rounded),
  report('Report', Icons.summarize_rounded),
  insight('Insight', Icons.lightbulb_rounded);

  const _EntryKind(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// One logged AI interaction.
class _Entry {
  const _Entry(this.kind, this.title, this.subtitle, this.time);

  final _EntryKind kind;
  final String title;
  final String subtitle;
  final String time;
}

/// A day-grouped section of history entries.
class _Group {
  const _Group(this.label, this.entries);

  final String label;
  final List<_Entry> entries;
}

/// **AI History** — `/owner/ai/history`.
///
/// A chronological, filterable log of every AI interaction — chats, image
/// analyses, generated reports and insights — grouped by day. Token-driven;
/// one tree serves both themes.
class AiHistoryScreen extends StatefulWidget {
  const AiHistoryScreen({super.key});

  @override
  State<AiHistoryScreen> createState() => _AiHistoryScreenState();
}

class _AiHistoryScreenState extends State<AiHistoryScreen> {
  _EntryKind? _filter;

  static const List<_Group> _groups = [
    _Group('Today', [
      _Entry(
        _EntryKind.chat,
        'Asked about sleep patterns',
        'Is 14 hours of sleep normal for Buddy?',
        '2:14 PM',
      ),
      _Entry(
        _EntryKind.analysis,
        'Rash image scanned',
        'Low risk detected. Apply recommended ointment.',
        '11:02 AM',
      ),
    ]),
    _Group('Yesterday', [
      _Entry(
        _EntryKind.report,
        'Weekly Wellness generated',
        'Aug 1 – Aug 7, 2026',
        '6:30 PM',
      ),
      _Entry(
        _EntryKind.insight,
        'Activity insight',
        'Activity up 15% vs. 30-day average.',
        '9:15 AM',
      ),
    ]),
    _Group('Aug 5, 2026', [
      _Entry(
        _EntryKind.chat,
        'Diet recommendations',
        'How much should I feed a 30kg Golden?',
        '4:48 PM',
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final margin = _horizontalMargin(context.screenWidth);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: aiAppBar(
        context,
        title: 'AI History',
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear history',
            onPressed: () => context.showSnackbar('Clear AI history?'),
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
                  _FilterBar(
                    selected: _filter,
                    onChanged: (k) => setState(() => _filter = k),
                  ),
                  AppSpacing.vGapLg,
                  for (final group in _groups) ...[
                    _GroupSection(group: group, filter: _filter),
                  ],
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

/// The filter row: an "All" chip plus one chip per [_EntryKind].
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _EntryKind? selected;
  final ValueChanged<_EntryKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'All',
            isSelected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final kind in _EntryKind.values) ...[
            AppSpacing.hGapSm,
            _FilterChip(
              label: kind.label,
              isSelected: selected == kind,
              onTap: () => onChanged(kind),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      labelStyle: context.textTheme.labelMedium?.copyWith(
        color: isSelected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        fontWeight: AppTypography.medium,
      ),
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: scheme.primaryContainer,
      showCheckmark: false,
      side: BorderSide(
        color: isSelected ? scheme.primary : scheme.outlineVariant,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brPill),
    );
  }
}

/// One day-grouped section: a date label over a card of interaction rows,
/// filtered to [filter] when set.
class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group, required this.filter});

  final _Group group;
  final _EntryKind? filter;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final entries = filter == null
        ? group.entries
        : group.entries.where((e) => e.kind == filter).toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              group.label,
              style: context.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
          AppCard(
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0)
                    Divider(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                      height: AppSpacing.lg,
                    ),
                  _EntryRow(entry: entries[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final (bg, fg) = switch (entry.kind) {
      _EntryKind.chat => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _EntryKind.analysis => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      _EntryKind.report => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      _EntryKind.insight => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
    };

    return AiListTile(
      leading: AiCircleIcon(
        icon: entry.kind.icon,
        background: bg,
        foreground: fg,
      ),
      title: entry.title,
      subtitle: entry.subtitle,
      onTap: () => context.showSnackbar('Opening ${entry.title}…'),
      trailing: Text(
        entry.time,
        style: context.textTheme.labelMedium?.copyWith(color: scheme.outline),
      ),
    );
  }
}
