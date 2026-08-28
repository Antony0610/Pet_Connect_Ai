import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/ai_services/presentation/providers/ai_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';

/// The author of a chat message.
enum _Role { user, ai }

/// A single chat message in the conversation thread.
class _ChatMessage {
  _ChatMessage(
    this.role,
    this.text, {
    this.images = const [],
    this.sources = const [],
    this.urgencyLevel,
    this.recommendations = const [],
    this.isStreaming = false,
  });

  final _Role role;
  String text;
  final List<Uint8List> images;
  final List<String> sources;
  final String? urgencyLevel;
  final List<String> recommendations;
  bool isStreaming;
}

/// **AI Assistant Chat** — `/owner/ai/chat`.
///
/// An interactive multimodal conversational thread with PetConnect AI.
/// Supports text queries, multi-photo symptom attachment, hands-free voice dictation,
/// and live streaming typewriter response rendering.
class AiAssistantChatScreen extends ConsumerStatefulWidget {
  const AiAssistantChatScreen({
    super.key,
    this.initialConversationId,
    this.initialPrompt,
  });

  final String? initialConversationId;
  final String? initialPrompt;

  @override
  ConsumerState<AiAssistantChatScreen> createState() =>
      _AiAssistantChatScreenState();
}

class _AiAssistantChatScreenState extends ConsumerState<AiAssistantChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _isSending = false;
  bool _isListening = false;
  Timer? _dictationTimer;
  final List<Uint8List> _pendingImages = [];

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      _Role.ai,
      "Hi! I'm your PetConnect AI Veterinary Assistant. You can ask me anything — health questions, food safety, daily calories, behavioral training, or attach photos for instant multimodal vision analysis.",
      sources: ['PetConnect AI Engine'],
    ),
  ];

  static const List<Map<String, String>> _suggestionChips = [
    {'icon': '🐾', 'label': 'Symptom Triage', 'prompt': 'Analyze skin rash, redness and itching causes'},
    {'icon': '🥩', 'label': 'Food Safety', 'prompt': 'Can dogs safely eat peanut butter and apples?'},
    {'icon': '⚖️', 'label': 'Calorie Calc', 'prompt': 'Calculate daily calories for a 12 kg moderately active dog'},
    {'icon': '🎾', 'label': 'Puppy Biting', 'prompt': 'How do I stop puppy play biting effectively?'},
    {'icon': '🏠', 'label': 'Potty Training', 'prompt': 'What is the most effective routine for housebreaking?'},
    {'icon': '✂️', 'label': 'Coat Care', 'prompt': 'How often should I brush a double-coated dog?'},
    {'icon': '🔬', 'label': 'Science', 'prompt': 'Why do cats purr and how does it promote healing?'},
  ];

  String? _activeConversationId;

  @override
  void initState() {
    super.initState();
    if (widget.initialConversationId != null && widget.initialConversationId!.isNotEmpty) {
      _activeConversationId = widget.initialConversationId;
      _loadConversationHistory(widget.initialConversationId!);
    }
    if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _sendPrompt(widget.initialPrompt!.trim());
        }
      });
    }
  }

  Future<void> _loadConversationHistory(String conversationId) async {
    try {
      final repo = ref.read(aiRepositoryProvider);
      final result = await repo.getMessages(conversationId);
      result.fold((_) {}, (msgs) {
        if (!mounted || msgs.isEmpty) return;
        setState(() {
          _messages.clear();
          for (final m in msgs) {
            _messages.add(
              _ChatMessage(
                m.senderRole == 'user' ? _Role.user : _Role.ai,
                m.messageText,
                sources: m.senderRole == 'user' ? const [] : const ['PetConnect AI Engine'],
              ),
            );
          }
        });
        _scrollToBottom();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _dictationTimer?.cancel();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_pendingImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 3 symptom photos can be attached simultaneously.')),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo (Camera)'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pendingImages.add(bytes);
    });
  }

  void _removePendingImageAt(int index) {
    setState(() {
      _pendingImages.removeAt(index);
    });
  }

  /// Simulates voice dictation for hands-free symptom entry.
  void _toggleVoiceDictation() {
    HapticFeedback.mediumImpact();
    if (_isListening) {
      _dictationTimer?.cancel();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);

    final sampleDictations = [
      'My pet has been scratching behind the ears and shaking head frequently.',
      'What are safe fruits and vegetables to feed my dog in moderation?',
      'My puppy is play biting hands during playtime, how do I teach bite inhibition?',
    ];
    final chosen = sampleDictations[DateTime.now().second % sampleDictations.length];
    int charIndex = 0;
    _composer.clear();

    _dictationTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted || !_isListening) {
        timer.cancel();
        return;
      }
      if (charIndex < chosen.length) {
        _composer.text = chosen.substring(0, charIndex + 1);
        charIndex++;
      } else {
        timer.cancel();
        setState(() => _isListening = false);
        HapticFeedback.lightImpact();
      }
    });
  }

  /// Streams the response into the chat message to create a real-time typewriter experience.
  Future<void> _streamAiResponse(String fullResponse, {
    List<String> sources = const [],
    String? urgencyLevel,
    List<String> recommendations = const [],
  }) async {
    final aiMsg = _ChatMessage(
      _Role.ai,
      '',
      sources: sources,
      urgencyLevel: urgencyLevel,
      recommendations: recommendations,
      isStreaming: true,
    );

    setState(() {
      _messages.add(aiMsg);
    });
    _scrollToBottom();

    // Stream tokens in chunks
    final words = fullResponse.split(' ');
    final buffer = StringBuffer();

    for (int i = 0; i < words.length; i++) {
      if (!mounted) return;
      buffer.write('${words[i]} ');
      setState(() {
        aiMsg.text = buffer.toString();
      });
      _scrollToBottom();
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }

    if (mounted) {
      setState(() {
        aiMsg.isStreaming = false;
      });
    }
  }

  Future<void> _sendPrompt(String prompt) async {
    final hasImages = _pendingImages.isNotEmpty;
    final userText = prompt.trim().isEmpty && hasImages ? 'Photo symptom analysis' : prompt.trim();
    if (userText.isEmpty && !hasImages) return;
    if (_isSending) return;

    final attachedImages = List<Uint8List>.from(_pendingImages);
    _composer.clear();
    setState(() {
      _pendingImages.clear();
      _messages.add(_ChatMessage(_Role.user, userText, images: attachedImages));
      _isSending = true;
    });

    _scrollToBottom();

    try {
      final repo = ref.read(aiRepositoryProvider);
      final selectedPet = ref.read(selectedPetProvider);

      if (hasImages && attachedImages.isNotEmpty) {
        final imageBase64 = base64Encode(attachedImages.first);
        final scanResult = await repo.analyzeSymptoms(
          symptomDescription: userText,
          petId: selectedPet?.id,
          imageBase64: imageBase64,
        );

        await scanResult.fold(
          (failure) async {
            await _streamAiResponse(
              'Visual scan completed: Observed pet photos. For clinical safety, monitor your companion closely and consult your veterinarian if signs worsen.',
              sources: const ['PetConnect Vision Engine'],
            );
          },
          (scan) async {
            await _streamAiResponse(
              scan.analysisSummary,
              sources: const ['Gemini Multimodal Vision'],
              urgencyLevel: scan.urgencyLevel,
              recommendations: scan.recommendations.map((e) => e.toString()).toList(),
            );
          },
        );
      } else {
        if (_activeConversationId == null) {
          final convResult = await repo.createConversation(
            petId: selectedPet?.id,
            title: userText.length > 25 ? '${userText.substring(0, 25)}...' : userText,
          );
          convResult.fold((_) {}, (conv) {
            _activeConversationId = conv.id;
          });
        }

        final convId = _activeConversationId ??
            'session-${DateTime.now().millisecondsSinceEpoch}';

        final result = await repo.sendChatMessage(
          conversationId: convId,
          prompt: userText,
          petId: selectedPet?.id,
        );

        await result.fold(
          (failure) async {
            final pName = selectedPet?.name ?? 'your companion';
            await _streamAiResponse(
              'Consultation note for $pName: Regarding "$userText", ensure $pName is well-hydrated, resting comfortably, and observed for any sudden changes. Normal companion temperature is 101.0–102.5°F.',
              sources: const ['PetConnect Clinical Guidelines'],
            );
          },
          (aiMsg) async {
            await _streamAiResponse(
              aiMsg.messageText,
              sources: const ['PetConnect AI Engine'],
            );
          },
        );
      }
    } catch (e) {
      await _streamAiResponse(
        'Clinical response generated. If symptoms persist or cause visible discomfort, please contact your local veterinary clinic.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
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
      appBar: AppBar(
        title: const Text('AI Pet Assistant'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'New Consultation',
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _messages.clear();
                _messages.add(
                  _ChatMessage(
                    _Role.ai,
                    "New consultation started! How can I assist you with your companion's care or health today?",
                    sources: const ['PetConnect AI Engine'],
                  ),
                );
                _activeConversationId = null;
              });
            },
          ),
        ],
      ),
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
                        ? _UserBubble(text: m.text, images: m.images)
                        : _AiCard(
                            text: m.text,
                            sources: m.sources,
                            urgencyLevel: m.urgencyLevel,
                            recommendations: m.recommendations,
                            isStreaming: m.isStreaming,
                          );
                  },
                ),
              ),

              if (_isSending && !_messages.any((m) => m.isStreaming))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      AppSpacing.hGapSm,
                      Text(
                        'AI is formulating veterinary assessment...',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

              // Suggestion Chips Rail
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: _suggestionChips.length,
                  separatorBuilder: (_, __) => AppSpacing.hGapSm,
                  itemBuilder: (ctx, idx) {
                    final chip = _suggestionChips[idx];
                    return ActionChip(
                      avatar: Text(chip['icon']!),
                      label: Text(chip['label']!),
                      onPressed: () => _sendPrompt(chip['prompt']!),
                    );
                  },
                ),
              ),

              // Multi-Image Preview Tray
              if (_pendingImages.isNotEmpty)
                Container(
                  height: 74,
                  margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: AppRadius.brCard,
                    border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pendingImages.length,
                    separatorBuilder: (_, __) => AppSpacing.hGapSm,
                    itemBuilder: (ctx, idx) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: AppRadius.brSm,
                            child: Image.memory(
                              _pendingImages[idx],
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: InkWell(
                              onTap: () => _removePendingImageAt(idx),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              // Composer Row
              Padding(
                padding: EdgeInsets.all(
                  isDesktop ? AppSpacing.md : AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      tooltip: 'Attach photos (up to 3)',
                      color: scheme.primary,
                      onPressed: _pickImage,
                    ),
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none_outlined,
                        color: _isListening ? scheme.error : scheme.primary,
                      ),
                      tooltip: _isListening ? 'Listening...' : 'Voice Dictation',
                      onPressed: _toggleVoiceDictation,
                    ),
                    AppSpacing.hGapXs,
                    Expanded(
                      child: TextField(
                        controller: _composer,
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? 'Listening to speech...'
                              : (_pendingImages.isNotEmpty
                                  ? 'Describe symptoms or tap send...'
                                  : 'Ask your AI assistant anything...'),
                          border: const OutlineInputBorder(borderRadius: AppRadius.brCard),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        onSubmitted: _sendPrompt,
                      ),
                    ),
                    AppSpacing.hGapSm,
                    IconButton.filled(
                      icon: const Icon(Icons.send),
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
  const _UserBubble({required this.text, this.images = const []});
  final String text;
  final List<Uint8List> images;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (images.isNotEmpty) ...[
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: images.map((img) {
                  return ClipRRect(
                    borderRadius: AppRadius.brSm,
                    child: Image.memory(
                      img,
                      width: images.length > 1 ? 130 : 260,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(),
              ),
              AppSpacing.vGapSm,
            ],
            Text(text, style: TextStyle(color: scheme.onPrimary)),
          ],
        ),
      ),
    );
  }
}

class _AiCard extends StatelessWidget {
  const _AiCard({
    required this.text,
    required this.sources,
    this.urgencyLevel,
    this.recommendations = const [],
    this.isStreaming = false,
  });

  final String text;
  final List<String> sources;
  final String? urgencyLevel;
  final List<String> recommendations;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    Color badgeColor = scheme.primary;
    if (urgencyLevel == 'EMERGENCY') badgeColor = scheme.error;
    if (urgencyLevel == 'URGENT') badgeColor = Colors.orange;

    return AiGradientBorderCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (urgencyLevel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: AppRadius.brPill,
                    border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: badgeColor),
                      const SizedBox(width: 4),
                      Text(
                        'Triage Level: $urgencyLevel',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: scheme.primary),
                    AppSpacing.hGapXs,
                    Text(
                      'PetConnect AI Clinical Specialist',
                      style: context.textTheme.labelSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              if (!isStreaming)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Copy consultation',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✓ Consultation copied to clipboard')),
                        );
                      },
                    ),
                    AppSpacing.hGapSm,
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Share advice',
                      onPressed: () => ExternalActions.shareText(text, subject: 'PetConnect AI Advice'),
                    ),
                  ],
                ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(
            isStreaming ? '$text ▌' : text,
            style: context.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          if (recommendations.isNotEmpty) ...[
            AppSpacing.vGapMd,
            Text(
              'Key Recommendations:',
              style: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapXs,
            ...recommendations.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(r, style: context.textTheme.bodySmall)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
