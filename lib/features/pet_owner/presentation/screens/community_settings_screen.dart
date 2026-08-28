import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// Dedicated **Community Settings** screen (`/owner/community/settings`).
///
/// Controls Community feed privacy, nearby visibility, message permissions, and blocked users.
class CommunitySettingsScreen extends ConsumerStatefulWidget {
  const CommunitySettingsScreen({super.key});

  @override
  ConsumerState<CommunitySettingsScreen> createState() => _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends ConsumerState<CommunitySettingsScreen> {
  static const _kPublicProfile = 'comm_public_profile';
  static const _kShowLocation = 'comm_show_location';
  static const _kMessageRequests = 'comm_message_requests';
  static const _kNotifyLikesComments = 'comm_notify_likes_comments';
  static const _kNotifyLostFound = 'comm_notify_lost_found';
  static const _kNotifyAdoptions = 'comm_notify_adoptions';
  static const _kSafeContentFilter = 'comm_safe_filter';
  static const _kDiscoveryRadius = 'comm_discovery_radius_km';

  bool _publicProfile = true;
  bool _showLocation = true;
  String _messageRequests = 'Friends Only';
  bool _notifyLikesComments = true;
  bool _notifyLostFound = true;
  bool _notifyAdoptions = true;
  bool _safeContentFilter = true;
  double _discoveryRadius = 15.0;
  final List<String> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() {
      _publicProfile = prefs.getBool(_kPublicProfile) ?? true;
      _showLocation = prefs.getBool(_kShowLocation) ?? true;
      _messageRequests = prefs.getString(_kMessageRequests) ?? 'Friends Only';
      _notifyLikesComments = prefs.getBool(_kNotifyLikesComments) ?? true;
      _notifyLostFound = prefs.getBool(_kNotifyLostFound) ?? true;
      _notifyAdoptions = prefs.getBool(_kNotifyAdoptions) ?? true;
      _safeContentFilter = prefs.getBool(_kSafeContentFilter) ?? true;
      _discoveryRadius = prefs.getDouble(_kDiscoveryRadius) ?? 15.0;
    });
  }

  Future<void> _setPublicProfile(bool val) async {
    setState(() => _publicProfile = val);
    await ref.read(sharedPreferencesProvider).setBool(_kPublicProfile, val);
    if (mounted) context.showSnackbar(val ? 'Public profile enabled' : 'Profile set to private');
  }

  Future<void> _setShowLocation(bool val) async {
    setState(() => _showLocation = val);
    await ref.read(sharedPreferencesProvider).setBool(_kShowLocation, val);
    if (mounted) context.showSnackbar(val ? 'Nearby location enabled' : 'Nearby location hidden');
  }

  Future<void> _setMessageRequests(String val) async {
    setState(() => _messageRequests = val);
    await ref.read(sharedPreferencesProvider).setString(_kMessageRequests, val);
    if (mounted) context.showSnackbar('Message requests set to $val');
  }

  Future<void> _setNotifyLikes(bool val) async {
    setState(() => _notifyLikesComments = val);
    await ref.read(sharedPreferencesProvider).setBool(_kNotifyLikesComments, val);
    if (mounted) context.showSnackbar(val ? 'Likes & Comments notifications ON' : 'Likes & Comments notifications muted');
  }

  Future<void> _setNotifyLostFound(bool val) async {
    setState(() => _notifyLostFound = val);
    await ref.read(sharedPreferencesProvider).setBool(_kNotifyLostFound, val);
    if (mounted) context.showSnackbar(val ? 'Lost & Found neighborhood alerts ON' : 'Lost & Found alerts muted');
  }

  Future<void> _setNotifyAdoptions(bool val) async {
    setState(() => _notifyAdoptions = val);
    await ref.read(sharedPreferencesProvider).setBool(_kNotifyAdoptions, val);
    if (mounted) context.showSnackbar(val ? 'Adoption alerts ON' : 'Adoption alerts muted');
  }

  Future<void> _setSafeFilter(bool val) async {
    setState(() => _safeContentFilter = val);
    await ref.read(sharedPreferencesProvider).setBool(_kSafeContentFilter, val);
    if (mounted) context.showSnackbar(val ? 'AI Safe Content Filter active' : 'Safe Filter disabled');
  }

  Future<void> _setDiscoveryRadius(double val) async {
    setState(() => _discoveryRadius = val);
    await ref.read(sharedPreferencesProvider).setDouble(_kDiscoveryRadius, val);
  }

  void _showBlockedUsersDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Blocked Users'),
        content: _blockedUsers.isEmpty
            ? const Text('You have not blocked any users in the community.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: _blockedUsers
                    .map((u) => ListTile(
                          title: Text(u),
                          trailing: TextButton(
                            onPressed: () {
                              setState(() => _blockedUsers.remove(u));
                              Navigator.pop(ctx);
                            },
                            child: const Text('Unblock'),
                          ),
                        ))
                    .toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMessageRequestsSheet() {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Message Requests Permission',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ...['Everyone', 'Friends Only', 'Verified Pet Owners', 'Off'].map(
                (opt) => ListTile(
                  title: Text(opt, style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: _messageRequests == opt
                      ? Icon(Icons.check_circle_rounded, color: scheme.primary)
                      : null,
                  onTap: () {
                    _setMessageRequests(opt);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    final appBar = OwnerGlassAppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: () => GoRouter.of(context).pop(),
      ),
      title: Text(
        'Community Settings',
        style: text.titleLarge?.copyWith(
          color: scheme.primary,
          fontWeight: AppTypography.bold,
        ),
      ),
    );

    final topPad = context.viewPadding.top + appBar.preferredSize.height;
    final bottomPad = context.viewPadding.bottom + AppSpacing.xxl;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: appBar,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          topPad + AppSpacing.md,
          AppSpacing.marginMobile,
          bottomPad,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader('Community Notifications', scheme),
                AppSpacing.vGapSm,
                AppCard(
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: _buildIconBadge(Icons.favorite_rounded, scheme.primaryContainer, scheme.primary),
                        title: const Text('Post Likes & Comments', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Instant alerts when companions interact with your posts'),
                        value: _notifyLikesComments,
                        onChanged: _setNotifyLikes,
                      ),
                      Divider(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: _buildIconBadge(Icons.campaign_rounded, scheme.errorContainer, scheme.error),
                        title: const Text('Lost & Found Broadcasts', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Emergency alerts for missing pets reported in your neighborhood'),
                        value: _notifyLostFound,
                        onChanged: _setNotifyLostFound,
                      ),
                      Divider(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: _buildIconBadge(Icons.pets_rounded, scheme.secondaryContainer, scheme.secondary),
                        title: const Text('Pet Adoption Highlights', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('New adoption matches nearby looking for forever homes'),
                        value: _notifyAdoptions,
                        onChanged: _setNotifyAdoptions,
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,
                _buildSectionHeader('Discovery & Geolocation Radius', scheme),
                AppSpacing.vGapSm,
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildIconBadge(Icons.radar_rounded, scheme.tertiaryContainer, scheme.tertiary),
                              const SizedBox(width: 12),
                              const Text('Nearby Feed Radius', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_discoveryRadius.toInt()} km',
                              style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider.adaptive(
                        value: _discoveryRadius,
                        min: 5.0,
                        max: 100.0,
                        divisions: 19,
                        label: '${_discoveryRadius.toInt()} km',
                        onChanged: (val) => setState(() => _discoveryRadius = val),
                        onChangeEnd: _setDiscoveryRadius,
                      ),
                      Text(
                        'Filter local meetups, events, and posts within ${_discoveryRadius.toInt()} km of your current coordinates.',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,
                _buildSectionHeader('Privacy & Feed Visibility', scheme),
                AppSpacing.vGapSm,
                AppCard(
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: _buildIconBadge(Icons.public_rounded, scheme.primaryContainer, scheme.primary),
                        title: const Text('Public Profile in Community', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Allow nearby companions to view your shared pet moments'),
                        value: _publicProfile,
                        onChanged: _setPublicProfile,
                      ),
                      Divider(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: _buildIconBadge(Icons.near_me_rounded, scheme.primaryContainer, scheme.primary),
                        title: const Text('Show in Nearby Companions', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Display your approximate distance for local pet meetups'),
                        value: _showLocation,
                        onChanged: _setShowLocation,
                      ),
                      Divider(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        secondary: _buildIconBadge(Icons.shield_outlined, scheme.secondaryContainer, scheme.secondary),
                        title: const Text('AI Safe Content Moderation', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Automatically blur sensitive media and filter abusive remarks'),
                        value: _safeContentFilter,
                        onChanged: _setSafeFilter,
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,
                _buildSectionHeader('Interactions & Messaging', scheme),
                AppSpacing.vGapSm,
                AppCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _buildIconBadge(Icons.chat_bubble_outline_rounded, scheme.primaryContainer, scheme.primary),
                        title: const Text('Message Requests', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('Currently allowing: $_messageRequests'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _showMessageRequestsSheet,
                      ),
                      Divider(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: _buildIconBadge(Icons.block_rounded, scheme.errorContainer, scheme.error),
                        title: const Text('Blocked Community Members', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${_blockedUsers.length} users blocked'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _showBlockedUsersDialog,
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

  Widget _buildIconBadge(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.brSm,
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: scheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
