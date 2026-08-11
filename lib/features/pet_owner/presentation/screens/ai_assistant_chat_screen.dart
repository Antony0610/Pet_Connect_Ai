import 'package:flutter/material.dart';

import '../../../../core/theme/tokens/app_breakpoints.dart';
import '../../../../core/theme/tokens/app_icon_sizes.dart';
import '../../../../core/theme/tokens/app_radius.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../widgets/ai_widgets.dart';

/// The author of a chat message.
enum _Role { user, ai }

/// A single chat message. AI messages may carry [sources] rendered as
/// attribution chips beneath the answer.
class _ChatMessage {
  const _ChatMessage(this.role, this.text, {this.sources = const []});

  final _Role role;
  final String text;
  final List<String> sources;
}

/// **AI Assistant Chat** — `/owner/ai/chat`.
///
/// A conversational thread with the pet-care assistant. User turns are primary
/// bubbles; AI turns are encased in the signature gradient-bordered card (per
/// the frozen `DESIGN.md` rule that AI-generated content is gradient-bordered)
/// with source-attribution chips. A row of suggestion chips seeds prompts and a
/// glass composer sends messages. Token-driven, so one tree serves both themes.
class AiAssistantChatScreen extends StatefulWidget {
  const AiAssistantChatScreen({super.key});

  @override
  State<AiAssistantChatScreen> createState() => _AiAssistantChatScreenState();
}

class _AiAssistantChatScreenState extends State<AiAssistantChatScreen> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      _Role.ai,
      "Hi Sarah! I'm your PetConnect assistant. I've reviewed Buddy's latest "
      'activity and health data — ask me anything about his care.',
      sources: ['PetConnect Health Passport'],
    ),
    const _ChatMessage(_Role.user, 'Is 14 hours of sleep normal for Buddy?'),
    const _ChatMessage(
      _Role.ai,
      'Yes — adult dogs typically sleep 12–14 hours a day, and Golden '
      "Retrievers sit at the higher end. Buddy's 14 hours is right in the "
      'healthy range given his activity level.',
      sources: ['AKC Canine Sleep Guide', 'Buddy · Activity Log'],
    ),
  ];

  static const List<String> _suggestions = [
    'Analyze recent activity',
    'Diet recommendations',
    'Vaccination status',
    'Nearby vets',
  ];

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = (preset ?? _composer.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(_Role.user, text));
      _messages.add(
        const _ChatMessage(
          _Role.ai,
          "Thanks — I'm analyzing that against Buddy's records now. In the "
          'full experience this connects to the live AI service for a tailored '
          'answer with cited sources.',
          sources: ['PetConnect AI'],
        ),
      );
      _composer.clear();
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final margin = _horizontalMargin(context.screenWidth);

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: aiAppBar(
        context,
        title: 'AI Assistant',
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => context.showSnackbar('Opening chat history…'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppBreakpoints.maxContentWidth,
                ),
                child: ListView.separated(
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(
                    margin,
                    AppSpacing.md,
                    margin,
                    AppSpacing.md,
                  ),
                  itemCount: _messages.length,
                  separatorBuilder: (_, __) => AppSpacing.vGapMd,
                  itemBuilder: (_, i) => _Bubble(message: _messages[i]),
                ),
              ),
            ),
          ),
          _SuggestionBar(
            suggestions: _suggestions,
            onTap: _send,
            margin: margin,
          ),
          _Composer(controller: _composer, onSend: _send, margin: margin),
        ],
      ),
    );
  }

  static double _horizontalMargin(double width) {
    if (width < AppBreakpoints.tablet) return AppSpacing.marginMobile;
    if (width < AppBreakpoints.desktop) return AppSpacing.marginTablet;
    return AppSpacing.marginDesktop;
  }
}

/// A single chat bubble. User turns are right-aligned `primary` bubbles; AI
/// turns are left-aligned and wrapped in the gradient-bordered AI card with a
/// leading assistant avatar and trailing source chips.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isUser = message.role == _Role.user;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.screenWidth * 0.78),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: AppRadius.rXl,
                topRight: AppRadius.rXl,
                bottomLeft: AppRadius.rXl,
                bottomRight: AppRadius.rSm,
              ),
            ),
            child: Text(
              message.text,
              style: context.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.screenWidth * 0.85),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AiCircleIcon(
              icon: Icons.smart_toy_rounded,
              background: scheme.primaryContainer,
              foreground: scheme.onPrimaryContainer,
              size: 36,
            ),
            AppSpacing.hGapSm,
            Flexible(
              child: AiGradientBorderCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    if (message.sources.isNotEmpty) ...[
                      AppSpacing.vGapSm,
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final s in message.sources)
                            AiSourceChip(
                              label: s,
                              onTap: () =>
                                  context.showSnackbar('Opening source: $s'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontally-scrolling row of suggestion chips that seed prompts.
class _SuggestionBar extends StatelessWidget {
  const _SuggestionBar({
    required this.suggestions,
    required this.onTap,
    required this.margin,
  });

  final List<String> suggestions;
  final ValueChanged<String> onTap;
  final double margin;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: margin),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => AppSpacing.hGapSm,
        itemBuilder: (_, i) {
          final label = suggestions[i];
          return ActionChip(
            label: Text(label),
            labelStyle: context.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: AppTypography.medium,
            ),
            backgroundColor: scheme.surfaceContainerHighest,
            side: BorderSide(color: scheme.outlineVariant),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.brPill),
            onPressed: () => onTap(label),
          );
        },
      ),
    );
  }
}

/// The glass composer docked to the bottom: a text field and a filled send
/// button, on a blurred surface with a hairline top edge.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.margin,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final double margin;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        margin,
        AppSpacing.sm,
        margin,
        AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: onSend,
                decoration: InputDecoration(
                  hintText: 'Ask about Buddy…',
                  filled: true,
                  fillColor: scheme.surfaceContainerHigh,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.brSection,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            AppSpacing.hGapSm,
            IconButton.filled(
              onPressed: () => onSend(controller.text),
              icon: const Icon(Icons.send_rounded, size: AppIconSizes.md),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }
}
