import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/widgets.dart';
import 'package:petconnect_ai/features/storage/domain/entities/pet_gallery_media.dart';
import 'package:petconnect_ai/features/storage/presentation/providers/storage_providers.dart';

/// The Pet Owner **Pet Media Gallery** screen.
///
/// Fully wired to live Supabase backend via [petGalleryMediaProvider] & [storageRepositoryProvider].
/// - Grid and Timeline views for real photos.
/// - Upload button with [ImagePicker] support.
/// - Tap to view / delete photo.
/// - ZERO mock/hardcoded image URLs.
class PetMediaGalleryScreen extends ConsumerStatefulWidget {
  const PetMediaGalleryScreen({super.key});

  @override
  ConsumerState<PetMediaGalleryScreen> createState() =>
      _PetMediaGalleryScreenState();
}

enum _GalleryView { grid, timeline }

class _PetMediaGalleryScreenState extends ConsumerState<PetMediaGalleryScreen> {
  _GalleryView _view = _GalleryView.grid;
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final selectedPet = ref.watch(selectedPetProvider);
    final petId = selectedPet?.id ?? '';

    final galleryAsync = ref.watch(petGalleryMediaProvider(petId));

    final appBar = OwnerGlassAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        selectedPet != null ? '${selectedPet.name}’s Gallery' : 'Gallery',
        style: text.titleLarge?.copyWith(
          color: scheme.primary,
          fontWeight: AppTypography.bold,
        ),
      ),
      actions: [
        OwnerAppBarAction(
          icon: Icons.add_a_photo_outlined,
          tooltip: 'Add Photo',
          onPressed: _uploading ? () {} : () => _pickAndUploadPhoto(petId),
        ),
      ],
    );

    final topPad = context.viewPadding.top + appBar.preferredSize.height;

    return OwnerScaffold(
      currentTab: OwnerTab.pets,
      appBar: appBar,
      showAiFab: false,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          topPad + AppSpacing.sm,
          AppSpacing.marginMobile,
          AppSpacing.xxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Title + view toggle ────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Photos & Media',
                      style: text.headlineSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    _ViewToggle(
                      value: _view,
                      onChanged: (v) => setState(() => _view = v),
                    ),
                  ],
                ),
                AppSpacing.vGapLg,

                if (_uploading) ...[
                  const LinearProgressIndicator(),
                  AppSpacing.vGapMd,
                ],

                galleryAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'Unable to load media: $e',
                        style: text.bodyMedium?.copyWith(color: scheme.error),
                      ),
                    ),
                  ),
                  data: (mediaList) {
                    if (mediaList.isEmpty) {
                      return _EmptyGalleryCard(
                        petName: selectedPet?.name ?? 'your pet',
                        onUpload: () => _pickAndUploadPhoto(petId),
                      );
                    }

                    if (_view == _GalleryView.timeline) {
                      return _TimelineGallery(
                        mediaList: mediaList,
                        onDelete: (item) => _deleteMedia(item, petId),
                      );
                    }

                    return _GridGallery(
                      mediaList: mediaList,
                      onDelete: (item) => _deleteMedia(item, petId),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(String petId) async {
    if (petId.isEmpty) {
      context.showErrorSnack('Please select a pet first.');
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final userId =
          ref.read(currentUserProfileProvider).valueOrNull?.id ?? 'anon';
      final fileName =
          'gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final repo = ref.read(storageRepositoryProvider);
      final result = await repo.uploadGalleryMedia(
        userId: userId,
        petId: petId,
        bytes: bytes,
        fileName: fileName,
        mimeType: 'image/jpeg',
      );

      result.fold(
        (failure) => context.showErrorSnack('Upload failed: ${failure.message}'),
        (item) {
          ref.invalidate(petGalleryMediaProvider(petId));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo added to gallery!')),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        context.showErrorSnack('Failed to upload photo: $e');
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteMedia(PetGalleryMedia item, String petId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to remove this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(storageRepositoryProvider);
    final result = await repo.deleteGalleryMedia(item.id, item.storagePath);
    result.fold(
      (failure) => context.showErrorSnack('Delete failed: ${failure.message}'),
      (_) {
        ref.invalidate(petGalleryMediaProvider(petId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo deleted.')),
          );
        }
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Empty State Card
// ═══════════════════════════════════════════════════════════════════

class _EmptyGalleryCard extends StatelessWidget {
  const _EmptyGalleryCard({
    required this.petName,
    required this.onUpload,
  });

  final String petName;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Container(
      padding: AppSpacing.cardPaddingPremium,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.brSection,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: AppIconSizes.xxl,
            color: scheme.primary.withValues(alpha: 0.50),
          ),
          AppSpacing.vGapMd,
          Text(
            'No Photos Yet',
            style: text.titleLarge?.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            'Capture and upload memorable moments with $petName.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.vGapLg,
          FilledButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Add First Photo'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Grid Gallery View
// ═══════════════════════════════════════════════════════════════════

class _GridGallery extends StatelessWidget {
  const _GridGallery({
    required this.mediaList,
    required this.onDelete,
  });

  final List<PetGalleryMedia> mediaList;
  final ValueChanged<PetGalleryMedia> onDelete;

  @override
  Widget build(BuildContext context) {
    final isWide = context.screenWidth >= AppBreakpoints.tablet;
    final crossAxisCount = isWide ? 4 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.0,
      ),
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        final item = mediaList[index];
        return _MediaItemTile(
          item: item,
          onDelete: () => onDelete(item),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Timeline Gallery View
// ═══════════════════════════════════════════════════════════════════

class _TimelineGallery extends StatelessWidget {
  const _TimelineGallery({
    required this.mediaList,
    required this.onDelete,
  });

  final List<PetGalleryMedia> mediaList;
  final ValueChanged<PetGalleryMedia> onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mediaList.length,
      separatorBuilder: (_, __) => AppSpacing.vGapLg,
      itemBuilder: (context, index) {
        final item = mediaList[index];
        final dateStr =
            '${item.createdAt.year}-${item.createdAt.month.toString().padLeft(2, '0')}-${item.createdAt.day.toString().padLeft(2, '0')}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: AppIconSizes.xs,
                  color: scheme.primary,
                ),
                AppSpacing.hGapXs,
                Text(
                  dateStr,
                  style: text.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: scheme.error,
                  onPressed: () => onDelete(item),
                ),
              ],
            ),
            AppSpacing.vGapXs,
            ClipRRect(
              borderRadius: AppRadius.brCard,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  item.mediaUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: scheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
            if (item.caption != null && item.caption!.isNotEmpty) ...[
              AppSpacing.vGapXs,
              Text(
                item.caption!,
                style: text.bodyMedium?.copyWith(color: scheme.onSurface),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Media Item Tile with Preview & Delete
// ═══════════════════════════════════════════════════════════════════

class _MediaItemTile extends StatelessWidget {
  const _MediaItemTile({
    required this.item,
    required this.onDelete,
  });

  final PetGalleryMedia item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return ClipRRect(
      borderRadius: AppRadius.brCard,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            item.mediaUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: Icon(
                Icons.image_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: Material(
              color: Colors.black45,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.white, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
                ),
                onPressed: onDelete,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// View Toggle (Grid / Timeline)
// ═══════════════════════════════════════════════════════════════════

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.value, required this.onChanged});

  final _GalleryView value;
  final ValueChanged<_GalleryView> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewChip(
            icon: Icons.grid_view,
            label: 'Grid',
            selected: value == _GalleryView.grid,
            onTap: () => onChanged(_GalleryView.grid),
          ),
          _ViewChip(
            icon: Icons.view_timeline,
            label: 'Timeline',
            selected: value == _GalleryView.timeline,
            onTap: () => onChanged(_GalleryView.timeline),
          ),
        ],
      ),
    );
  }
}

class _ViewChip extends StatelessWidget {
  const _ViewChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;

    return Material(
      color: selected ? scheme.surface : Colors.transparent,
      borderRadius: AppRadius.brPill,
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.base + 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSizes.xs, color: fg),
              AppSpacing.hGapXs,
              Text(
                label,
                style: text.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
