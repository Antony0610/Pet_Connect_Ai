import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/ai_widgets.dart';
import '../widgets/owner_app_bar.dart';

/// A faithful Flutter rendering of the frozen Stitch **Community Messages**
/// (Light Theme design authority, ID `ec84e328`).
///
/// Enables direct messaging between pet owners, rescue volunteers, and vets
/// with integrated AI chat summaries and message input controls.
class CommunityMessagesScreen extends StatefulWidget {
  const CommunityMessagesScreen({super.key});

  @override
  State<CommunityMessagesScreen> createState() =>
      _CommunityMessagesScreenState();
}

class _CommunityMessagesScreenState extends State<CommunityMessagesScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedFilter = 'All';
  final _messageController = TextEditingController();

  final List<String> _filters = const ['All', 'Owners', 'Volunteers', 'Vets'];

  final List<_ChatMessage> _activeMessages = [
    const _ChatMessage(
      text: 'Did Buster enjoy the new trail today?',
      isUser: false,
      timestamp: '10:30 AM',
    ),
    const _ChatMessage(
      text:
          "Buster loved his walk today! Thank you so much for taking him to the park. He's fast asleep now 😴",
      isUser: true,
      timestamp: '10:42 AM',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _activeMessages.add(
        _ChatMessage(text: text, isUser: true, timestamp: 'Just now'),
      );
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Messages',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            tooltip: 'New Message',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Start new message...')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Search & Filter Controls ───────────────────────
                AppTextField(
                  hintText: 'Search messages...',
                  prefixIcon: const Icon(Icons.search),
                ),
                AppSpacing.vGapSm,
                Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(filter),
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
                          if (selected)
                            setState(() => _selectedFilter = filter);
                        },
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── AI Chat Summary Banner ────────────────────────
                AiGradientBorderCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: scheme.primary,
                            size: AppIconSizes.md,
                          ),
                          AppSpacing.hGapSm,
                          Text(
                            'AI Summary Available',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        'Based on recent chats, Sarah usually prefers morning walks for Buster. Would you like to schedule a playdate?',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Active Chat Header ────────────────────────────
                AppCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const UserAvatar(
                          name: 'Sarah Jenkins',
                          radius: 20,
                        ),
                        title: Row(
                          children: [
                            Text(
                              'Sarah Jenkins',
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            AppSpacing.hGapXs,
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        subtitle: const Text('Online'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.call_outlined),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      AppSpacing.vGapSm,

                      // ── Chat Messages ───────────────────────────
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _activeMessages.length,
                        itemBuilder: (context, index) {
                          final msg = _activeMessages[index];
                          return Align(
                            alignment: msg.isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              constraints: const BoxConstraints(maxWidth: 300),
                              decoration: BoxDecoration(
                                color: msg.isUser
                                    ? scheme.primaryContainer
                                    : scheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.text,
                                    style: TextStyle(
                                      color: msg.isUser
                                          ? scheme.onPrimaryContainer
                                          : scheme.onSurface,
                                    ),
                                  ),
                                  AppSpacing.vGapXs,
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      msg.timestamp,
                                      style: context.textTheme.labelSmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      AppSpacing.vGapSm,

                      // ── Input Bar ───────────────────────────────
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {},
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                filled: true,
                                fillColor: scheme.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.full,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.send, color: scheme.primary),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String text;
  final bool isUser;
  final String timestamp;
}
