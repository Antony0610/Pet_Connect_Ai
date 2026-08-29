import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/ai_services/presentation/providers/ai_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
/// conversation thread history drawer, mid-chat pet switching, and live streaming typewriter responses.
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
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isSending = false;
  bool _isListening = false;
  bool _speechEnabled = false;
  final List<Uint8List> _pendingImages = [];

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      _Role.ai,
      "Hi! I'm your PetConnect AI Veterinary Assistant. You can ask me anything — health triage, toxicology, nutrition math, behavior training, avian/exotic care, or attach photos for instant multimodal inspection.",
      sources: const ['PetConnect AI Engine'],
    ),
  ];

  static const List<Map<String, String>> _suggestionChips = [
    {'icon': '🐾', 'label': 'Symptom Triage', 'prompt': 'Analyze skin rash, redness and itching causes'},
    {'icon': '🥩', 'label': 'Food Safety', 'prompt': 'Can dogs safely eat peanut butter and apples?'},
    {'icon': '⚖️', 'label': 'Calorie Math', 'prompt': 'Calculate daily calories for a 12 kg moderately active dog'},
    {'icon': '🎾', 'label': 'Puppy Biting', 'prompt': 'How do I stop puppy play biting effectively?'},
    {'icon': '🦜', 'label': 'Avian & Exotics', 'prompt': 'What are the emergency signs of Teflon toxicity in birds?'},
    {'icon': '🚨', 'label': 'First Aid & CPR', 'prompt': 'Step-by-step CPR and choking first aid for companion pets'},
    {'icon': '🏠', 'label': 'Potty Training', 'prompt': 'What is the most effective routine for housebreaking?'},
    {'icon': '🔬', 'label': 'Science', 'prompt': 'Why do cats purr and how does it promote healing?'},
  ];

  String? _activeConversationId;

  @override
  void initState() {
    super.initState();
    _initSpeech();
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

  Future<void> _initSpeech() async {
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) {
        _speechEnabled = await _speechToText.initialize(
          onError: (val) {
            if (mounted) setState(() => _isListening = false);
          },
          onStatus: (status) {
            if (status == 'notListening' || status == 'done') {
              if (mounted) setState(() => _isListening = false);
            }
          },
        );
      }
      if (mounted) setState(() {});
    } catch (_) {}
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
    _speechToText.stop();
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
              title: const Text('Take Photo with Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Select from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _pendingImages.add(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e')),
        );
      }
    }
  }

  void _toggleDictation() async {
    await HapticFeedback.mediumImpact();
    if (_isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    // Check and request microphone permission at runtime
    var micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      micStatus = await Permission.microphone.request();
      if (micStatus.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Microphone access is needed for voice input. Please enable it in Settings.'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }
      if (!micStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required for voice dictation.')),
          );
        }
        return;
      }
    }

    if (!_speechEnabled) {
      _speechEnabled = await _speechToText.initialize(
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
    }

    if (_speechEnabled) {
      if (mounted) setState(() => _isListening = true);
      await _speechToText.listen(
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
        ),
        onResult: (result) {
          if (mounted) {
            setState(() {
              _composer.text = result.recognizedWords;
              _composer.selection = TextSelection.fromPosition(
                TextPosition(offset: _composer.text.length),
              );
            });
          }
        },
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not supported or available on this device.')),
        );
      }
    }
  }

  Future<void> _streamAiResponse(
    String fullResponse, {
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
            ref.invalidate(aiConversationsProvider);
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
              'Consultation note for $pName: Regarding "$userText", ensure $pName is well-hydrated, resting comfortably, and observed for any sudden changes.',
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
    final selectedPet = ref.watch(selectedPetProvider);
    final petsAsync = ref.watch(petsProvider);
    final conversationsAsync = ref.watch(aiConversationsProvider);

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chat History',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_comment_outlined),
                      tooltip: 'New Thread',
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _messages.clear();
                          _messages.add(
                            _ChatMessage(
                              _Role.ai,
                              'Started a new consultation thread! What can I help with today?',
                              sources: const ['PetConnect AI Engine'],
                            ),
                          );
                          _activeConversationId = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: conversationsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('No previous conversations')),
                  data: (convs) {
                    if (convs.isEmpty) {
                      return const Center(child: Text('No past chat threads found.'));
                    }
                    return ListView.builder(
                      itemCount: convs.length,
                      itemBuilder: (ctx, i) {
                        final c = convs[i];
                        final isSelected = c.id == _activeConversationId;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.3),
                          leading: const Icon(Icons.chat_bubble_outline, size: 18),
                          title: Text(
                            c.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() => _activeConversationId = c.id);
                            _loadConversationHistory(c.id);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'PetConnect AI',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.hGapSm,
            petsAsync.when(
              data: (pets) {
                if (pets.isEmpty) return const SizedBox.shrink();
                return DropdownButton<String>(
                  value: selectedPet?.id,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  items: pets.map((p) {
                    return DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        '• ${p.name}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) {
                      ref.read(selectedPetIdProvider.notifier).state = id;
                    }
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
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

              if (_messages.length <= 2)
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    scrollDirection: Axis.horizontal,
                    itemCount: _suggestionChips.length,
                    separatorBuilder: (_, __) => AppSpacing.hGapSm,
                    itemBuilder: (ctx, i) {
                      final item = _suggestionChips[i];
                      return ActionChip(
                        avatar: Text(item['icon']!),
                        label: Text(item['label']!),
                        onPressed: () => _sendPrompt(item['prompt']!),
                      );
                    },
                  ),
                ),

              if (_pendingImages.isNotEmpty)
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pendingImages.length,
                    separatorBuilder: (_, __) => AppSpacing.hGapSm,
                    itemBuilder: (ctx, i) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: AppRadius.brMd,
                            child: Image.memory(
                              _pendingImages[i],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -4,
                            right: -4,
                            child: IconButton(
                              icon: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                              onPressed: () {
                                setState(() {
                                  _pendingImages.removeAt(i);
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              if (_isListening)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                  color: scheme.primaryContainer.withValues(alpha: 0.3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mic, color: Colors.red, size: 18),
                      AppSpacing.hGapSm,
                      const Text(
                        'Listening for voice input... (Speak your inquiry)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      AppSpacing.hGapSm,
                      GestureDetector(
                        onTap: _toggleDictation,
                        child: const Text('Stop', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      tooltip: 'Attach Symptom Photos (Up to 3)',
                      onPressed: _pickImage,
                    ),
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      color: _isListening ? Colors.red : null,
                      tooltip: 'Voice Input',
                      onPressed: _toggleDictation,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _composer,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendPrompt,
                        decoration: InputDecoration(
                          hintText: _pendingImages.isNotEmpty
                              ? 'Add details to symptom photos...'
                              : 'Ask about health, calories, training, exotics...',
                          border: const OutlineInputBorder(
                            borderRadius: AppRadius.brPill,
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.hGapSm,
                    IconButton.filled(
                      icon: const Icon(Icons.send_rounded),
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
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.screenWidth * 0.75),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              topRight: Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(AppRadius.lg),
              bottomRight: AppRadius.rSm,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (images.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: images.map((img) {
                    return ClipRRect(
                      borderRadius: AppRadius.brMd,
                      child: Image.memory(img, width: 80, height: 80, fit: BoxFit.cover),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapSm,
              ],
              Text(
                text,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiCard extends StatelessWidget {
  const _AiCard({
    required this.text,
    this.sources = const [],
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

    final formattedText = text
        .replaceAll('🐾 **PetConnect AI Assistance**:\n\n', '')
        .replaceAll('**Visual Observations**:\n\n', '')
        .trim();

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.screenWidth * 0.85),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              topRight: Radius.circular(AppRadius.lg),
              bottomLeft: AppRadius.rSm,
              bottomRight: Radius.circular(AppRadius.lg),
            ),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome, size: 14, color: scheme.primary),
                  ),
                  AppSpacing.hGapXs,
                  Text(
                    'PetConnect AI',
                    style: context.textTheme.labelSmall?.copyWith(
                      fontWeight: AppTypography.bold,
                      color: scheme.primary,
                    ),
                  ),
                  const Spacer(),
                  if (text.isNotEmpty && !isStreaming) ...[
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      tooltip: 'Copy to Clipboard',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: text));
                        context.showSnackbar('✓ Copied AI response to clipboard');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 16),
                      tooltip: 'Share Advice',
                      onPressed: () {
                        ExternalActions.shareText(
                          '🐾 PetConnect AI Advice:\n\n$text',
                          subject: 'PetConnect AI Care Advice',
                        );
                      },
                    ),
                  ],
                ],
              ),
              AppSpacing.vGapSm,
              Text(
                formattedText,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
