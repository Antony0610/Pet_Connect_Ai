import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/ai_services/presentation/providers/ai_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';

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
class AiAssistantChatScreen extends ConsumerStatefulWidget {
  const AiAssistantChatScreen({super.key});

  @override
  ConsumerState<AiAssistantChatScreen> createState() =>
      _AiAssistantChatScreenState();
}

class _AiAssistantChatScreenState extends ConsumerState<AiAssistantChatScreen> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _isSending = false;

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      _Role.ai,
      "Hi! I'm your PetConnect AI assistant. How can I assist you with your pet's health and wellness today?",
      sources: ['PetConnect AI Engine'],
    ),
  ];

  static const List<String> _suggestions = [
    'Analyze recent activity',
    'Vaccination schedule',
    'Dietary tips',
    'Sleep habits',
  ];

  String? _activeConversationId;

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _sendPrompt(String prompt) async {
    if (prompt.trim().isEmpty || _isSending) return;

    final userText = prompt.trim();
    _composer.clear();

    setState(() {
      _messages.add(_ChatMessage(_Role.user, userText));
      _isSending = true;
    });

    _scrollToBottom();

    try {
      final repo = ref.read(aiRepositoryProvider);

      if (_activeConversationId == null) {
        final convResult = await repo.createConversation(
          title: userText.length > 25
              ? '${userText.substring(0, 25)}...'
              : userText,
        );
        convResult.fold((_) {}, (conv) {
          _activeConversationId = conv.id;
        });
      }

      final convId =
          _activeConversationId ??
          'session-${DateTime.now().millisecondsSinceEpoch}';

      final result = await repo.sendChatMessage(
        conversationId: convId,
        prompt: userText,
      );

      result.fold(
        (failure) {
          setState(() {
            _messages.add(
              _ChatMessage(
                _Role.ai,
                'I am currently experiencing connectivity issues: ${failure.message}. Please try again shortly.',
                sources: const ['Error Handler'],
              ),
            );
          });
        },
        (aiMsg) {
          setState(() {
            _messages.add(
              _ChatMessage(
                _Role.ai,
                aiMsg.messageText,
                sources: const ['Gemini 1.5 Flash via Edge Function'],
              ),
            );
          });
        },
      );
    } catch (e) {
      setState(() {
        _messages.add(
          _ChatMessage(
            _Role.ai,
            'Request failed: $e',
            sources: ['System Error'],
          ),
        );
      });
    } finally {
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDesktop = context.screenWidth >= AppBreakpoints.desktop;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Pet Assistant'), centerTitle: false),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _messages.length,
                  separatorBuilder: (_, __) => AppSpacing.vGapMd,
                  itemBuilder: (ctx, i) {
                    final m = _messages[i];
                    return m.role == _Role.user
                        ? _UserBubble(text: m.text)
                        : _AiCard(text: m.text, sources: m.sources);
                  },
                ),
              ),

              if (_isSending)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: LinearProgressIndicator(),
                ),

              // Suggestions Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: _suggestions.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ActionChip(
                        label: Text(s),
                        onPressed: () => _sendPrompt(s),
                      ),
                    );
                  }).toList(),
                ),
              ),

              AppSpacing.vGapSm,

              // Composer Row
              Padding(
                padding: EdgeInsets.all(
                  isDesktop ? AppSpacing.md : AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _composer,
                        decoration: const InputDecoration(
                          hintText: 'Ask your AI assistant anything...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: _sendPrompt,
                      ),
                    ),
                    AppSpacing.hGapSm,
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: scheme.primary,
                      onPressed: () => _sendPrompt(_composer.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(text, style: TextStyle(color: scheme.onPrimary)),
      ),
    );
  }
}

class _AiCard extends StatelessWidget {
  const _AiCard({required this.text, required this.sources});
  final String text;
  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    return AiGradientBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          if (sources.isNotEmpty) ...[
            AppSpacing.vGapSm,
            Wrap(
              spacing: 6,
              children: sources
                  .map(
                    (s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
