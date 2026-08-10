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

/// A faithful Flutter rendering of the frozen Stitch **Create Post** (Light
/// Theme design authority, ID `910fdec0`).
///
/// Enables pet owners to create, format, attach media, and publish community
/// posts with AI Writing Assistant integration and tag selection.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const double _maxContentWidth = 800;

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedCategory = 'Photo/Video';
  bool _isGeneratingDraft = false;
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

  void _handleGenerateDraft() {
    setState(() => _isGeneratingDraft = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _isGeneratingDraft = false;
        if (_titleController.text.isEmpty) {
          _titleController.text = 'Tips for Leash Training Success';
        }
        _bodyController.text =
            'We recently tried counter-conditioning techniques during our daily morning walks. Focus on maintaining treat rewards whenever passing other pets. Consistency made all the difference!';
      });
    });
  }

  void _handleSubmit() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a post title')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post published successfully!')),
    );
    GoRouter.of(context).pop();
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
              onPressed: _handleSubmit,
              size: AppButtonSize.small,
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
              crossAxisAlignment: CrossAlignment.start,
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
                        if (selected)
                          setState(() => _selectedCategory = cat.label);
                      },
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── Title Input ───────────────────────────────────
                AppTextField(
                  controller: _titleController,
                  labelText: 'Post Title',
                  hintText: 'What do you want to share?',
                ),
                AppSpacing.vGapLg,

                // ── Formatting Toolbar ────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
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
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.format_italic, size: 18),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.format_underlined, size: 18),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.format_list_bulleted, size: 18),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.format_list_numbered, size: 18),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.link, size: 18),
                        onPressed: () {},
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Media picker demo: Photo attached'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Add Media'),
                    ),
                    AppSpacing.hGapSm,
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location attached: Dolores Park'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.location_on_outlined),
                      label: const Text('Location'),
                    ),
                  ],
                ),
                AppSpacing.vGapXl,

                // ── AI Writing Assistant Card ──────────────────────
                AiGradientBorderCard(
                  child: Column(
                    crossAxisAlignment: CrossAlignment.start,
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
