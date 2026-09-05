import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/ai_services/presentation/providers/ai_providers.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_mascot_companion.dart';
import 'package:petconnect_ai/features/smart_collar/presentation/providers/smart_collar_providers.dart';
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
/// An open-domain conversational thread with PetConnect AI powered by Google Gemini.
/// Supports universal question answering (coding, calculations, general knowledge, trivia, writing)
/// and specialized clinical veterinary diagnostics, multi-photo symptom inspection, voice dictation,
/// and rich Markdown rendering with code blocks, bold headers, and copy actions.
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

class _AiModelOption {
  final String key;
  final String label;
  final String subtitle;
  final String tag;
  final Color color;
  final IconData icon;

  const _AiModelOption({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.tag,
    required this.color,
    required this.icon,
  });
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
  String? _lastUserPrompt;
  String _dictationLocale = 'en_IN'; // Default to English, toggleable to Malayalam 'ml_IN' or Auto

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      _Role.ai,
      '👋 Hello! I am PetConnect AI, your companion AI assistant.\n\n'
      'Feel free to ask me **anything** — health symptoms, nutrition, behavior training, general knowledge, science, translations, and more. You can also attach photos for visual inspection!',
      sources: const ['PetConnect AI'],
    ),
  ];

  static const List<Map<String, String>> _suggestionChips = [
    {'icon': '🐾', 'label': 'Symptom Triage', 'prompt': 'Analyze skin rash, redness and itching causes in dogs'},
    {'icon': '🥩', 'label': 'Food Safety', 'prompt': 'Can dogs safely eat peanut butter, apples, and blueberries?'},
    {'icon': '⚖️', 'label': 'Calorie Math', 'prompt': 'Calculate daily RER and MER calories for a 12 kg moderately active dog'},
    {'icon': '🔬', 'label': 'Science', 'prompt': 'Explain how quantum computing works in simple terms'},
    {'icon': '💻', 'label': 'Python Code', 'prompt': 'Write a Python function to find the longest palindromic substring'},
    {'icon': '🦜', 'label': 'Avian Care', 'prompt': 'What are the emergency signs of Teflon/PTFE toxicity in pet birds?'},
    {'icon': '🏠', 'label': 'Puppy Biting', 'prompt': 'How do I stop puppy play biting and teach bite inhibition effectively?'},
    {'icon': '🌐', 'label': 'Kerala Cats', 'prompt': 'Recommend the best cat breeds for Kerala climate and apartment living'},
  ];

  String? _activeConversationId;
  String _selectedModelKey = 'gemini-3.8-flash';
  String _activeModelLabel = '⚡ Flash 3.8';
  bool _showScrollToBottom = false;

  static const List<_AiModelOption> _topGeminiModels = [
    _AiModelOption(
      key: 'gemini-3.8-flash',
      label: 'Gemini 3.8 Flash',
      subtitle: 'Flagship next-gen multimodal model with deep clinical reasoning',
      tag: 'Flagship',
      color: Color(0xFF6366F1),
      icon: Icons.auto_awesome_rounded,
    ),
    _AiModelOption(
      key: 'gemini-3.7-flash',
      label: 'Gemini 3.7 Flash',
      subtitle: 'High-performance multimodal clinical reasoning & diagnostic triage',
      tag: 'Advanced',
      color: Color(0xFF8B5CF6),
      icon: Icons.psychology_rounded,
    ),
    _AiModelOption(
      key: 'gemini-3.6-flash',
      label: 'Gemini 3.6 Flash',
      subtitle: 'Next-gen high-throughput multimodal intelligence',
      tag: 'Balanced',
      color: Color(0xFF06B6D4),
      icon: Icons.flare_rounded,
    ),
    _AiModelOption(
      key: 'gemini-3.5-flash-lite',
      label: 'Gemini 3.5 Flash-Lite',
      subtitle: 'Sub-second ~1s latency for instant response & rapid triage',
      tag: 'Ultra-Fast',
      color: Color(0xFF10B981),
      icon: Icons.bolt_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedModel();
    _initSpeech();
    _scroll.addListener(_handleScrollListener);
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

  void _loadSavedModel() {
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getString('app_selected_gemini_model');
    if (saved != null && saved.isNotEmpty) {
      final match = _topGeminiModels.firstWhere(
        (m) => m.key == saved,
        orElse: () => _topGeminiModels.first,
      );
      setState(() {
        _selectedModelKey = match.key;
        _activeModelLabel = match.tag == 'Ultra-Fast'
            ? '⚡ Flash 3.5'
            : '⚡ ${match.label.replaceAll('Gemini ', '')}';
      });
    }
    final savedLocale = prefs.getString('app_voice_dictation_locale');
    if (savedLocale != null && savedLocale.isNotEmpty) {
      setState(() {
        _dictationLocale = savedLocale;
      });
    }
  }

  void _showModelSelectionModal(BuildContext context) {
    HapticFeedback.lightImpact();
    final scheme = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.72,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.tune_rounded, color: scheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select AI Intelligence Model',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurface,
                            ),
                          ),
                          Text(
                            'Choose the optimal Gemini engine for your session',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _topGeminiModels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final option = _topGeminiModels[i];
                      final isSelected = _selectedModelKey == option.key;

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          await HapticFeedback.mediumImpact();
                          setState(() {
                            _selectedModelKey = option.key;
                            _activeModelLabel = '⚡ ${option.label.replaceAll('Gemini ', '')}';
                          });
                          await ref.read(sharedPreferencesProvider).setString(
                                'app_selected_gemini_model',
                                option.key,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? option.color.withValues(alpha: 0.12)
                                : scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? option.color
                                  : scheme.outlineVariant.withValues(alpha: 0.4),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: option.color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(option.icon, color: option.color, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          option.label,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.5,
                                            color: isSelected ? option.color : scheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: option.color.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            option.tag,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: option.color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      option.subtitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, color: option.color, size: 22),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleScrollListener() {
    if (!_scroll.hasClients) return;
    final isScrolledUp = (_scroll.position.maxScrollExtent - _scroll.offset) > 160;
    if (isScrolledUp != _showScrollToBottom && mounted) {
      setState(() => _showScrollToBottom = isScrolledUp);
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
                sources: m.senderRole == 'user' ? const [] : const ['Gemini Omni-Intelligence'],
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
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
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
          localeId: _dictationLocale == 'auto' ? null : _dictationLocale,
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

  String _buildAppRagContext() {
    final buffer = StringBuffer();
    try {
      final authUser = ref.read(supabaseClientProvider).auth.currentUser;
      final profile = ref.read(currentUserProfileProvider).valueOrNull;

      final userName = profile?.fullName ??
          authUser?.userMetadata?['full_name'] as String? ??
          authUser?.email?.split('@').first ??
          'Pet Parent';

      final userCity = profile?.city ?? 'Meladoor, Kerala, India';
      final lat = profile?.latitude ?? 10.2740;
      final lng = profile?.longitude ?? 76.3216;
      final now = DateTime.now().toLocal();

      buffer.writeln('PET OWNER USER PROFILE & LIVE GEOGRAPHIC LOCATION:');
      buffer.writeln('- Name: $userName');
      buffer.writeln('- Email: ${authUser?.email ?? "Not specified"}');
      buffer.writeln('- Home City / Region: $userCity');
      buffer.writeln('- Exact GPS Coordinates: $lat° N, $lng° E');
      buffer.writeln('- Current Date & Local Time: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}');
      buffer.writeln('- INSTRUCTION FOR WEATHER & OUTDOOR QUERIES: When the user asks about the weather, climate, current temperature, rain forecast, or safe pet walking times, ALWAYS use this exact location ($userCity, Coordinates: $lat, $lng) to provide accurate real-time weather assessments, temperature, humidity, walking recommendations (avoiding hot pavement during peak hours), and rain/heat warnings.');
    } catch (_) {}

    try {
      final allPets = ref.read(petsProvider).valueOrNull ?? [];
      final selectedPet = ref.read(selectedPetProvider);

      buffer.writeln('\nREGISTERED PETS IN OWNER HOUSEHOLD (${allPets.length}):');
      if (allPets.isEmpty && selectedPet != null) {
        buffer.writeln(
          '- Active Selected Pet: ${selectedPet.name} (Species: ${selectedPet.species}, Breed: ${selectedPet.breed ?? "Not specified"}, Gender: ${selectedPet.gender}, Age/DOB: ${selectedPet.dateOfBirth ?? "Unknown"}, Weight: ${selectedPet.weightKg != null ? "${selectedPet.weightKg} kg" : "N/A"}, Health Status: ${selectedPet.healthStatus})',
        );
      } else if (allPets.isEmpty) {
        buffer.writeln('- No pets registered in local profile yet.');
      } else {
        for (final p in allPets) {
          final isSelected = selectedPet?.id == p.id;
          final dobStr = p.dateOfBirth != null
              ? '${p.dateOfBirth!.year}-${p.dateOfBirth!.month.toString().padLeft(2, "0")}-${p.dateOfBirth!.day.toString().padLeft(2, "0")}'
              : 'Unknown';
          buffer.writeln(
            '- ${isSelected ? "[ACTIVE SELECTED COMPANION] " : ""}${p.name}: Species: ${p.species}, Breed: ${p.breed ?? "Unknown"}, Gender: ${p.gender}, DOB: $dobStr, Weight: ${p.weightKg ?? "N/A"} kg, Health Status: ${p.healthStatus}',
          );
        }
      }
    } catch (_) {}

    try {
      final collars = ref.read(registeredCollarsProvider).valueOrNull ?? [];
      if (collars.isNotEmpty) {
        buffer.writeln('\nSMART COLLAR & IOT TELEMETRY:');
        for (final c in collars) {
          buffer.writeln(
            '- Smart Collar Device: ${c.deviceId} (ID: ${c.id}), Battery: ${c.batteryPercentage}%, Protocol: ${c.connectivityType}, Lost Mode: ${c.isLostMode ? "Active" : "Normal"}, Pet ID: ${c.petId ?? "Assigned"}',
          );
        }
      }
    } catch (_) {}

    try {
      final healthScans = ref.read(aiHealthScansProvider).valueOrNull ?? [];
      if (healthScans.isNotEmpty) {
        buffer.writeln('\nRECENT CLINICAL AI HEALTH SCANS & VET ASSESSMENTS:');
        for (final s in healthScans.take(3)) {
          final dateStr = s.createdAt.toIso8601String().split('T').first;
          final cleanSummary = s.analysisSummary.replaceAll('\n', ' ').trim();
          final summarySnippet = cleanSummary.length > 120
              ? '${cleanSummary.substring(0, 120)}...'
              : cleanSummary;
          buffer.writeln(
            '- Date: $dateStr | Urgency: ${s.urgencyLevel} | Scan Summary: $summarySnippet | Recommendations: ${s.recommendations.take(2).join("; ")}',
          );
        }
      }
    } catch (_) {}

    return buffer.toString();
  }

  Future<void> _streamAiResponse(
    String fullResponse, {
    List<String> sources = const ['Gemini Omni-Intelligence'],
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
    const batchSize = 3; // Multi-word batched streaming for instantaneous fluid rendering

    for (int i = 0; i < words.length; i += batchSize) {
      if (!mounted) return;
      final end = (i + batchSize < words.length) ? i + batchSize : words.length;
      for (int j = i; j < end; j++) {
        buffer.write('${words[j]} ');
      }
      setState(() {
        aiMsg.text = buffer.toString();
      });
      _scrollToBottom();
      await Future<void>.delayed(const Duration(milliseconds: 2));
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

    _lastUserPrompt = userText;
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
        final visualPrompt = userText == 'Photo symptom analysis' || userText.trim().isEmpty
            ? 'Please thoroughly examine this pet photo. Identify the species and breed, inspect facial features, eyes, coat condition, and posture, and provide detailed veterinary visual observations and care recommendations.'
            : userText;

        final scanResult = await repo.analyzeSymptoms(
          symptomDescription: visualPrompt,
          petId: selectedPet?.id,
          imageBase64: imageBase64,
          preferredModel: _selectedModelKey,
        );

        if (mounted) {
          setState(() => _isSending = false);
        }

        if (scanResult.isLeft()) {
          // Automatic high-availability fallback
          final fallbackResult = await repo.analyzeSymptoms(
            symptomDescription: visualPrompt,
            petId: selectedPet?.id,
            imageBase64: imageBase64,
            preferredModel: 'gemini-3.5-flash-lite',
          );
          if (fallbackResult.isRight()) {
            final scan = fallbackResult.getOrElse(() => throw Exception());
            await _streamAiResponse(
              scan.analysisSummary,
              sources: const ['Gemini 3.5 Multimodal Vision'],
              urgencyLevel: scan.urgencyLevel,
              recommendations: scan.recommendations.map((e) => e.toString()).toList(),
            );
            return;
          }
        }

        await scanResult.fold(
          (failure) async {
            await _streamAiResponse(
              '⚠️ Unable to analyze photo at this moment. Please check your internet connection and try again.',
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
          try {
            final convResult = await repo.createConversation(
              petId: selectedPet?.id,
              title: userText.length > 25 ? '${userText.substring(0, 25)}...' : userText,
            ).timeout(const Duration(seconds: 3));
            convResult.fold((_) {}, (conv) {
              _activeConversationId = conv.id;
              ref.invalidate(aiConversationsProvider);
            });
          } catch (_) {}
        }

        final convId = _activeConversationId ??
            'session-${DateTime.now().millisecondsSinceEpoch}';

        final ragContext = _buildAppRagContext();

        final result = await repo.sendChatMessage(
          conversationId: convId,
          prompt: userText,
          petId: selectedPet?.id,
          ragContext: ragContext,
          preferredModel: _selectedModelKey,
        ).timeout(const Duration(seconds: 30));

        if (mounted) {
          setState(() => _isSending = false);
        }

        await result.fold(
          (failure) async {
            await _streamAiResponse(
              '⚠️ Could not reach Gemini AI. Please check your network connection.',
              sources: const ['PetConnect AI Engine'],
            );
          },
          (aiMsg) async {
            if (aiMsg.metadata['model'] != null) {
              final mName = (aiMsg.metadata['model'] as String).replaceAll('gemini-', '');
              if (mounted) {
                setState(() {
                  _activeModelLabel = '⚡ $mName';
                });
              }
            }
            final reply = aiMsg.messageText.trim().isNotEmpty
                ? aiMsg.messageText.trim()
                : 'I am here to assist with all your questions and pet care needs! How can I help you today?';
            await _streamAiResponse(
              reply,
              sources: const ['Gemini Omni-Intelligence'],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
      }
      await _streamAiResponse(
        '⚠️ An error occurred while generating response: $e. Please try again.',
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
                      'Conversations',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_comment_outlined),
                      tooltip: 'New Conversation',
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _messages.clear();
                          _messages.add(
                            _ChatMessage(
                              _Role.ai,
                              '👋 Started a fresh session! What would you like to ask or explore today?',
                              sources: const ['Gemini Omni-Intelligence'],
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
                  error: (_, __) => const Center(child: Text('No previous chats found')),
                  data: (conversations) {
                    if (conversations.isEmpty) {
                      return const Center(
                        child: Text(
                          'No previous conversations',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: conversations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final c = conversations[i];
                        final isSelected = c.id == _activeConversationId;
                        return ListTile(
                          selected: isSelected,
                          leading: const Icon(Icons.chat_bubble_outline, size: 18),
                          title: Text(
                            c.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
            const Hero(
              tag: 'ai-mascot-avatar-hero',
              child: AiMascotCompanion(
                size: 34,
                isAppBarMode: true,
                showSpeechBubble: false,
                showSwitcherBadge: false,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PetConnect AI',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _showModelSelectionModal(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF10B981)),
                    const SizedBox(width: 2),
                    Text(
                      _activeModelLabel,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: Color(0xFF10B981)),
                  ],
                ),
              ),
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
            tooltip: 'New Conversation',
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _messages.clear();
                _messages.add(
                  _ChatMessage(
                    _Role.ai,
                    '👋 Started a fresh session! What would you like to ask or explore today?',
                    sources: const ['Gemini Omni-Intelligence'],
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
                child: Stack(
                  children: [
                    ListView.separated(
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
                                onRegenerate: _lastUserPrompt != null && i == _messages.length - 1
                                    ? () => _sendPrompt(_lastUserPrompt!)
                                    : null,
                              );
                      },
                    ),

                    // ChatGPT-Style Floating Scroll-to-Bottom Down-Arrow Button
                    if (_showScrollToBottom)
                      Positioned(
                        bottom: 14,
                        right: 18,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _scroll.animateTo(
                                _scroll.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: scheme.primary,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
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
                        'Thinking...',
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
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    scrollDirection: Axis.horizontal,
                    itemCount: _suggestionChips.length,
                    separatorBuilder: (_, __) => AppSpacing.hGapSm,
                    itemBuilder: (ctx, i) {
                      final item = _suggestionChips[i];
                      return ActionChip(
                        avatar: Text(item['icon']!, style: const TextStyle(fontSize: 14)),
                        label: Text(
                          item['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        backgroundColor: scheme.surfaceContainerHighest,
                        side: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                      Text(
                        _dictationLocale.startsWith('ml')
                            ? 'കേൾക്കുന്നു... (മലയാളത്തിൽ സംസാരിക്കുക)'
                            : 'Listening for voice input... (Speak in English)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                      tooltip: 'Attach Photos for Multimodal Inspection',
                      onPressed: _pickImage,
                    ),
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      color: _isListening ? Colors.red : null,
                      tooltip: _dictationLocale.startsWith('ml') ? 'ശബ്ദ ഇൻപുട്ട് (മലയാളം)' : 'Voice Input (English)',
                      onPressed: _toggleDictation,
                    ),
                    InkWell(
                      onTap: () async {
                        await HapticFeedback.selectionClick();
                        final nextLocale = _dictationLocale == 'en_IN'
                            ? 'ml_IN'
                            : (_dictationLocale == 'ml_IN' ? 'auto' : 'en_IN');
                        setState(() {
                          _dictationLocale = nextLocale;
                        });
                        await ref.read(sharedPreferencesProvider).setString(
                              'app_voice_dictation_locale',
                              nextLocale,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(nextLocale == 'ml_IN'
                                  ? '✓ Voice dictation: Malayalam (മലയാളം)'
                                  : (nextLocale == 'auto'
                                      ? '✓ Voice dictation: Auto Detect Language'
                                      : '✓ Voice dictation: English (Default)')),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          _dictationLocale == 'ml_IN'
                              ? 'മലയാളം'
                              : (_dictationLocale == 'auto' ? 'AUTO' : 'EN'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _composer,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendPrompt,
                        decoration: InputDecoration(
                          hintText: _pendingImages.isNotEmpty
                              ? 'Add notes to symptom photos...'
                              : 'Ask anything — health, symptoms, nutrition, behavior...',
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
    this.onRegenerate,
  });

  final String text;
  final List<String> sources;
  final String? urgencyLevel;
  final List<String> recommendations;
  final bool isStreaming;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

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
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        MascotChangeNotifier.instance.currentStyle.assetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: scheme.primaryContainer,
                          child: Icon(Icons.auto_awesome, size: 12, color: scheme.primary),
                        ),
                      ),
                    ),
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
                      tooltip: 'Share',
                      onPressed: () {
                        ExternalActions.shareText(
                          text,
                          subject: 'PetConnect AI Response',
                        );
                      },
                    ),
                    if (onRegenerate != null)
                      IconButton(
                        icon: const Icon(Icons.replay_rounded, size: 16),
                        tooltip: 'Regenerate Response',
                        onPressed: onRegenerate,
                      ),
                  ],
                ],
              ),
              Builder(
                builder: (ctx) {
                  try {
                    return _RichMarkdownView(text: text);
                  } catch (_) {
                    return SelectableText(
                      text.replaceAll('**', ''),
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rich formatted Markdown parser and renderer supporting:
/// Headers, bullet points, bold/italic terms, inline code pills, and multi-line code blocks with copy action.
class _RichMarkdownView extends StatelessWidget {
  const _RichMarkdownView({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    try {
      final scheme = Theme.of(context).colorScheme;
      final lines = text.split('\n');
      final widgets = <Widget>[];

      bool inCodeBlock = false;
      final codeBuffer = StringBuffer();
      String codeLanguage = '';

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];

        // Code block start/end
        if (line.trim().startsWith('```')) {
          if (inCodeBlock) {
            // Finish code block
            final code = codeBuffer.toString().trimRight();
            widgets.add(_buildCodeBlock(code, codeLanguage, context));
            codeBuffer.clear();
            inCodeBlock = false;
            codeLanguage = '';
          } else {
            inCodeBlock = true;
            codeLanguage = line.trim().length > 3 ? line.trim().substring(3).trim() : '';
          }
          continue;
        }

        if (inCodeBlock) {
          codeBuffer.writeln(line);
          continue;
        }

        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          widgets.add(const SizedBox(height: 6));
          continue;
        }

        // Headings (#, ##, ###, ####, #####)
        if (RegExp(r'^#{1,6}\s+').hasMatch(trimmed)) {
          final level = RegExp(r'^(#+)').firstMatch(trimmed)?.group(1)?.length ?? 1;
          final title = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
          widgets.add(
            _buildSectionHeader(
              context: context,
              title: title,
              isMajor: level <= 2,
            ),
          );
        }
        // Standalone bold line acting as a title (e.g., **Key Symptoms:** or **Daily Care Plan**)
        else if (trimmed.startsWith('**') && trimmed.endsWith('**') && trimmed.length >= 4 && trimmed.length < 90 && !trimmed.substring(2, trimmed.length - 2).contains('**')) {
          final title = trimmed.substring(2, trimmed.length - 2);
          widgets.add(
            _buildSectionHeader(
              context: context,
              title: title,
              isMajor: true,
            ),
          );
        }
        // Numbered heading or list item (e.g., 1) **Heading:** or 1. **Heading** or 1. Detail text)
        else if (RegExp(r'^\d+[\.\)]\s+').hasMatch(trimmed)) {
          final match = RegExp(r'^(\d+[\.\)])\s+(.*)$').firstMatch(trimmed);
          final numPrefix = match?.group(1) ?? '1.';
          final itemText = match?.group(2) ?? trimmed;
          
          final isShortTitle = (itemText.startsWith('**') && itemText.contains('**') && itemText.length < 70) ||
                               (itemText.endsWith(':') && itemText.length < 50);
          if (isShortTitle) {
            widgets.add(
              _buildSectionHeader(
                context: context,
                badgeText: numPrefix,
                title: itemText,
                isMajor: true,
              ),
            );
          } else {
            widgets.add(
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8, top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        numPrefix,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildFormattedSpans(itemText, context),
                    ),
                  ],
                ),
              ),
            );
          }
        }
        // Bullet list items (•, *, -)
        else if (trimmed.startsWith('• ') || trimmed.startsWith('* ') || trimmed.startsWith('- ')) {
          final itemText = trimmed.length > 2 ? trimmed.substring(2) : trimmed;
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    width: 5.5,
                    height: 5.5,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: _buildFormattedSpans(itemText, context),
                  ),
                ],
              ),
            ),
          );
        }
        // Normal paragraph
        else {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildFormattedSpans(trimmed, context),
            ),
          );
        }
      }

      // Unclosed code block
      if (inCodeBlock && codeBuffer.isNotEmpty) {
        widgets.add(_buildCodeBlock(codeBuffer.toString().trimRight(), codeLanguage, context));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      );
    } catch (_) {
      // Safe fallback that never breaks or turns grey
      return SelectableText(
        text.replaceAll('**', ''),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14.5,
          height: 1.5,
        ),
      );
    }
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    String? badgeText,
    required String title,
    bool isMajor = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final cleanTitle = title.replaceAll('**', '').trim();
    return Padding(
      padding: EdgeInsets.only(
        top: isMajor ? 12 : 8,
        bottom: 5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (badgeText != null && badgeText.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              cleanTitle,
              style: TextStyle(
                fontSize: isMajor ? 15.5 : 14.5,
                fontWeight: FontWeight.bold,
                color: isMajor ? scheme.primary : scheme.onSurface,
                letterSpacing: 0.15,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String code, String language, BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language.isNotEmpty ? language.toUpperCase() : 'CODE',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✓ Code copied to clipboard')),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.copy, size: 13, color: Color(0xFF94A3B8)),
                      SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              code,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedSpans(String rawText, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    try {
      final spans = <InlineSpan>[];

      // Regex for bold (**text**), inline code (`code`), and italics (*text*)
      final pattern = RegExp(r'(\*\*[^*]+\*\*|`[^`]+`|\*[^*]+\*)');
      int lastIndex = 0;

      for (final match in pattern.allMatches(rawText)) {
        if (match.start > lastIndex) {
          final slice = rawText.substring(lastIndex, match.start).replaceAll('**', '');
          spans.add(
            TextSpan(
              text: slice,
              style: TextStyle(color: scheme.onSurface, fontSize: 14.5, height: 1.5),
            ),
          );
        }

        final matchedText = match.group(0)!;
        if (matchedText.startsWith('**') && matchedText.endsWith('**') && matchedText.length >= 4) {
          final content = matchedText.substring(2, matchedText.length - 2).replaceAll('**', '');
          spans.add(
            TextSpan(
              text: content,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
          );
        } else if (matchedText.startsWith('`') && matchedText.endsWith('`') && matchedText.length >= 2) {
          final content = matchedText.substring(1, matchedText.length - 1);
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  content,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        } else if (matchedText.startsWith('*') && matchedText.endsWith('*') && matchedText.length >= 2) {
          final content = matchedText.substring(1, matchedText.length - 1);
          spans.add(
            TextSpan(
              text: content,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: scheme.onSurface,
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
          );
        }
        lastIndex = match.end;
      }

      if (lastIndex < rawText.length) {
        final slice = rawText.substring(lastIndex).replaceAll('**', '');
        spans.add(
          TextSpan(
            text: slice,
            style: TextStyle(color: scheme.onSurface, fontSize: 14.5, height: 1.5),
          ),
        );
      }

      return SelectableText.rich(
        TextSpan(children: spans),
        style: TextStyle(color: scheme.onSurface, fontSize: 14.5, height: 1.5),
      );
    } catch (_) {
      return SelectableText(
        rawText.replaceAll('**', ''),
        style: TextStyle(color: scheme.onSurface, fontSize: 14.5, height: 1.5),
      );
    }
  }
}
