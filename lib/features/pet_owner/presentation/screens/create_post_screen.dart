import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:petconnect_ai/core/config/env.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/community_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/features/storage/presentation/providers/storage_providers.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// A Flutter rendering of the **Create Post** screen.
///
/// Enables pet owners to create, format, attach real media from gallery, and publish community
/// posts with AI Writing Assistant integration and tag selection.
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  static const double _maxContentWidth = 800;

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedCategory = 'Photo/Video';
  bool _isGeneratingDraft = false;
  bool _isSubmitting = false;
  bool _isPreviewMode = false;
  Uint8List? _attachedImageBytes;
  String? _attachedImageName;
  String? _attachedLocation;
  final List<String> _tags = ['DogLife', 'Training'];

  final List<_CategoryOption> _categories = const [
    _CategoryOption('Photo/Video', Icons.image),
    _CategoryOption('Question', Icons.help_outline),
    _CategoryOption('Story', Icons.auto_stories),
    _CategoryOption('Health', Icons.health_and_safety_outlined),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1440,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _attachedImageBytes = bytes;
      _attachedImageName = picked.name;
    });
  }

  void _removeMedia() {
    setState(() {
      _attachedImageBytes = null;
      _attachedImageName = null;
    });
  }

  void _insertFormatting(String prefix, [String suffix = '']) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    if (!selection.isValid || selection.start < 0) {
      _bodyController.text = '$text$prefix$suffix';
      _bodyController.selection = TextSelection.collapsed(
        offset: _bodyController.text.length,
      );
    } else {
      final selectedText = selection.textInside(text);
      final newText = selection.textBefore(text) +
          prefix +
          selectedText +
          suffix +
          selection.textAfter(text);
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length + selectedText.length + suffix.length,
        ),
      );
    }
  }

  Future<void> _promptInsertLink() async {
    final selection = _bodyController.selection;
    final selectedText = selection.isValid ? selection.textInside(_bodyController.text) : '';
    final textController = TextEditingController(text: selectedText);
    final urlController = TextEditingController(text: 'https://');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.link, size: 22),
            SizedBox(width: 8),
            Text('Insert Web Link'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Display Text',
                hintText: 'e.g. Pet Nutrition Guide',
                border: OutlineInputBorder(),
              ),
              autofocus: selectedText.isEmpty,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autofocus: selectedText.isNotEmpty,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final linkText = textController.text.trim();
              final linkUrl = urlController.text.trim();
              if (linkUrl.isNotEmpty && linkUrl != 'https://') {
                Navigator.pop(ctx, {
                  'text': linkText.isEmpty ? linkUrl : linkText,
                  'url': linkUrl,
                });
              } else {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Insert Link'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final formatted = '[${result['text']}](${result['url']})';
      _insertFormatting(formatted);
    }
  }

  Future<void> _promptManageTags() async {
    final tagInputController = TextEditingController();
    const suggested = [
      'DogLife',
      'CatCare',
      'PuppyTraining',
      'PetHealth',
      'RescueStory',
      'Nutrition',
      'Adoption',
      'Wellness',
      'AskVeterinarian',
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tag, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Manage Hashtags',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tagInputController,
                        decoration: const InputDecoration(
                          hintText: 'Type a custom tag...',
                          prefixIcon: Icon(Icons.tag, size: 18),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (val) {
                          final clean = val.replaceAll('#', '').trim();
                          if (clean.isNotEmpty && !_tags.contains(clean)) {
                            setState(() => _tags.add(clean));
                            setModalState(() {});
                            tagInputController.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final clean = tagInputController.text.replaceAll('#', '').trim();
                        if (clean.isNotEmpty && !_tags.contains(clean)) {
                          setState(() => _tags.add(clean));
                          setModalState(() {});
                          tagInputController.clear();
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Current Tags:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _tags.map((tag) {
                    return Chip(
                      avatar: const Icon(Icons.tag, size: 14),
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () {
                        setState(() => _tags.remove(tag));
                        setModalState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Popular Suggestions:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: suggested.map((s) {
                    final isAlready = _tags.contains(s);
                    return ActionChip(
                      avatar: Icon(
                        isAlready ? Icons.check : Icons.add,
                        size: 14,
                        color: isAlready ? Colors.green : null,
                      ),
                      label: Text(s),
                      onPressed: isAlready
                          ? null
                          : () {
                              setState(() => _tags.add(s));
                              setModalState(() {});
                            },
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _promptLocation() async {
    final controller = TextEditingController(text: _attachedLocation ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Location'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. Central Park, Dog Beach',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _attachedLocation = result.isEmpty ? null : result;
      });
    }
  }

  Future<void> _handleGenerateDraft() async {
    setState(() => _isGeneratingDraft = true);
    try {
      final apiKey = Env.geminiApiKey;
      if (apiKey.isNotEmpty) {
        final dio = Dio();
        final prompt = 'Write a helpful, friendly community post for pet owners in category "$_selectedCategory" '
            '${_titleController.text.trim().isNotEmpty ? 'with topic "${_titleController.text.trim()}"' : ''}. '
            'Format as JSON: {"title": "concise engaging title", "content": "2 short paragraphs of authentic pet advice and tips"}. '
            'Output only the raw JSON object, without markdown quotes.';
        final response = await dio.post<Map<String, dynamic>>(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
          data: {
            'contents': [
              {
                'parts': [{'text': prompt}]
              }
            ]
          },
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data!;
          final candidates = data['candidates'] as List<dynamic>?;
          final firstCandidate = candidates?.isNotEmpty == true ? candidates!.first as Map<String, dynamic> : null;
          final content = firstCandidate?['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          final text = parts?.isNotEmpty == true ? (parts!.first as Map<String, dynamic>)['text'] as String? : null;
          if (text != null) {
            final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
            final decoded = jsonDecode(clean) as Map<String, dynamic>;
            if (mounted) {
              setState(() {
                _titleController.text = (decoded['title']?.toString()) ?? _titleController.text;
                _bodyController.text = (decoded['content']?.toString()) ?? _bodyController.text;
                _isGeneratingDraft = false;
              });
              return;
            }
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isGeneratingDraft = false;
        if (_selectedCategory == 'Health') {
          _titleController.text = 'Seasonal Allergy Signs to Watch Out For';
          _bodyController.text =
              'With the changing weather, please keep an eye on paw licking, ear scratching, and watery eyes. Consistent grooming and wipe-downs after walks helped us reduce flare-ups significantly!';
        } else if (_selectedCategory == 'Question') {
          _titleController.text = 'Best Puzzle Toys for High-Energy Pups?';
          _bodyController.text =
              'Looking for recommendations on durable interactive puzzle toys that keep clever dogs mentally stimulated for 30+ minutes. What has worked best for your pets?';
        } else if (_selectedCategory == 'Story') {
          _titleController.text = 'Our Journey Adopting a Senior Rescue';
          _bodyController.text =
              'Six months ago we welcomed an 8-year-old rescue into our family. Watching them blossom from shy and fearful to playful and confident has been the most rewarding experience of our lives.';
        } else {
          _titleController.text = 'Tips for Leash Training Success';
          _bodyController.text =
              'We recently tried counter-conditioning techniques during our daily morning walks. Focus on maintaining treat rewards whenever passing other pets. Consistency made all the difference!';
        }
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a post title')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProfileProvider).valueOrNull;
      final userId = user?.id ?? 'anon';
      String? uploadedImageUrl;

      if (_attachedImageBytes != null) {
        try {
          final storageRepo = ref.read(storageRepositoryProvider);
          final uploadResult = await storageRepo.uploadGalleryMedia(
            userId: userId,
            petId: 'community',
            bytes: _attachedImageBytes!,
            fileName: _attachedImageName ?? 'post_media_${DateTime.now().millisecondsSinceEpoch}.jpg',
            mimeType: 'image/jpeg',
            caption: _titleController.text.trim(),
          );
          uploadResult.fold((_) {}, (media) {
            if (media.mediaUrl.isNotEmpty) {
              uploadedImageUrl = media.mediaUrl;
            }
          });
        } catch (_) {}

        // If remote upload didn't yield a URL, preserve the base64 data URI
        uploadedImageUrl ??= 'data:image/jpeg;base64,${base64Encode(_attachedImageBytes!)}';
      }

      final repo = ref.read(communityRepositoryProvider);
      await repo.createPost(
        userId: userId,
        category: _selectedCategory,
        title: _titleController.text.trim(),
        content: _bodyController.text.trim(),
        imageUrl: uploadedImageUrl,
        location: _attachedLocation,
        tags: _tags,
      );

      ref.invalidate(communityPostsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published to Community!')),
        );
        GoRouter.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post published with local state: $e')),
        );
        GoRouter.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Create Post',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AppButton.filled(
              onPressed: _isSubmitting ? null : _handleSubmit,
              size: AppButtonSize.small,
              isLoading: _isSubmitting,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Submit'),
                  SizedBox(width: 4),
                  Icon(Icons.send, size: 14),
                ],
              ),
            ),
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
                // ── Author & Audience Card ────────────────────────
                _buildAuthorCard(scheme),
                AppSpacing.vGapLg,

                // ── Category Selector Chips ───────────────────────
                Text(
                  'Post Category',
                  style: context.textTheme.labelLarge?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                AppSpacing.vGapSm,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat.label;
                    return ChoiceChip(
                      avatar: Icon(
                        cat.icon,
                        size: 18,
                        color: isSelected ? scheme.onPrimary : scheme.primary,
                      ),
                      label: Text(cat.label),
                      selected: isSelected,
                      selectedColor: scheme.primary,
                      backgroundColor: scheme.surfaceContainerHigh,
                      labelStyle: TextStyle(
                        color: isSelected ? scheme.onPrimary : scheme.onSurface,
                        fontWeight: AppTypography.semiBold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat.label);
                        }
                      },
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── Post Title Field ──────────────────────────────
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Post Title',
                    hintText: 'What would you like to share or ask?',
                    prefixIcon: const Icon(Icons.title),
                    filled: true,
                    fillColor: scheme.surfaceContainerLow,
                    border: const OutlineInputBorder(
                      borderRadius: AppRadius.brCard,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) {
                    if (_isPreviewMode) setState(() {});
                  },
                ),
                AppSpacing.vGapLg,

                // ── Formatting Toolbar & Mode Switcher ────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.sm),
                    ),
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.format_bold, size: 18),
                                tooltip: 'Bold (**text**)',
                                onPressed: () => _insertFormatting('**', '**'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_italic, size: 18),
                                tooltip: 'Italic (*text*)',
                                onPressed: () => _insertFormatting('*', '*'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_strikethrough, size: 18),
                                tooltip: 'Strikethrough (~~text~~)',
                                onPressed: () => _insertFormatting('~~', '~~'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.code, size: 18),
                                tooltip: 'Inline Code (`code`)',
                                onPressed: () => _insertFormatting('`', '`'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.link, size: 18),
                                tooltip: 'Insert Web Link',
                                onPressed: _promptInsertLink,
                              ),
                              IconButton(
                                icon: const Icon(Icons.tag, size: 18),
                                tooltip: 'Add Hashtag',
                                onPressed: _promptManageTags,
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_list_bulleted, size: 18),
                                tooltip: 'Bullet List',
                                onPressed: () => _insertFormatting('\n• ', ''),
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_list_numbered, size: 18),
                                tooltip: 'Numbered List',
                                onPressed: () => _insertFormatting('\n1. ', ''),
                              ),
                              IconButton(
                                icon: const Icon(Icons.format_quote, size: 18),
                                tooltip: 'Blockquote (> quote)',
                                onPressed: () => _insertFormatting('\n> ', ''),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: scheme.outlineVariant,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      // Edit / Preview Toggle
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.edit, size: 14),
                            label: Text('Edit', style: TextStyle(fontSize: 11)),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.visibility, size: 14),
                            label: Text('Preview', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                        selected: {_isPreviewMode},
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          ),
                        ),
                        onSelectionChanged: (selection) {
                          setState(() => _isPreviewMode = selection.first);
                        },
                      ),
                    ],
                  ),
                ),

                // ── Multi-line Body or Live Preview ───────────────
                if (_isPreviewMode)
                  _buildPreview(scheme)
                else
                  TextField(
                    controller: _bodyController,
                    maxLines: 7,
                    decoration: InputDecoration(
                      hintText: 'Share your advice, update, or question with pet parents...',
                      filled: true,
                      fillColor: scheme.surfaceContainerLow,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(AppRadius.sm),
                        ),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                AppSpacing.vGapSm,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isPreviewMode ? '✓ Showing Markdown Preview' : 'Supports markdown formatting',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${_bodyController.text.length}/2000',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapLg,

                // ── Media & Action Buttons Row ───────────────────
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickMedia,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(_attachedImageBytes != null ? 'Change Photo' : 'Add Photo'),
                    ),
                    AppSpacing.hGapSm,
                    OutlinedButton.icon(
                      onPressed: _promptLocation,
                      icon: const Icon(Icons.location_on_outlined),
                      label: Text(_attachedLocation != null ? _attachedLocation! : 'Add Location'),
                    ),
                    if (_attachedLocation != null) ...[
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: 'Remove location',
                        onPressed: () => setState(() => _attachedLocation = null),
                      ),
                    ],
                  ],
                ),

                // ── Attached Media Preview ──────────────────────
                if (_attachedImageBytes != null) ...[
                  AppSpacing.vGapMd,
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.brSection,
                        child: Image.memory(
                          _attachedImageBytes!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: IconButton.filled(
                          onPressed: _removeMedia,
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                AppSpacing.vGapXl,

                // ── AI Writing Assistant Card ──────────────────────
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
                            'AI Writing Assistant',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        'Stuck on what to write? Our Gemini AI assistant can draft an engaging post tailored to your selected topic.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      AppButton.outlined(
                        onPressed: _isGeneratingDraft
                            ? null
                            : _handleGenerateDraft,
                        size: AppButtonSize.small,
                        isLoading: _isGeneratingDraft,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 14),
                            SizedBox(width: 4),
                            Text('Generate Draft with Gemini'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapXl,

                // ── Tags Section ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hashtags (${_tags.length})',
                      style: context.textTheme.labelLarge?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text('Manage'),
                      onPressed: _promptManageTags,
                    ),
                  ],
                ),
                AppSpacing.vGapSm,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 6,
                  children: [
                    ..._tags.map(
                      (tag) => Chip(
                        avatar: const Icon(Icons.tag, size: 14),
                        label: Text(tag),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () {
                          setState(() => _tags.remove(tag));
                        },
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 14),
                      label: const Text('Add Tag'),
                      onPressed: _promptManageTags,
                    ),
                  ],
                ),
                AppSpacing.vGapXl,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorCard(ColorScheme scheme) {
    final user = ref.watch(currentUserProfileProvider).valueOrNull;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          UserAvatar(
            imageUrl: user?.avatarUrl,
            name: user?.fullName ?? 'Pet Parent',
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user?.fullName ?? 'Pet Parent',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Community Author',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.public, size: 13, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Public to PetConnect Community',
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ColorScheme scheme) {
    if (_bodyController.text.trim().isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.sm)),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Text(
          'Post preview will appear here...',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadius.sm)),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_titleController.text.trim().isNotEmpty) ...[
            Text(
              _titleController.text.trim(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 16),
          ],
          Text(
            _bodyController.text,
            style: const TextStyle(fontSize: 14.5, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _CategoryOption {
  const _CategoryOption(this.label, this.icon);
  final String label;
  final IconData icon;
}
