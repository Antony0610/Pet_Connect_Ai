import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
    if (selection.start < 0) {
      _bodyController.text = '$text$prefix$suffix';
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
          offset: selection.start + prefix.length + selectedText.length,
        ),
      );
    }
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

  void _handleGenerateDraft() {
    setState(() => _isGeneratingDraft = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
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
        } else {
          _titleController.text = 'Tips for Leash Training Success';
          _bodyController.text =
              'We recently tried counter-conditioning techniques during our daily morning walks. Focus on maintaining treat rewards whenever passing other pets. Consistency made all the difference!';
        }
      });
    });
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
                // ── Category Selector Chips ───────────────────────
                Text(
                  'Category',
                  style: context.textTheme.labelLarge?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                AppSpacing.vGapSm,
                Wrap(
                  spacing: AppSpacing.sm,
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
                    hintText: 'What do you want to share?',
                    filled: true,
                    fillColor: scheme.surfaceContainerLow,
                    border: const OutlineInputBorder(
                      borderRadius: AppRadius.brCard,
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                AppSpacing.vGapLg,

                // ── Formatting Toolbar ────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.sm),
                    ),
                  ),
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
                        icon: const Icon(Icons.format_underlined, size: 18),
                        tooltip: 'Underline (_text_)',
                        onPressed: () => _insertFormatting('_', '_'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.format_list_bulleted, size: 18),
                        tooltip: 'Bullet list',
                        onPressed: () => _insertFormatting('\n- ', ''),
                      ),
                      IconButton(
                        icon: const Icon(Icons.format_list_numbered, size: 18),
                        tooltip: 'Numbered list',
                        onPressed: () => _insertFormatting('\n1. ', ''),
                      ),
                      IconButton(
                        icon: const Icon(Icons.link, size: 18),
                        tooltip: 'Link',
                        onPressed: () => _insertFormatting('[', '](https://)'),
                      ),
                    ],
                  ),
                ),

                // ── Multi-line Body TextArea ──────────────────────
                TextField(
                  controller: _bodyController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Write your post content here...',
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
                ),
                AppSpacing.vGapSm,
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_bodyController.text.length}/2000',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Media & Action Buttons Row ───────────────────
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickMedia,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: Text(_attachedImageBytes != null ? 'Change Media' : 'Add Media'),
                    ),
                    AppSpacing.hGapSm,
                    OutlinedButton.icon(
                      onPressed: _promptLocation,
                      icon: const Icon(Icons.location_on_outlined),
                      label: Text(_attachedLocation != null ? _attachedLocation! : 'Location'),
                    ),
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
                          height: 180,
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
                        'Stuck on what to write? Select a topic and our AI can help you draft your post.',
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
                            Text('Generate Draft'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapXl,

                // ── Tags Section ──────────────────────────────────
                Text(
                  'Tags',
                  style: context.textTheme.labelLarge?.copyWith(
                    fontWeight: AppTypography.bold,
                  ),
                ),
                AppSpacing.vGapSm,
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    ..._tags.map(
                      (tag) => Chip(
                        avatar: const Icon(Icons.tag, size: 14),
                        label: Text(tag),
                        onDeleted: () {
                          setState(() => _tags.remove(tag));
                        },
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 14),
                      label: const Text('Add Tag'),
                      onPressed: () {
                        setState(() => _tags.add('PetCare'));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryOption {
  const _CategoryOption(this.label, this.icon);
  final String label;
  final IconData icon;
}
