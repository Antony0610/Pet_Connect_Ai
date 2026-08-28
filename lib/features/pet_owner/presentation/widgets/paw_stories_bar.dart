import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/router/route_paths.dart';

/// Data model for an Instagram-style companion Paw Story.
class PawStory {
  const PawStory({
    required this.id,
    required this.petName,
    required this.authorName,
    required this.avatarUrl,
    required this.imageUrl,
    required this.caption,
    required this.timeAgo,
    this.isViewed = false,
  });

  final String id;
  final String petName;
  final String authorName;
  final String avatarUrl;
  final String imageUrl;
  final String caption;
  final String timeAgo;
  final bool isViewed;

  PawStory copyWith({
    String? id,
    String? petName,
    String? authorName,
    String? avatarUrl,
    String? imageUrl,
    String? caption,
    String? timeAgo,
    bool? isViewed,
  }) {
    return PawStory(
      id: id ?? this.id,
      petName: petName ?? this.petName,
      authorName: authorName ?? this.authorName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      timeAgo: timeAgo ?? this.timeAgo,
      isViewed: isViewed ?? this.isViewed,
    );
  }
}

/// The horizontal Instagram-style stories tray at the top of Community Hub.
class PawStoriesBar extends ConsumerStatefulWidget {
  const PawStoriesBar({super.key});

  @override
  ConsumerState<PawStoriesBar> createState() => _PawStoriesBarState();
}

class _PawStoriesBarState extends ConsumerState<PawStoriesBar> {
  final List<PawStory> _stories = [
    const PawStory(
      id: 'story-1',
      petName: 'Max',
      authorName: 'Sarah Jenkins',
      avatarUrl:
          'https://images.unsplash.com/photo-1552053831-71594a27632d?w=150',
      imageUrl:
          'https://images.unsplash.com/photo-1552053831-71594a27632d?w=800',
      caption: 'Beach morning sprint! 🏖️ Loving the sunny weather today.',
      timeAgo: '2h ago',
    ),
    const PawStory(
      id: 'story-2',
      petName: 'Luna',
      authorName: 'David Miller',
      avatarUrl:
          'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=150',
      imageUrl:
          'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800',
      caption: 'Clean bill of health at Dr. Lee\'s clinic! 🩺🐾',
      timeAgo: '4h ago',
    ),
    const PawStory(
      id: 'story-3',
      petName: 'Rocky',
      authorName: 'Alex Thorne',
      avatarUrl:
          'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=150',
      imageUrl:
          'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=800',
      caption: 'New smart collar tracking our 5-mile mountain trail hike! 🏔️',
      timeAgo: '5h ago',
    ),
    const PawStory(
      id: 'story-4',
      petName: 'Bella',
      authorName: 'Emily Watson',
      avatarUrl:
          'https://images.unsplash.com/photo-1537151625747-768eb6cf92b2?w=150',
      imageUrl:
          'https://images.unsplash.com/photo-1537151625747-768eb6cf92b2?w=800',
      caption: 'Meetup with local rescue puppies at Central Park! 🎉',
      timeAgo: '6h ago',
    ),
    const PawStory(
      id: 'story-5',
      petName: 'Milo',
      authorName: 'Chris Evans',
      avatarUrl:
          'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=150',
      imageUrl:
          'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=800',
      caption: 'Graduated from intermediate agility course today! 🏅🐾',
      timeAgo: '8h ago',
    ),
  ];

  void _openStoryViewer(int index) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (ctx, anim, __) => FadeTransition(
          opacity: anim,
          child: _PawStoryViewerScreen(
            stories: _stories,
            initialIndex: index,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final userProfile = ref.watch(currentUserProfileProvider).valueOrNull;

    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _stories.length + 1,
        separatorBuilder: (_, __) => AppSpacing.hGapSm,
        itemBuilder: (context, index) {
          if (index == 0) {
            // "Your Story" button
            return GestureDetector(
              onTap: () => context.push(RoutePaths.ownerCommunityCreatePost),
              child: SizedBox(
                width: 76,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: scheme.outlineVariant.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: scheme.primaryContainer,
                            backgroundImage: (userProfile?.avatarUrl != null &&
                                    userProfile!.avatarUrl!.isNotEmpty)
                                ? NetworkImage(userProfile.avatarUrl!)
                                : null,
                            child: (userProfile?.avatarUrl == null ||
                                    userProfile!.avatarUrl!.isEmpty)
                                ? Icon(Icons.pets, color: scheme.primary, size: 24)
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: scheme.surface,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your Story',
                      style: context.textTheme.labelSmall?.copyWith(
                        fontWeight: AppTypography.medium,
                        color: scheme.onSurface,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }

          final story = _stories[index - 1];
          return GestureDetector(
            onTap: () => _openStoryViewer(index - 1),
            child: SizedBox(
              width: 76,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: story.isViewed
                          ? LinearGradient(
                              colors: [
                                scheme.outlineVariant,
                                scheme.outlineVariant.withValues(alpha: 0.5),
                              ],
                            )
                          : const LinearGradient(
                              colors: [
                                Color(0xFF833AB4),
                                Color(0xFFFD1D1D),
                                Color(0xFFF77737),
                                Color(0xFFFFDC80),
                              ],
                              begin: Alignment.bottomLeft,
                              end: Alignment.topRight,
                            ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.surface,
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: scheme.surfaceContainerHigh,
                        backgroundImage: NetworkImage(story.avatarUrl),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story.petName,
                    style: context.textTheme.labelSmall?.copyWith(
                      fontWeight: AppTypography.bold,
                      color: scheme.onSurface,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Full-screen Instagram/Snapchat style Story Viewer with timed progression.
class _PawStoryViewerScreen extends StatefulWidget {
  const _PawStoryViewerScreen({
    required this.stories,
    required this.initialIndex,
  });

  final List<PawStory> stories;
  final int initialIndex;

  @override
  State<_PawStoryViewerScreen> createState() => _PawStoryViewerScreenState();
}

class _PawStoryViewerScreenState extends State<_PawStoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  final TextEditingController _replyController = TextEditingController();
  bool _isPaused = false;
  bool _isLiked = false;

  static const Duration _storyDuration = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _progressController = AnimationController(
      vsync: this,
      duration: _storyDuration,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _startStory();
  }

  void _startStory() {
    _isLiked = false;
    _progressController.stop();
    _progressController.reset();
    _progressController.forward();
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() => _currentIndex++);
      _startStory();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _startStory();
    } else {
      _startStory();
    }
  }

  void _pauseStory() {
    if (!_isPaused) {
      _isPaused = true;
      _progressController.stop();
    }
  }

  void _resumeStory() {
    if (_isPaused) {
      _isPaused = false;
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = widget.stories[_currentIndex];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => _pauseStory(),
        onLongPressEnd: (_) => _resumeStory(),
        onTapUp: (details) {
          final x = details.globalPosition.dx;
          if (x < size.width * 0.3) {
            _prevStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Story Image ──────────────────────────────────────────────
            Image.network(
              story.imageUrl,
              fit: BoxFit.cover,
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
                child: Icon(Icons.broken_image_rounded,
                    color: Colors.white38, size: 64),
              ),
            ),

            // ── Top Gradient Overlay ─────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 160,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Bottom Gradient Overlay ──────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Story Progress Segment Bars ──────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: Row(
                children: List.generate(widget.stories.length, (index) {
                  return Expanded(
                    child: Container(
                      height: 2.5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: index < _currentIndex
                          ? Container(color: Colors.white)
                          : index == _currentIndex
                              ? AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (context, _) {
                                    return FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: _progressController.value,
                                      child: Container(color: Colors.white),
                                    );
                                  },
                                )
                              : const SizedBox.shrink(),
                    ),
                  );
                }),
              ),
            ),

            // ── Story Header: Avatar, Name, Time, Close ───────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(story.avatarUrl),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${story.petName} • ${story.authorName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          story.timeAgo,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 26),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Story Caption & Interactive Reply Bar ────────────────────
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 12,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Caption
                  if (story.caption.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Text(
                        story.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Quick Reply & Reaction Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: AppRadius.brPill,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: TextField(
                            controller: _replyController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Send message to owner...',
                              hintStyle: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              border: InputBorder.none,
                            ),
                            onTap: _pauseStory,
                            onSubmitted: (val) {
                              _resumeStory();
                              _replyController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Message sent to owner!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Heart Reaction
                      IconButton(
                        icon: Icon(
                          _isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _isLiked ? Colors.redAccent : Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() => _isLiked = !_isLiked);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
