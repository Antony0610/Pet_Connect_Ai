import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/community_post.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/community_providers.dart';

/// Opens the interactive full-screen photo viewer for a [CommunityPost].
void showCommunityPhotoViewer(BuildContext context, CommunityPost post) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      barrierDismissible: true,
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: CommunityPhotoViewer(post: post),
        );
      },
    ),
  );
}

/// Immersive Instagram-style photo viewer with pinch-to-zoom, double-tap to like,
/// author details, and interactive reactions.
class CommunityPhotoViewer extends ConsumerStatefulWidget {
  const CommunityPhotoViewer({
    super.key,
    required this.post,
    this.heroTag,
  });

  final CommunityPost post;
  final String? heroTag;

  @override
  ConsumerState<CommunityPhotoViewer> createState() =>
      _CommunityPhotoViewerState();
}

class _CommunityPhotoViewerState extends ConsumerState<CommunityPhotoViewer>
    with SingleTickerProviderStateMixin {
  late CommunityPost _post;
  final TransformationController _transformController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _showHeartAnimation = false;
  bool _showOverlay = true;

  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _heartOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _post = widget.post;

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _heartScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 30),
    ]).animate(
      CurvedAnimation(parent: _heartAnimController, curve: Curves.easeOutBack),
    );

    _heartOpacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_heartAnimController);
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  Future<void> _handleDoubleTapLike() async {
    await HapticFeedback.heavyImpact();
    setState(() {
      _showHeartAnimation = true;
      if (!_isLiked) {
        _isLiked = true;
        _post = _post.copyWith(likesCount: _post.likesCount + 1);
      }
    });

    unawaited(
      _heartAnimController.forward(from: 0.0).then((_) {
        if (mounted) setState(() => _showHeartAnimation = false);
      }),
    );

    await ref.read(communityRepositoryProvider).likePost(_post.id);
    ref.invalidate(communityPostsProvider);
  }

  Future<void> _handleToggleLike() async {
    await HapticFeedback.lightImpact();
    setState(() {
      _isLiked = !_isLiked;
      _post = _post.copyWith(
        likesCount: _isLiked
            ? _post.likesCount + 1
            : (_post.likesCount > 0 ? _post.likesCount - 1 : 0),
      );
    });
    await ref.read(communityRepositoryProvider).likePost(_post.id);
    ref.invalidate(communityPostsProvider);
  }

  void _handleDoubleTapZoom(TapDownDetails details) {
    if (_transformController.value != Matrix4.identity()) {
      _transformController.value = Matrix4.identity();
    } else {
      final position = details.localPosition;
      final translation = Matrix4.translationValues(
        -position.dx * 1.5,
        -position.dy * 1.5,
        0.0,
      );
      final scale = Matrix4.diagonal3Values(2.5, 2.5, 1.0);
      _transformController.value = translation.clone()..multiply(scale);
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Interactive Zoomable Photo ─────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _showOverlay = !_showOverlay),
            onDoubleTapDown: (details) => _doubleTapDetails = details,
            onDoubleTap: () {
              if (_doubleTapDetails != null) {
                _handleDoubleTapZoom(_doubleTapDetails!);
              }
              _handleDoubleTapLike();
            },
            child: Center(
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.8,
                maxScale: 4.0,
                child: Hero(
                  tag: widget.heroTag ?? 'post-photo-${_post.id}',
                  child: _buildPhotoContent(_post.imageUrl, size),
                ),
              ),
            ),
          ),

          // ── Animated Heart Burst Overlay on Double-Tap ─────────────────
          if (_showHeartAnimation)
            Center(
              child: AnimatedBuilder(
                animation: _heartAnimController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _heartOpacityAnimation.value,
                    child: Transform.scale(
                      scale: _heartScaleAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.redAccent,
                          size: 96,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── Top Header Overlay (Author details & Close button) ─────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            top: _showOverlay ? 0 : -120,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: scheme.primaryContainer,
                    backgroundImage: (_post.authorAvatarUrl != null &&
                            _post.authorAvatarUrl!.isNotEmpty)
                        ? NetworkImage(_post.authorAvatarUrl!)
                        : null,
                    child: (_post.authorAvatarUrl == null ||
                            _post.authorAvatarUrl!.isEmpty)
                        ? Text(
                            (_post.authorName != null &&
                                    _post.authorName!.isNotEmpty)
                                ? _post.authorName![0].toUpperCase()
                                : 'P',
                            style: TextStyle(
                              color: scheme.onPrimaryContainer,
                              fontWeight: AppTypography.bold,
                            ),
                          )
                        : null,
                  ),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _post.authorName ?? 'Community Member',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Text(
                              _timeAgo(_post.createdAt),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            if (_post.location != null &&
                                _post.location!.isNotEmpty) ...[
                              const Text(
                                ' • ',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  _post.location!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.8),
                      borderRadius: AppRadius.brPill,
                    ),
                    child: Text(
                      _post.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 26),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Caption & Actions Bar Overlay ───────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: _showOverlay ? 0 : -200,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: 24,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Action Buttons Row (Like, Comment, Share, Bookmark)
                  Row(
                    children: [
                      // Like button
                      InkWell(
                        onTap: _handleToggleLike,
                        borderRadius: AppRadius.brPill,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                _isLiked || _post.likesCount > 0
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: _isLiked || _post.likesCount > 0
                                    ? Colors.redAccent
                                    : Colors.white,
                                size: 26,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_post.likesCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tags count
                      if (_post.tags.isNotEmpty)
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _post.tags.map((t) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: const BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: AppRadius.brPill,
                                  ),
                                  child: Text(
                                    '#$t',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        )
                      else
                        const Spacer(),

                      // Bookmark button
                      IconButton(
                        icon: Icon(
                          _isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: _isBookmarked
                              ? scheme.primary
                              : Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() => _isBookmarked = !_isBookmarked);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isBookmarked
                                  ? 'Saved to bookmarks'
                                  : 'Removed from bookmarks'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),

                      // Share button
                      IconButton(
                        icon: const Icon(Icons.share_rounded,
                            color: Colors.white, size: 24),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ExternalActions.shareText(
                            'Check out "${_post.title}" by ${_post.authorName} on PetConnect AI:\n\n${_post.content}',
                            subject: _post.title,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Post Title & Caption
                  if (_post.title.isNotEmpty)
                    Text(
                      _post.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (_post.content.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _post.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoContent(String? imageUrl, Size size) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade900,
        child: const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 64),
        ),
      );
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIdx = imageUrl.indexOf(',');
        final base64Str =
            commaIdx != -1 ? imageUrl.substring(commaIdx + 1) : imageUrl;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          width: size.width,
          height: size.height,
        );
      } catch (_) {
        return const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 64),
        );
      }
    } else if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
      final path = imageUrl.replaceFirst('file://', '');
      return Image.file(
        File(path),
        fit: BoxFit.contain,
        width: size.width,
        height: size.height,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 64),
        ),
      );
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        width: size.width,
        height: size.height,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white70,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 64),
        ),
      );
    }
  }
}
