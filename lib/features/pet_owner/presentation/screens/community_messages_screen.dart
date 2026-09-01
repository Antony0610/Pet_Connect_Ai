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

/// **Modern Messenger & Community Group Chat Hub**
///
/// Features:
/// 1. **Direct Messages (1-on-1)**: Private chats with delivery ticks, search, filters, and real-time streaming.
/// 2. **Community Groups**: Multi-user group chat channels with group creation, category badges, member counts, and live broadcast.
class CommunityMessagesScreen extends ConsumerStatefulWidget {
  const CommunityMessagesScreen({super.key, this.otherUserId});

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

  List<Map<String, dynamic>> _communityProfiles = [];
  List<Map<String, dynamic>> _communityGroups = [];
  List<Map<String, dynamic>> _groupMessages = [];
  bool _loadingProfiles = true;
  bool _loadingGroups = true;
  bool _loadingGroupMessages = false;

  RealtimeChannel? _groupRealtimeChannel;

  // Local messages merged with realtime stream
  final List<DirectMessage> _localMessages = [];

  @override
  void initState() {
    super.initState();
    _loadCommunityProfiles();
    _loadCommunityGroups();
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

  Future<void> _loadCommunityProfiles() async {
    final client = ref.read(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;

    try {
      final res = await client
          .from('profiles')
          .select('id, full_name, avatar_url, city, role, bio')
          .neq('id', currentUserId ?? '')
          .limit(30);

      final list = (res as List<dynamic>).cast<Map<String, dynamic>>();

      if (mounted) {
        setState(() {
          _communityProfiles = list;
          _loadingProfiles = false;
        });

        if (widget.otherUserId != null) {
          final match = list.firstWhere(
            (p) => p['id'] == widget.otherUserId,
            orElse: () => {
              'id': widget.otherUserId,
              'full_name': 'Community Member',
              'avatar_url': null,
              'city': 'Kerala',
            },
          );
          _selectContact(match);
        }
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

  void _selectContact(Map<String, dynamic> contact) {
    HapticFeedback.lightImpact();
    setState(() {
      _activeContact = contact;
      _activeGroup = null;
      _localMessages.clear();
    });
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
    HapticFeedback.lightImpact();
    _groupRealtimeChannel?.unsubscribe();
    if (widget.otherUserId != null && _activeContact != null) {
      GoRouter.of(context).pop();
    } else {
      setState(() {
        _activeContact = null;
        _activeGroup = null;
        _localMessages.clear();
        _groupMessages.clear();
      });
    }
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

      final currentProfile = ref.read(currentUserProfileProvider).valueOrNull;
      final enriched = {
        ...res,
        'sender': {
          'id': currentUserId,
          'full_name': currentProfile?.fullName ?? 'You',
          'avatar_url': currentProfile?.avatarUrl,
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
          SnackBar(content: Text('Failed to post message: $e')),
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
    final cityCtrl = TextEditingController(text: 'Kerala');
    String selectedCategory = _groupCategories.first;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final scheme = Theme.of(context).colorScheme;
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.group_add_rounded, color: scheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Create Community Group',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      hintText: 'e.g. 🐶 Kochi Golden Retrievers Club',
                      prefixIcon: Icon(Icons.groups_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description & Rules',
                      hintText: 'e.g. Playdates, grooming tips, and local pet meetups...',
                      prefixIcon: Icon(Icons.description_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: _groupCategories.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setSheetState(() => selectedCategory = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: cityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Location / City',
                            hintText: 'e.g. Kochi',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Create & Launch Group', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final desc = descCtrl.text.trim();
                        final city = cityCtrl.text.trim();

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Group "$name" created successfully!')),
                          );
                          _selectGroup(newGroup);
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
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

    if (_activeContact != null) {
      return _buildOneOnOneChatScreen(context, scheme, currentUserId);
    }

    if (_activeGroup != null) {
      return _buildGroupChatScreen(context, scheme, currentUserId);
    }

    return _buildInboxScreen(context, scheme);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // VIEW 1: MESSENGER INBOX (DIRECT MESSAGES + COMMUNITY GROUPS)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildInboxScreen(BuildContext context, ColorScheme scheme) {
    final filteredProfiles = _communityProfiles.where((p) {
      final name = (p['full_name'] as String? ?? '').toLowerCase();
      final city = (p['city'] as String? ?? '').toLowerCase();
      final role = (p['role'] as String? ?? '').toLowerCase();

      final matchesQuery = _searchQuery.isEmpty ||
          name.contains(_searchQuery) ||
          city.contains(_searchQuery);

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
          if (_selectedMessengerTab == 1)
            IconButton(
              icon: const Icon(Icons.group_add_rounded),
              tooltip: 'New Group',
              onPressed: _openCreateGroupDialog,
            )
          else
            IconButton(
              icon: const Icon(Icons.person_search_rounded),
              tooltip: 'Find Contacts',
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
        ],
      ),
      floatingActionButton: _selectedMessengerTab == 1
          ? FloatingActionButton.extended(
              onPressed: _openCreateGroupDialog,
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('New Group', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _selectedMessengerTab == 0
                    ? 'Search people & conversations...'
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
                fillColor: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          // Primary Tab Switcher (Direct vs Groups)
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
                              'Direct Chats (${_communityProfiles.length})',
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
                ? _buildDirectChatsList(filteredProfiles, scheme)
                : _buildGroupsList(filteredGroups, scheme),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectChatsList(
    List<Map<String, dynamic>> filteredProfiles,
    ColorScheme scheme,
  ) {
    if (_loadingProfiles) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredProfiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No conversations found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try searching for another name or location',
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredProfiles.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (ctx, i) {
        final profile = filteredProfiles[i];
        final name = (profile['full_name'] as String?) ?? 'Community Member';
        final avatarUrl = profile['avatar_url'] as String?;
        final city = (profile['city'] as String?) ?? 'Kerala';
        final role = (profile['role'] as String?) ?? 'Pet Parent';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: () => _selectContact(profile),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primary.withValues(alpha: 0.15),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                ),
              ),
            ],
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
              const Text(
                'Active',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '📍 $city',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        );
      },
    );
  }

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
            const Text(
              'No community groups yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Create a new group to connect pet parents together!',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create First Group'),
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
        final name = (group['name'] as String?) ?? 'Community Group';
        final category = (group['category'] as String?) ?? 'General';
        final city = (group['city'] as String?) ?? 'Kerala';
        final description = (group['description'] as String?) ?? 'Public PetConnect group';

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          onTap: () => _selectGroup(group),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary,
                  scheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.groups_rounded, color: Colors.white, size: 28),
            ),
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
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                '📍 $city • Open Community Chat',
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.primary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // VIEW 2: 1-ON-1 DIRECT CHAT SCREEN
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildOneOnOneChatScreen(
    BuildContext context,
    ColorScheme scheme,
    String currentUserId,
  ) {
    final otherUserId = _activeContact!['id'] as String;
    final otherName = (_activeContact!['full_name'] as String?) ?? 'Community Contact';
    final otherAvatar = _activeContact!['avatar_url'] as String?;
    final otherCity = (_activeContact!['city'] as String?) ?? 'Kerala';

    ref.listen<AsyncValue<DirectMessage>>(
      liveDirectMessagesStreamProvider(otherUserId),
      (previous, next) {
        next.whenData((incoming) {
          setState(() {
            if (!_localMessages.any((m) => m.id == incoming.id)) {
              _localMessages.add(incoming);
            }
          });
          _scrollToBottom();
        });
      },
    );

    final initialMessagesAsync = ref.watch(directMessagesProvider(otherUserId));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Messages',
          onPressed: _backToInbox,
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primary.withValues(alpha: 0.15),
                  backgroundImage: otherAvatar != null && otherAvatar.isNotEmpty
                      ? NetworkImage(otherAvatar)
                      : null,
                  child: otherAvatar == null || otherAvatar.isEmpty
                      ? Text(
                          otherName.isNotEmpty ? otherName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 1.5),
                    ),
                  ),
                ),
              ],
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    '📍 $otherCity • Active now',
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
      ),
      body: Column(
        children: [
          Expanded(
            child: initialMessagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading messages: $err', style: TextStyle(color: scheme.error)),
                ),
              ),
              data: (loaded) {
                final displayMap = <String, DirectMessage>{};
                for (final m in loaded) {
                  displayMap[m.id] = m;
                }
                for (final m in _localMessages) {
                  displayMap[m.id] = m;
                }
                final displayMessages = displayMap.values.toList()
                  ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

                if (displayMessages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: scheme.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.waving_hand_rounded, size: 32, color: scheme.primary),
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
                                  const Icon(
                                    Icons.done_all_rounded,
                                    size: 13,
                                    color: Colors.white,
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
  // VIEW 3: COMMUNITY GROUP CHAT SCREEN
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildGroupChatScreen(
    BuildContext context,
    ColorScheme scheme,
    String currentUserId,
  ) {
    final groupName = (_activeGroup!['name'] as String?) ?? 'Community Group';
    final category = (_activeGroup!['category'] as String?) ?? 'General';
    final city = (_activeGroup!['city'] as String?) ?? 'Kerala';
    final description = (_activeGroup!['description'] as String?) ?? '';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Groups',
          onPressed: _backToInbox,
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.tertiary],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.groups_rounded, color: Colors.white, size: 20),
              ),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    '📍 $city • $category Group',
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
            tooltip: 'Group Information',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(groupName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Category: $category • 📍 $city', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        const Text('Group Description & Guidelines:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(description.isNotEmpty ? description : 'Open community group for pet parents.', style: TextStyle(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('Share Group Invite Link'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Group invite link copied to clipboard!')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Group Messages List
          Expanded(
            child: _loadingGroupMessages
                ? const Center(child: CircularProgressIndicator())
                : _groupMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.forum_outlined, size: 36, color: scheme.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Welcome to $groupName!',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to say hello and start the conversation!',
                              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
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
                          final isUser = msg['sender_id'] == currentUserId;
                          final sender = msg['sender'] as Map<String, dynamic>?;
                          final senderName = (sender?['full_name'] as String?) ?? 'Member';
                          final senderAvatar = sender?['avatar_url'] as String?;
                          final createdAt = DateTime.tryParse(msg['created_at']?.toString() ?? '') ?? DateTime.now();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment:
                                  isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isUser) ...[
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: scheme.primaryContainer,
                                    backgroundImage: senderAvatar != null && senderAvatar.isNotEmpty
                                        ? NetworkImage(senderAvatar)
                                        : null,
                                    child: senderAvatar == null || senderAvatar.isEmpty
                                        ? Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : 'M',
                                            style: TextStyle(fontSize: 10, color: scheme.primary, fontWeight: FontWeight.bold))
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.72,
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
                                      if (!isUser) ...[
                                        Text(
                                          senderName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: scheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                      Text(
                                        msg['message_text']?.toString() ?? '',
                                        style: TextStyle(
                                          color: isUser ? Colors.white : scheme.onSurface,
                                          fontSize: 14.5,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _formatTimestamp(createdAt),
                                        style: TextStyle(
                                          fontSize: 10,
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

          // Group Input Composer
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
