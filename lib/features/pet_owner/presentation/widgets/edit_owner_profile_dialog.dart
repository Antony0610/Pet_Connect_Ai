import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/storage/presentation/providers/storage_providers.dart';
import 'package:petconnect_ai/shared/widgets/avatar/user_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modern, comprehensive modal bottom sheet for editing Pet Owner profiles.
///
/// Supports:
/// - Avatar upload & avatar preset gallery selection
/// - Full Name, Phone, City, and Bio
/// - Quick city chips for 1-tap geo-tagging
/// - Multi-layer persistence (local cache + Supabase auth metadata + profiles table)
class EditOwnerProfileDialog extends ConsumerStatefulWidget {
  const EditOwnerProfileDialog({super.key, required this.profile});

  final UserProfile profile;

  static Future<void> show(BuildContext context, {required UserProfile profile}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditOwnerProfileDialog(profile: profile),
    );
  }

  @override
  ConsumerState<EditOwnerProfileDialog> createState() => _EditOwnerProfileDialogState();
}

class _EditOwnerProfileDialogState extends ConsumerState<EditOwnerProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  late final TextEditingController _bioController;

  late String? _selectedAvatarUrl;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _error;

  static const List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
  ];

  static const List<String> _quickCities = [
    'Annamanada',
    'Meladoor',
    'Kochi',
    'Thrissur',
    'Bengaluru',
    'Mumbai',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phone ?? '');
    _cityController = TextEditingController(text: widget.profile.city ?? '');
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _selectedAvatarUrl = widget.profile.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  (double, double) _resolveCoordinatesForCity(String city) {
    final lower = city.toLowerCase().trim();
    if (lower.contains('annamanada')) {
      return (10.2312, 76.2829);
    } else if (lower.contains('meladoor')) {
      return (10.2740, 76.3216);
    } else if (lower.contains('mala')) {
      return (10.2456, 76.2978);
    } else if (lower.contains('chalakudy')) {
      return (10.3070, 76.3330);
    } else if (lower.contains('aluva')) {
      return (10.1076, 76.3516);
    } else if (lower.contains('angamaly')) {
      return (10.1960, 76.3860);
    } else if (lower.contains('thrissur') || lower.contains('trichur')) {
      return (10.5276, 76.2144);
    } else if (lower.contains('kochi') || lower.contains('cochin') || lower.contains('ernakulam')) {
      return (9.9312, 76.2673);
    } else if (lower.contains('trivandrum') || lower.contains('thiruvananthapuram')) {
      return (8.5241, 76.9366);
    } else if (lower.contains('kozhikode') || lower.contains('calicut')) {
      return (11.2588, 75.7804);
    } else if (lower.contains('bengaluru') || lower.contains('bangalore')) {
      return (12.9716, 77.5946);
    } else if (lower.contains('mumbai')) {
      return (19.0760, 72.8777);
    } else if (lower.contains('delhi')) {
      return (28.6139, 77.2090);
    } else if (lower.contains('chennai')) {
      return (13.0827, 80.2707);
    }
    return (widget.profile.latitude ?? 10.2312, widget.profile.longitude ?? 76.2829);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final storageRepo = ref.read(storageRepositoryProvider);
      final userId = widget.profile.id;

      final uploadResult = await storageRepo.uploadUserAvatar(
        userId: userId,
        bytes: bytes,
        fileName: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        mimeType: 'image/jpeg',
      );

      uploadResult.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Avatar upload failed: ${failure.message}')),
            );
          }
        },
        (newUrl) {
          setState(() => _selectedAvatarUrl = newUrl);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Avatar selection error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final city = _cityController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Full name cannot be empty.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final (lat, lng) = _resolveCoordinatesForCity(city);
    final userId = widget.profile.id;

    // 1. Immediate local cache persistence via SharedPreferences
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('user_profile_name_$userId', name);
    await prefs.setString('user_profile_phone_$userId', phone);
    await prefs.setString('user_profile_city_$userId', city);
    await prefs.setString('user_profile_bio_$userId', bio);
    if (_selectedAvatarUrl != null) {
      await prefs.setString('user_profile_avatar_$userId', _selectedAvatarUrl!);
    }

    // 2. Persist to Supabase Auth user metadata
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': name,
            'phone': phone,
            'city': city,
            'bio': bio,
            if (_selectedAvatarUrl != null) 'avatar_url': _selectedAvatarUrl,
            'latitude': lat,
            'longitude': lng,
          },
        ),
      );
    } catch (_) {
      // Continue even if auth metadata write meets transient network error
    }

    // 3. Upsert to Supabase profiles database table
    try {
      final upsert = ref.read(upsertUserProfileProvider);
      await upsert(
        widget.profile.copyWith(
          fullName: name,
          phone: phone.isNotEmpty ? phone : null,
          city: city.isNotEmpty ? city : null,
          bio: bio.isNotEmpty ? bio : null,
          avatarUrl: _selectedAvatarUrl,
          latitude: lat,
          longitude: lng,
        ),
      );
    } catch (_) {
      // Continue since local cache and auth metadata are already updated
    }

    // 4. Invalidate provider to re-read updated profile everywhere
    ref.invalidate(currentUserProfileProvider);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Profile updated successfully!'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            AppSpacing.vGapMd,

            // Header Title and Close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Guardian Profile',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: AppTypography.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your details appear on posters & vet bookings',
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cancel',
                ),
              ],
            ),
            AppSpacing.vGapLg,

            // Avatar Section
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [scheme.primary, scheme.secondary],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: scheme.surfaceContainerHighest,
                      child: _uploadingAvatar
                          ? const CircularProgressIndicator(strokeWidth: 2.5)
                          : UserAvatar(
                              imageUrl: _selectedAvatarUrl ?? '',
                              size: 92,
                            ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _uploadingAvatar ? null : _pickAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.surface, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.photo_camera,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.vGapSm,

            // Quick Preset Avatars
            Center(
              child: Text(
                'Choose an avatar or tap camera to upload',
                style: textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: Center(
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: _presetAvatars.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final url = _presetAvatars[index];
                    final isSelected = _selectedAvatarUrl == url;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatarUrl = url),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? scheme.primary : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(url),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            AppSpacing.vGapMd,

            // Full Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                hintText: 'e.g. Antony Thomson',
                prefixIcon: const Icon(Icons.person_rounded),
                errorText: _error,
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.brCard,
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.brCard,
                  borderSide: BorderSide(color: scheme.primary, width: 2),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            AppSpacing.vGapMd,

            // Emergency Contact Phone
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Emergency Contact Phone',
                hintText: 'e.g. +91 98765 43210',
                helperText: 'Displayed on missing posters and clinic records',
                prefixIcon: const Icon(Icons.phone_rounded),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.brCard,
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.brCard,
                  borderSide: BorderSide(color: scheme.primary, width: 2),
                ),
              ),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            AppSpacing.vGapMd,

            // Home City / Location
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: 'Home City / Location',
                hintText: 'e.g. Annamanada, Thrissur',
                helperText: 'Used to center neighborhood SOS alerts & lost pet radar',
                prefixIcon: const Icon(Icons.location_on_rounded),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.brCard,
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.brCard,
                  borderSide: BorderSide(color: scheme.primary, width: 2),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),

            // Quick City Chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickCities.map((c) {
                final isCurrent = _cityController.text.toLowerCase().trim() == c.toLowerCase().trim();
                return ChoiceChip(
                  label: Text(c, style: const TextStyle(fontSize: 12)),
                  selected: isCurrent,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _cityController.text = c;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            AppSpacing.vGapMd,

            // Bio
            TextField(
              controller: _bioController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'About / Guardian Bio',
                hintText: 'Tell the pet community about your pets and family...',
                prefixIcon: const Icon(Icons.notes_rounded),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.brCard,
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.brCard,
                  borderSide: BorderSide(color: scheme.primary, width: 2),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            AppSpacing.vGapLg,

            // Save Changes Button
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text(_saving ? 'Saving...' : 'Save Changes'),
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.brCard,
                ),
                textStyle: textTheme.titleSmall?.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ),
            AppSpacing.vGapSm,
          ],
        ),
      ),
    );
  }
}
