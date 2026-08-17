import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/features/realtime/domain/entities/direct_message.dart';
import 'package:petconnect_ai/features/realtime/presentation/providers/realtime_providers.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// A live Flutter rendering of the Stitch **Community Messages**
/// (Light Theme design authority, ID `ec84e328`).
///
/// Enables direct messaging between pet owners, rescue volunteers, and vets
/// backed by Supabase Realtime WebSocket streams and `public.direct_messages`.
class CommunityMessagesScreen extends ConsumerStatefulWidget {
  const CommunityMessagesScreen({super.key, this.otherUserId});

  final String? otherUserId;

  @override
  ConsumerState<CommunityMessagesScreen> createState() =>
      _CommunityMessagesScreenState();
}

class _CommunityMessagesScreenState
    extends ConsumerState<CommunityMessagesScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedFilter = 'All';
  final _messageController = TextEditingController();
  bool _isSending = false;

  final List<String> _filters = const ['All', 'Owners', 'Volunteers', 'Vets'];

  // Local message cache merged with realtime stream
  final List<DirectMessage> _localMessages = [];

  String get _effectiveOtherUserId =>
      widget.otherUserId ?? '00000000-0000-0000-0000-000000000001';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final repo = ref.read(realtimeRepositoryProvider);
      final result = await repo.sendDirectMessage(
        receiverId: _effectiveOtherUserId,
        text: text,
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send message: ${failure.message}')),
            );
          }
        },
        (sentMessage) {
          setState(() {
            if (!_localMessages.any((m) => m.id == sentMessage.id)) {
              _localMessages.add(sentMessage);
            }
          });
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final currentUserId =
        ref.watch(supabaseClientProvider).auth.currentUser?.id ?? '';

    // Listen to live stream of direct messages
    ref.listen<AsyncValue<DirectMessage>>(
      liveDirectMessagesStreamProvider(_effectiveOtherUserId),
      (previous, next) {
        next.whenData((incoming) {
          setState(() {
            if (!_localMessages.any((m) => m.id == incoming.id)) {
              _localMessages.add(incoming);
            }
          });
        });
      },
    );

    final initialMessagesAsync = ref.watch(
      directMessagesProvider(_effectiveOtherUserId),
    );

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Messages',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square),
            tooltip: 'New Message',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Start new message...')),
              );
            },
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
                // ── Search & Filter Controls ───────────────────────
                const AppTextField(
                  hintText: 'Search messages...',
                  prefixIcon: Icon(Icons.search),
                ),
                AppSpacing.vGapSm,
                Row(
                  children:
                      _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            selectedColor: scheme.primary,
                            backgroundColor: scheme.surfaceContainerHigh,
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? scheme.onPrimary
                                      : scheme.onSurface,
                              fontWeight: AppTypography.semiBold,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedFilter = filter);
                              }
                            },
                          ),
                        );
                      }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── AI Chat Summary Banner ────────────────────────
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
                            'AI Summary Available',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        'Direct messaging channel secured by end-to-end Supabase RLS and real-time streaming.',
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Active Chat Header ────────────────────────────
                AppCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const UserAvatar(
                          name: 'Community Contact',
                          radius: 20,
                        ),
                        title: Row(
                          children: [
                            Text(
                              'Community Contact',
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: AppTypography.bold,
                              ),
                            ),
                            AppSpacing.hGapXs,
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        subtitle: const Text('Live Realtime'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.call_outlined),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      AppSpacing.vGapSm,

                      // ── Chat Messages ───────────────────────────
                      initialMessagesAsync.when(
                        loading:
                            () => const Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        error:
                            (err, stack) => Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                'Error loading conversation: $err',
                                style: TextStyle(color: scheme.error),
                              ),
                            ),
                        data: (loaded) {
                          // Merge loaded list with local realtime items
                          final displayMap = <String, DirectMessage>{};
                          for (final m in loaded) {
                            displayMap[m.id] = m;
                          }
                          for (final m in _localMessages) {
                            displayMap[m.id] = m;
                          }
                          final displayMessages =
                              displayMap.values.toList()
                                ..sort(
                                  (a, b) =>
                                      a.createdAt.compareTo(b.createdAt),
                                );

                          if (displayMessages.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.lg,
                              ),
                              child: Center(
                                child: Text(
                                  'No messages yet. Send a message below to start chatting!',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: displayMessages.length,
                            itemBuilder: (context, index) {
                              final msg = displayMessages[index];
                              final isUser = msg.senderId == currentUserId;

                              return Align(
                                alignment:
                                    isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  constraints: const BoxConstraints(
                                    maxWidth: 300,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isUser
                                            ? scheme.primaryContainer
                                            : scheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.messageText,
                                        style: TextStyle(
                                          color:
                                              isUser
                                                  ? scheme.onPrimaryContainer
                                                  : scheme.onSurface,
                                        ),
                                      ),
                                      AppSpacing.vGapXs,
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          _formatTimestamp(msg.createdAt),
                                          style: context.textTheme.labelSmall
                                              ?.copyWith(
                                                color:
                                                    scheme.onSurfaceVariant,
                                                fontSize: 10,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      AppSpacing.vGapSm,

                      // ── Input Bar ───────────────────────────────
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {},
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                filled: true,
                                fillColor: scheme.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.full,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          if (_isSending)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else
                            IconButton(
                              icon: Icon(Icons.send, color: scheme.primary),
                              onPressed: _sendMessage,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
