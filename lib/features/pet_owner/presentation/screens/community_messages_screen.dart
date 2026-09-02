import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/realtime/domain/entities/direct_message.dart';
import 'package:petconnect_ai/features/realtime/presentation/providers/realtime_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Active conversation summary thread for the inbox view
class _ConversationThread {
  _ConversationThread({
    required this.peerProfile,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isLastMsgFromMe,
    required this.isRead,
    required this.unreadCount,
  });

  final Map<String, dynamic> peerProfile;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isLastMsgFromMe;
  final bool isRead;
  final int unreadCount;
}

/// **Modern Messenger & Community Group Chat Hub**
///
/// Features:
/// 1. **Conversations Feed (Direct Chats)**: Shows ONLY accounts with active message history with snippets & read ticks.
/// 2. **Start New Chat Directory Modal**: Discover and message non-admin pet parents, vets, and rescue responders.
/// 3. **Delivery Ticks**: Single tick (sent) vs cyan double tick (read).
/// 4. **Community Groups**: Multi-user group chat channels with real-time broadcasting.
class CommunityMessagesScreen extends ConsumerStatefulWidget {
  const CommunityMessagesScreen({super.key, this.initialOtherUserId, this.otherUserId});

  final String? initialOtherUserId;
  final String? otherUserId;

  @override
  ConsumerState<CommunityMessagesScreen> createState() =>
      _CommunityMessagesScreenState();
}

class _CommunityMessagesScreenState
    extends ConsumerState<CommunityMessagesScreen>
    with SingleTickerProviderStateMixin {
  int _selectedMessengerTab = 0; // 0 = Direct, 1 = Groups
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  final _groupMessageController = TextEditingController();
  final _scrollController = ScrollController();
  final _groupScrollController = ScrollController();
  bool _isSending = false;
  String _searchQuery = '';

  final List<String> _filters = const ['All', 'Pet Parents', 'Vets', 'Rescues'];
  final List<String> _groupCategories = const [
    'Community',
    'Breed Club',
    'Veterinary',
    'Rescue & Volunteer',
    'Training & Play',
    'Adoption',
  ];

  Map<String, dynamic>? _activeContact;
  Map<String, dynamic>? _activeGroup;

  List<_ConversationThread> _conversationThreads = [];
  List<Map<String, dynamic>> _communityProfiles = [];
  List<Map<String, dynamic>> _communityGroups = [];
  List<Map<String, dynamic>> _groupMessages = [];
  bool _loadingConversations = true;
  bool _loadingProfiles = true;
  bool _loadingGroups = true;
  bool _loadingGroupMessages = false;

  RealtimeChannel? _groupRealtimeChannel;

  // Local messages merged with realtime stream
  final List<DirectMessage> _localMessages = [];

  String? get _effectiveOtherUserId =>
      widget.initialOtherUserId ?? widget.otherUserId;

  @override
  void initState() {
    super.initState();
    if (_effectiveOtherUserId != null && _effectiveOtherUserId!.isNotEmpty) {
      unawaited(_openDirectUserById(_effectiveOtherUserId!));
    }
    _loadConversations();
    _loadCommunityProfiles();
    _loadCommunityGroups();
  }

  @override
  void didUpdateWidget(covariant CommunityMessagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _effectiveOtherUserId;
    if (target != null &&
        target.isNotEmpty &&
        (target != oldWidget.initialOtherUserId && target != oldWidget.otherUserId)) {
      unawaited(_openDirectUserById(target));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _groupMessageController.dispose();
    _scrollController.dispose();
    _groupScrollController.dispose();
    _groupRealtimeChannel?.unsubscribe();
    super.dispose();
  }

  /// Load active conversation threads where current user exchanged messages
  Future<void> _loadConversations() async {
    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;

    if (currentUserId == null) {
      if (mounted) setState(() => _loadingConversations = false);
      return;
    }

    try {
      final res = await client
          .from('direct_messages')
          .select('id, sender_id, receiver_id, message_text, is_read, created_at')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .order('created_at', ascending: false);

      final allMsgs = (res as List<dynamic>).cast<Map<String, dynamic>>();

      // Group by peer
      final peerMap = <String, List<Map<String, dynamic>>>{};
      for (final msg in allMsgs) {
        final sender = msg['sender_id'] as String;
        final receiver = msg['receiver_id'] as String;
        final peerId = sender == currentUserId ? receiver : sender;

        peerMap.putIfAbsent(peerId, () => []).add(msg);
      }

      final peerIds = peerMap.keys.toList();
      final profilesMap = <String, Map<String, dynamic>>{};

      if (peerIds.isNotEmpty) {
        final profRes = await client
            .from('profiles')
            .select('id, full_name, avatar_url, city, role, bio')
            .inFilter('id', peerIds);

        for (final p in (profRes as List<dynamic>)) {
          final pMap = p as Map<String, dynamic>;
          final role = (pMap['role'] as String? ?? '').toLowerCase();
          // Exclude administrators
          if (!role.contains('admin')) {
            profilesMap[pMap['id'] as String] = pMap;
          }
        }
      }

      final threads = <_ConversationThread>[];
      for (final entry in peerMap.entries) {
        final peerId = entry.key;
        final profile = profilesMap[peerId];
        if (profile == null) continue; // Skip admin or non-existent profile

        final msgs = entry.value;
        final latest = msgs.first;
        final isFromMe = latest['sender_id'] == currentUserId;
        final unread = msgs
            .where((m) => m['sender_id'] == peerId && (m['is_read'] == false || m['is_read'] == null))
            .length;

        threads.add(
          _ConversationThread(
            peerProfile: profile,
            lastMessage: latest['message_text'] as String? ?? '',
            lastMessageTime: DateTime.tryParse(latest['created_at'] as String? ?? '') ?? DateTime.now(),
            isLastMsgFromMe: isFromMe,
            isRead: (latest['is_read'] as bool?) ?? false,
            unreadCount: unread,
          ),
        );
      }

      threads.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      if (mounted) {
        setState(() {
          _conversationThreads = threads;
          _loadingConversations = false;
        });

        // If navigated directly with a target user ID and no contact is active yet, open that chat immediately
        if (_effectiveOtherUserId != null && _activeContact == null) {
          unawaited(_openDirectUserById(_effectiveOtherUserId!));
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingConversations = false);
    }
  }

  Future<void> _openDirectUserById(String targetId) async {
    final client = ref.read(supabaseClientProvider);
    try {
      final pRes = await client
          .from('profiles')
          .select('id, full_name, avatar_url, city, role, bio')
          .eq('id', targetId)
          .maybeSingle();

      final contact = pRes ?? {
        'id': targetId,
        'full_name': 'Community Member',
        'city': 'Kerala',
        'role': 'pet_owner',
      };

      if (mounted) {
        await _selectContact(contact);
      }
    } catch (_) {
      if (mounted) {
        await _selectContact({
          'id': targetId,
          'full_name': 'Community Member',
          'city': 'Kerala',
          'role': 'pet_owner',
        });
      }
    }
  }

  /// Load directory profiles (excluding administrators) for New Chat discovery
  Future<void> _loadCommunityProfiles() async {
    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;

    try {
      final res = await client
          .from('profiles')
          .select('id, full_name, avatar_url, city, role, bio')
          .neq('id', currentUserId ?? '')
          .neq('role', 'administrator')
          .neq('role', 'admin')
          .limit(40);

      final list = (res as List<dynamic>).cast<Map<String, dynamic>>();

      if (mounted) {
        setState(() {
          _communityProfiles = list;
          _loadingProfiles = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingProfiles = false);
      }
    }
  }

  Future<void> _loadCommunityGroups() async {
    final client = ref.read(supabaseClientProvider);

    try {
      final res = await client
          .from('community_groups')
          .select('id, name, description, avatar_url, category, city, created_at')
          .order('created_at', ascending: false);

      final list = (res as List<dynamic>).cast<Map<String, dynamic>>();

      if (mounted) {
        setState(() {
          _communityGroups = list;
          _loadingGroups = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingGroups = false);
      }
    }
  }

  Future<void> _selectContact(Map<String, dynamic> contact) async {
    await HapticFeedback.lightImpact();
    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;
    final targetId = contact['id'] as String?;

    setState(() {
      _activeContact = contact;
      _activeGroup = null;
      _localMessages.clear();
    });

    if (currentUserId != null && targetId != null) {
      try {
        await client
            .from('direct_messages')
            .update({'is_read': true})
            .eq('sender_id', targetId)
            .eq('receiver_id', currentUserId)
            .eq('is_read', false);
        ref.invalidate(directMessagesProvider(targetId));
      } catch (_) {}
    }
  }

  void _selectGroup(Map<String, dynamic> group) async {
    await HapticFeedback.lightImpact();
    setState(() {
      _activeGroup = group;
      _activeContact = null;
      _groupMessages.clear();
      _loadingGroupMessages = true;
    });

    await _loadGroupMessages(group['id'] as String);
    _subscribeToGroupRealtime(group['id'] as String);
  }

  Future<void> _loadGroupMessages(String groupId) async {
    final client = ref.read(supabaseClientProvider);

    try {
      final res = await client
          .from('community_group_messages')
          .select('id, group_id, sender_id, message_text, media_url, created_at')
          .eq('group_id', groupId)
          .order('created_at', ascending: true);

      final rawMsgs = (res as List<dynamic>).cast<Map<String, dynamic>>();

      final senderIds = rawMsgs
          .map((m) => m['sender_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      final profilesMap = <String, Map<String, dynamic>>{};
      if (senderIds.isNotEmpty) {
        final profRes = await client
            .from('profiles')
            .select('id, full_name, avatar_url')
            .inFilter('id', senderIds);

        for (final p in (profRes as List<dynamic>)) {
          final pMap = p as Map<String, dynamic>;
          profilesMap[pMap['id'] as String] = pMap;
        }
      }

      final parsed = rawMsgs.map((m) {
        return {
          ...m,
          'sender': profilesMap[m['sender_id']] ?? {
            'id': m['sender_id'],
            'full_name': 'Member',
          },
        };
      }).toList();

      if (mounted) {
        setState(() {
          _groupMessages = parsed;
          _loadingGroupMessages = false;
        });
        _scrollToGroupBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingGroupMessages = false);
      }
    }
  }

  void _subscribeToGroupRealtime(String groupId) {
    _groupRealtimeChannel?.unsubscribe();
    final client = ref.read(supabaseClientProvider);

    _groupRealtimeChannel = client
        .channel('public:community_group_messages:$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'community_group_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) async {
            final newRecord = payload.newRecord;
            final senderId = newRecord['sender_id'] as String?;

            Map<String, dynamic>? senderProfile;
            if (senderId != null) {
              final prof = await client
                  .from('profiles')
                  .select('id, full_name, avatar_url')
                  .eq('id', senderId)
                  .maybeSingle();
              senderProfile = prof;
            }

            final enriched = {
              ...newRecord,
              'sender': senderProfile ?? {'full_name': 'Member'},
            };

            if (mounted) {
              setState(() {
                if (!_groupMessages.any((m) => m['id'] == enriched['id'])) {
                  _groupMessages.add(enriched);
                }
              });
              _scrollToGroupBottom();
            }
          },
        )
        .subscribe();
  }

  void _backToInbox() {
    unawaited(HapticFeedback.lightImpact());
    _groupRealtimeChannel?.unsubscribe();
    unawaited(_loadConversations()); // Refresh inbox list
    setState(() {
      _activeContact = null;
      _activeGroup = null;
      _localMessages.clear();
      _groupMessages.clear();
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending || _activeContact == null) return;

    final targetUserId = _activeContact!['id'] as String;
    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final repo = ref.read(realtimeRepositoryProvider);
      final result = await repo.sendDirectMessage(
        receiverId: targetUserId,
        text: text,
      );

      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send: ${failure.message}')),
            );
          }
        },
        (sentMessage) {
          ref.invalidate(directMessagesProvider(targetUserId));
          setState(() {
            if (!_localMessages.any((m) => m.id == sentMessage.id)) {
              _localMessages.add(sentMessage);
            }
          });
          _scrollToBottom();
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _sendGroupMessage() async {
    final text = _groupMessageController.text.trim();
    if (text.isEmpty || _isSending || _activeGroup == null) return;

    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) return;

    final groupId = _activeGroup!['id'] as String;
    setState(() => _isSending = true);
    _groupMessageController.clear();

    try {
      final res = await client.from('community_group_messages').insert({
        'group_id': groupId,
        'sender_id': currentUserId,
        'message_text': text,
      }).select().single();

      final myProf = ref.read(currentUserProfileProvider).valueOrNull;
      final enriched = {
        ...res,
        'sender': {
          'id': currentUserId,
          'full_name': myProf?.fullName ?? 'Me',
          'avatar_url': myProf?.avatarUrl,
        },
      };

      setState(() {
        if (!_groupMessages.any((m) => m['id'] == enriched['id'])) {
          _groupMessages.add(enriched);
        }
      });
      _scrollToGroupBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send group message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _openCreateGroupDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    String selectedCategory = _groupCategories.first;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final scheme = Theme.of(context).colorScheme;

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.group_add_rounded, color: scheme.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Create Community Group',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      hintText: 'e.g. Kochi Golden Retrievers Club',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'What is this group about?',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_rounded),
                    ),
                    items: _groupCategories.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'City / Region',
                      hintText: 'e.g. Kochi, Thrissur, Bangalore',
                      prefixIcon: Icon(Icons.location_on_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Create & Launch Group'),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final desc = descCtrl.text.trim();
                        final city = cityCtrl.text.trim();

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please enter a group name')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        await HapticFeedback.mediumImpact();

                        try {
                          final client = ref.read(supabaseClientProvider);
                          final currentUserId = client.auth.currentUser?.id;

                          final newGroup = await client
                              .from('community_groups')
                              .insert({
                                'name': name,
                                'description': desc,
                                'category': selectedCategory,
                                'city': city.isNotEmpty ? city : 'Kerala',
                                'created_by': currentUserId,
                              })
                              .select()
                              .single();

                          if (currentUserId != null) {
                            await client.from('community_group_members').insert({
                              'group_id': newGroup['id'],
                              'user_id': currentUserId,
                              'role': 'admin',
                            });
                          }

                          await _loadCommunityGroups();

                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text('Group "$name" created successfully!')),
                          );
                          _selectGroup(newGroup);
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text('Failed to create group: $e')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Open New Chat Directory Dialog to discover and message any community member
  void _openNewChatDirectoryDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final scheme = Theme.of(context).colorScheme;
          String modalSearch = '';

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.person_search_rounded, color: scheme.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Start New Conversation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search people by name or city...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onChanged: (val) {
                      setModalState(() => modalSearch = val.toLowerCase().trim());
                    },
                  ),
                ),
                const Divider(height: 12),
                Expanded(
                  child: _loadingProfiles
                      ? const Center(child: CircularProgressIndicator())
                      : _communityProfiles.isEmpty
                          ? Center(
                              child: Text(
                                'No community members available',
                                style: TextStyle(color: scheme.onSurfaceVariant),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: _communityProfiles.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final profile = _communityProfiles[i];
                                final name = (profile['full_name'] as String?) ?? 'Community Member';
                                final city = (profile['city'] as String?) ?? 'Kerala';
                                final avatar = profile['avatar_url'] as String?;
                                final role = (profile['role'] as String?) ?? 'pet_owner';

                                if (modalSearch.isNotEmpty &&
                                    !name.toLowerCase().contains(modalSearch) &&
                                    !city.toLowerCase().contains(modalSearch)) {
                                  return const SizedBox.shrink();
                                }

                                String roleTag = '🐾 Pet Parent';
                                if (role.contains('vet')) roleTag = '🩺 Veterinarian';
                                if (role.contains('rescue') || role.contains('volunteer')) {
                                  roleTag = '🚑 Rescue Responder';
                                }

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  leading: CircleAvatar(
                                    radius: 22,
                                    backgroundColor: scheme.primaryContainer,
                                    backgroundImage: (avatar != null && avatar.isNotEmpty)
                                        ? NetworkImage(avatar)
                                        : null,
                                    child: (avatar == null || avatar.isEmpty)
                                        ? Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: scheme.onPrimaryContainer,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Row(
                                    children: [
                                      Text(
                                        roleTag,
                                        style: TextStyle(fontSize: 11, color: scheme.primary, fontWeight: FontWeight.w600),
                                      ),
                                      Text(' • $city', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                                    ],
                                  ),
                                  trailing: FilledButton.tonal(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _selectContact(profile);
                                    },
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    ),
                                    child: const Text('Chat', style: TextStyle(fontSize: 12)),
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToGroupBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_groupScrollController.hasClients) {
        _groupScrollController.animateTo(
          _groupScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(DateTime dt) {
    final localDt = dt.toLocal();
    final hour = localDt.hour > 12 ? localDt.hour - 12 : (localDt.hour == 0 ? 12 : localDt.hour);
    final period = localDt.hour >= 12 ? 'PM' : 'AM';
    final minute = localDt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatRelativeTime(DateTime dt) {
    final localDt = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(localDt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${localDt.day}/${localDt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final currentUserId =
        ref.watch(supabaseClientProvider).auth.currentUser?.id ?? '';
    final isInsideChat = _activeContact != null || _activeGroup != null;

    return PopScope(
      canPop: !isInsideChat,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isInsideChat) {
          _backToInbox();
        }
      },
      child: isInsideChat
          ? (_activeContact != null
              ? _buildOneOnOneChatScreen(context, scheme, currentUserId)
              : _buildGroupChatScreen(context, scheme, currentUserId))
          : _buildInboxScreen(context, scheme),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // VIEW 1: MESSENGER INBOX (DIRECT CONVERSATIONS FEED + COMMUNITY GROUPS)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildInboxScreen(BuildContext context, ColorScheme scheme) {
    final filteredThreads = _conversationThreads.where((t) {
      final name = (t.peerProfile['full_name'] as String? ?? '').toLowerCase();
      final city = (t.peerProfile['city'] as String? ?? '').toLowerCase();
      final lastMsg = t.lastMessage.toLowerCase();
      final role = (t.peerProfile['role'] as String? ?? '').toLowerCase();

      final matchesQuery = _searchQuery.isEmpty ||
          name.contains(_searchQuery) ||
          city.contains(_searchQuery) ||
          lastMsg.contains(_searchQuery);

      if (!matchesQuery) return false;

      if (_selectedFilter == 'Pet Parents') {
        return role.contains('owner') || role.contains('parent') || role.isEmpty;
      } else if (_selectedFilter == 'Vets') {
        return role.contains('vet') || role.contains('doctor');
      } else if (_selectedFilter == 'Rescues') {
        return role.contains('rescue') || role.contains('shelter') || role.contains('volunteer');
      }
      return true;
    }).toList();

    final filteredGroups = _communityGroups.where((g) {
      final name = (g['name'] as String? ?? '').toLowerCase();
      final cat = (g['category'] as String? ?? '').toLowerCase();
      final city = (g['city'] as String? ?? '').toLowerCase();

      return _searchQuery.isEmpty ||
          name.contains(_searchQuery) ||
          cat.contains(_searchQuery) ||
          city.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Messenger',
          style: context.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_selectedMessengerTab == 0)
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_rounded),
              tooltip: 'New Chat',
              onPressed: () => _openNewChatDirectoryDialog(context),
            )
          else
            IconButton(
              icon: const Icon(Icons.group_add_rounded),
              tooltip: 'New Group',
              onPressed: _openCreateGroupDialog,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              _loadConversations();
              _loadCommunityGroups();
            },
          ),
        ],
      ),
      floatingActionButton: _selectedMessengerTab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openNewChatDirectoryDialog(context),
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Start New Chat', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : FloatingActionButton.extended(
              onPressed: _openCreateGroupDialog,
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('New Group', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _selectedMessengerTab == 0
                    ? 'Search conversations...'
                    : 'Search community groups & clubs...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: scheme.surfaceContainerHigh.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val.toLowerCase().trim());
              },
            ),
          ),

          // Dual-Tab Switcher: Direct Chats vs Community Groups
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _selectedMessengerTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedMessengerTab == 0
                              ? scheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 16,
                              color: _selectedMessengerTab == 0
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Direct Chats (${_conversationThreads.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedMessengerTab == 0
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() => _selectedMessengerTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedMessengerTab == 1
                              ? scheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.groups_rounded,
                              size: 18,
                              color: _selectedMessengerTab == 1
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Community Groups (${_communityGroups.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _selectedMessengerTab == 1
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sub-Filter Chips for Direct Tab
          if (_selectedMessengerTab == 0)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      showCheckmark: false,
                      selectedColor: scheme.primaryContainer,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (val) {
                        if (val) setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          const Divider(height: 1),

          // Content List
          Expanded(
            child: _selectedMessengerTab == 0
                ? _buildDirectChatsList(filteredThreads, scheme)
                : _buildGroupsList(filteredGroups, scheme),
          ),
        ],
      ),
    );
  }

  /// Build Active Direct Conversations List (Conversations Feed)
  Widget _buildDirectChatsList(
    List<_ConversationThread> filteredThreads,
    ColorScheme scheme,
  ) {
    if (_loadingConversations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredThreads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mark_chat_unread_outlined,
                  size: 56, color: scheme.primary.withValues(alpha: 0.6)),
              const SizedBox(height: 12),
              Text(
                'No active conversations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Connect with pet parents, veterinarians, and rescue responders in your community.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                icon: const Icon(Icons.person_search_rounded, size: 18),
                label: const Text('Discover & Start Chat'),
                onPressed: () => _openNewChatDirectoryDialog(context),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredThreads.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (ctx, i) {
        final thread = filteredThreads[i];
        final profile = thread.peerProfile;
        final name = (profile['full_name'] as String?) ?? 'Community Member';
        final avatarUrl = profile['avatar_url'] as String?;
        final role = (profile['role'] as String?) ?? 'pet_owner';

        String roleTag = '🐾 Pet Parent';
        if (role.contains('vet')) roleTag = '🩺 Vet';
        if (role.contains('rescue') || role.contains('volunteer')) roleTag = '🚑 Rescue';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: () => _selectContact(profile),
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: scheme.primaryContainer,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: thread.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                _formatRelativeTime(thread.lastMessageTime),
                style: TextStyle(
                  fontSize: 11,
                  color: thread.unreadCount > 0 ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: thread.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              if (thread.isLastMsgFromMe) ...[
                Icon(
                  thread.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                  size: 14,
                  color: thread.isRead ? const Color(0xFF06B6D4) : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  thread.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: thread.unreadCount > 0 ? scheme.onSurface : scheme.onSurfaceVariant,
                    fontWeight: thread.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (thread.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${thread.unreadCount}',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Text(
                  roleTag,
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Build Community Groups List
  Widget _buildGroupsList(
    List<Map<String, dynamic>> filteredGroups,
    ColorScheme scheme,
  ) {
    if (_loadingGroups) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined,
                size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No groups found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to create a community pet group!',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Create Community Group'),
              onPressed: _openCreateGroupDialog,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredGroups.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (ctx, i) {
        final group = filteredGroups[i];
        final name = (group['name'] as String?) ?? 'Group';
        final desc = (group['description'] as String?) ?? 'Active group';
        final category = (group['category'] as String?) ?? 'Community';
        final city = (group['city'] as String?) ?? 'Kerala';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: () => _selectGroup(group),
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: scheme.secondaryContainer,
            child: Icon(Icons.groups_rounded, color: scheme.onSecondaryContainer, size: 28),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '📍 $city',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant.withValues(alpha: 0.8)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // VIEW 2: 1-ON-1 DIRECT CHAT SCREEN (WITH DELIVERY TICKS & PERSISTENCE)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildOneOnOneChatScreen(
    BuildContext context,
    ColorScheme scheme,
    String currentUserId,
  ) {
    final otherUser = _activeContact!;
    final otherUserId = otherUser['id'] as String;
    final otherName = (otherUser['full_name'] as String?) ?? 'Community Member';
    final otherAvatar = otherUser['avatar_url'] as String?;
    final otherRole = (otherUser['role'] as String?) ?? 'pet_owner';
    final otherCity = (otherUser['city'] as String?) ?? 'Kerala';

    String roleBadge = '🐾 Pet Parent';
    if (otherRole.contains('vet')) roleBadge = '🩺 Veterinarian';
    if (otherRole.contains('rescue') || otherRole.contains('volunteer')) {
      roleBadge = '🚑 Rescue Responder';
    }

    final messagesAsync = ref.watch(directMessagesProvider(otherUserId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Inbox',
          onPressed: _backToInbox,
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primaryContainer,
              backgroundImage: otherAvatar != null && otherAvatar.isNotEmpty
                  ? NetworkImage(otherAvatar)
                  : null,
              child: otherAvatar == null || otherAvatar.isEmpty
                  ? Text(
                      otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$roleBadge • $otherCity',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Chat',
            onPressed: () => ref.invalidate(directMessagesProvider(otherUserId)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: Colors.orange),
                    const SizedBox(height: 8),
                    Text('Failed to load messages: $err'),
                    TextButton(
                      onPressed: () => ref.invalidate(directMessagesProvider(otherUserId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (streamedMessages) {
                final displayMessages = List<DirectMessage>.from(streamedMessages);
                for (final local in _localMessages) {
                  if (!displayMessages.any((m) => m.id == local.id)) {
                    displayMessages.add(local);
                  }
                }
                displayMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

                if (displayMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: scheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Say hello to $otherName!',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Direct messages are private and encrypted',
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: displayMessages.length,
                  itemBuilder: (ctx, i) {
                    final msg = displayMessages[i];
                    final isUser = msg.senderId == currentUserId;

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isUser
                              ? LinearGradient(
                                  colors: [
                                    scheme.primary,
                                    scheme.primary.withValues(alpha: 0.85),
                                  ],
                                )
                              : null,
                          color: isUser ? null : scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isUser ? 18 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.messageText,
                              style: TextStyle(
                                color: isUser ? Colors.white : scheme.onSurface,
                                fontSize: 14.5,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTimestamp(msg.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isUser
                                        ? Colors.white.withValues(alpha: 0.75)
                                        : scheme.onSurfaceVariant.withValues(alpha: 0.75),
                                  ),
                                ),
                                if (isUser) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                                    size: 13,
                                    color: msg.isRead
                                        ? const Color(0xFF67E8F9) // Cyan double tick for read
                                        : Colors.white.withValues(alpha: 0.8), // Single white tick for sent
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message $otherName...',
                        filled: true,
                        fillColor: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (_isSending)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    )
                  else
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                      ),
                      onPressed: _sendMessage,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // VIEW 3: MULTI-USER COMMUNITY GROUP CHAT
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildGroupChatScreen(
    BuildContext context,
    ColorScheme scheme,
    String currentUserId,
  ) {
    final group = _activeGroup!;
    final groupName = (group['name'] as String?) ?? 'Group';
    final category = (group['category'] as String?) ?? 'Community';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Groups',
          onPressed: _backToInbox,
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.secondaryContainer,
              child: Icon(Icons.groups_rounded, color: scheme.onSecondaryContainer, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$category • Group Chat',
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Group Info',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(groupName),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category: $category'),
                      const SizedBox(height: 8),
                      Text('Description: ${group['description'] ?? 'No description'}'),
                      const SizedBox(height: 8),
                      Text('City: ${group['city'] ?? 'Kerala'}'),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingGroupMessages
                ? const Center(child: CircularProgressIndicator())
                : _groupMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.forum_outlined,
                              size: 48,
                              color: scheme.primary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Welcome to $groupName!',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Say hello to start the discussion',
                              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _groupScrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        itemCount: _groupMessages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _groupMessages[i];
                          final senderId = msg['sender_id'] as String?;
                          final isUser = senderId == currentUserId;
                          final senderProfile = msg['sender'] as Map<String, dynamic>?;
                          final senderName = (senderProfile?['full_name'] as String?) ?? 'Member';
                          final text = (msg['message_text'] as String?) ?? '';
                          final dt = DateTime.tryParse(msg['created_at'] as String? ?? '') ??
                              DateTime.now();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment:
                                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isUser) ...[
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: scheme.primaryContainer,
                                    child: Text(
                                      senderName.isNotEmpty ? senderName[0].toUpperCase() : 'M',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: scheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    gradient: isUser
                                        ? LinearGradient(
                                            colors: [
                                              scheme.primary,
                                              scheme.primary.withValues(alpha: 0.85),
                                            ],
                                          )
                                        : null,
                                    color: isUser ? null : scheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                                      bottomRight: Radius.circular(isUser ? 4 : 16),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isUser
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (!isUser)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 2.0),
                                          child: Text(
                                            senderName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: scheme.primary,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        text,
                                        style: TextStyle(
                                          color: isUser ? Colors.white : scheme.onSurface,
                                          fontSize: 14,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatTimestamp(dt),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          color: isUser
                                              ? Colors.white.withValues(alpha: 0.75)
                                              : scheme.onSurfaceVariant.withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Bar for Group Chat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _groupMessageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message $groupName...',
                        filled: true,
                        fillColor: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendGroupMessage(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (_isSending)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    )
                  else
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                      ),
                      onPressed: _sendGroupMessage,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
