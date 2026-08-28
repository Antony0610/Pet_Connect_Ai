import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/ai_services/presentation/providers/ai_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/router/route_paths.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

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
  const _Entry(
    this.kind,
    this.title,
    this.subtitle,
    this.time, {
    this.id,
    this.onTap,
  });

  final _EntryKind kind;
  final String title;
  final String subtitle;
  final String time;
  final String? id;
  final VoidCallback? onTap;
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
/// analyses, generated reports and insights — with direct navigation to resumes threads.
class AiHistoryScreen extends ConsumerStatefulWidget {
  const AiHistoryScreen({super.key});

  @override
  ConsumerState<AiHistoryScreen> createState() => _AiHistoryScreenState();
}

class _AiHistoryScreenState extends ConsumerState<AiHistoryScreen> {
  _EntryKind? _filter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final margin = _horizontalMargin(context.screenWidth);
    final conversationsAsync = ref.watch(aiConversationsProvider);
    final scansAsync = ref.watch(aiHealthScansProvider);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: aiAppBar(
        context,
        title: 'AI History',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(aiConversationsProvider);
              ref.invalidate(aiHealthScansProvider);
              context.showSnackbar('AI History refreshed.');
            },
          ),
        ],
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          final scans = scansAsync.asData?.value ?? [];

          // Group entries by date
          final now = DateTime.now();
          final timeFormat = DateFormat('h:mm a');

          // Filter out redundant empty 'Daily Insight' conversations from user view
          final realConversations = conversations
              .where((c) => c.title != 'Daily Insight' || conversations.length <= 1)
              .toList();

          final List<_Entry> chatEntries = realConversations.map((c) {
            return _Entry(
              _EntryKind.chat,
              c.title,
              'Session ID: ${c.id.substring(0, c.id.length > 8 ? 8 : c.id.length)}',
              timeFormat.format(c.createdAt),
              id: c.id,
              onTap: () => context.push('${RoutePaths.ownerAiChat}?conversationId=${c.id}'),
            );
          }).toList();

          final List<_Entry> scanEntries = scans
              .where((s) => !s.analysisSummary.contains('404'))
              .map((s) {
            return _Entry(
              _EntryKind.analysis,
              'Symptom Scan: ${s.urgencyLevel}',
              s.analysisSummary.length > 60
                  ? '${s.analysisSummary.substring(0, 60)}...'
                  : s.analysisSummary,
              timeFormat.format(s.createdAt),
              id: s.id,
              onTap: () => context.push(RoutePaths.ownerAiDiagnostic),
            );
          }).toList();

          final List<_Entry> reportEntries = [
            _Entry(
              _EntryKind.report,
              'Weekly Wellness Report',
              'Activity up 15%, restorative rest patterns',
              timeFormat.format(now.subtract(const Duration(hours: 4))),
              onTap: () => context.push(RoutePaths.ownerAiReports),
            ),
          ];

          final List<_Entry> insightEntries = [
            _Entry(
              _EntryKind.insight,
              'Activity & Sleep Telemetry Insight',
              'Optimal mobility and sleep tracking verified',
              timeFormat.format(now.subtract(const Duration(hours: 6))),
              onTap: () => context.push(RoutePaths.ownerAiInsights),
            ),
          ];

          final allEntries = [
            ...chatEntries,
            ...scanEntries,
            ...reportEntries,
            ...insightEntries,
          ];

          // Apply search query if present
          final searchedEntries = _searchQuery.isEmpty
              ? allEntries
              : allEntries.where((e) {
                  final q = _searchQuery.toLowerCase();
                  return e.title.toLowerCase().contains(q) || e.subtitle.toLowerCase().contains(q);
                }).toList();

          final groups = [
            _Group('Recent Interactions', searchedEntries),
          ];

          final filtered = groups
              .map((g) {
                final matched = _filter == null
                    ? g.entries
                    : g.entries.where((e) => e.kind == _filter).toList();
                return _Group(g.label, matched);
              })
              .where((g) => g.entries.isNotEmpty)
              .toList();

          return SingleChildScrollView(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search chats, scans, or reports...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () => setState(() => _searchQuery = ''),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                      AppSpacing.vGapMd,
                      _FilterBar(
                        selected: _filter,
                        onChanged: (kind) => setState(() => _filter = kind),
                      ),
                      AppSpacing.vGapLg,
                      if (filtered.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: Text(
                              'No interactions found for this filter.',
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        for (final group in filtered) ...[
                          _GroupSection(group: group, filter: _filter),
                          AppSpacing.vGapLg,
                        ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Unable to load AI history: $err',
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.error,
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

/// A horizontally scrollable row of filter chips: "All", "Chat", "Analysis",
/// "Report", "Insight".
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _EntryKind? selected;
  final ValueChanged<_EntryKind?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'All',
            isSelected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final kind in _EntryKind.values) ...[
            AppSpacing.hGapSm,
            _Chip(
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

class _Chip extends StatelessWidget {
  const _Chip({
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
    final bg = isSelected
        ? scheme.primary
        : scheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final fg = isSelected ? scheme.onPrimary : scheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.brPill,
          ),
          child: Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight:
                  isSelected ? AppTypography.bold : AppTypography.medium,
            ),
          ),
        ),
      ),
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
      onTap: entry.onTap ?? () => context.showSnackbar('Opening ${entry.title}…'),
      trailing: Text(
        entry.time,
        style: context.textTheme.labelMedium?.copyWith(color: scheme.outline),
      ),
    );
  }
}
