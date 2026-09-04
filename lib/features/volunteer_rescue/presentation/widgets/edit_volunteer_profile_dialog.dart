import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/storage/presentation/providers/storage_providers.dart';
import 'package:petconnect_ai/features/volunteer_rescue/presentation/providers/rescue_providers.dart';
import 'package:petconnect_ai/shared/widgets/avatar/user_avatar.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';

/// Modal dialog for editing full Volunteer responder details with DP upload.
class EditVolunteerProfileDialog extends ConsumerStatefulWidget {
  const EditVolunteerProfileDialog({
    required this.profile,
    super.key,
  });

  final UserProfile profile;

  static Future<bool?> show(
    BuildContext context, {
    required UserProfile profile,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: EditVolunteerProfileDialog(profile: profile),
      ),
    );
  }

  @override
  ConsumerState<EditVolunteerProfileDialog> createState() =>
      _EditVolunteerProfileDialogState();
}

class _EditVolunteerProfileDialogState
    extends ConsumerState<EditVolunteerProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _bioController;
  late TextEditingController _orgController;
  late TextEditingController _sectorController;
  late TextEditingController _equipmentController;
  late TextEditingController _vehicleController;

  String? _avatarUrl;
  bool _isUploadingDp = false;
  bool _isSaving = false;
  bool _isOnDuty = true;

  final List<String> _availableSkills = [
    'Animal First Aid',
    'Search & Rescue',
    'Wildlife Handling',
    'Water Rescue',
    'Trauma Care',
    'Emergency Transport',
    'K9 Handling',
  ];

  late Set<String> _selectedSkills;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    final prefs = ref.read(sharedPreferencesProvider);

    _avatarUrl = p.avatarUrl;
    _nameController = TextEditingController(text: p.fullName);
    _phoneController = TextEditingController(text: p.phone ?? '');
    _cityController = TextEditingController(text: p.city ?? '');
    _bioController = TextEditingController(text: p.bio ?? '');
    _orgController = TextEditingController(
      text: prefs.getString('volunteer_org') ?? 'PetConnect Rapid Animal Rescue Corps',
    );
    _sectorController = TextEditingController(
      text: prefs.getString('volunteer_sector') ?? 'Central Command • Rapid Dispatch',
    );
    _equipmentController = TextEditingController(
      text: prefs.getString('volunteer_equipment') ?? 'Pet First Aid Kit, Animal Carrier, Microchip Scanner, Safety Gloves, Slip Leash',
    );
    _vehicleController = TextEditingController(
      text: prefs.getString('volunteer_vehicle') ?? 'SUV with Pet Crate & Partition',
    );
    final savedSkills = prefs.getStringList('volunteer_skills');
    _selectedSkills = savedSkills != null && savedSkills.isNotEmpty
        ? savedSkills.toSet()
        : {'Animal First Aid', 'Search & Rescue', 'Emergency Transport'};
    _isOnDuty = ref.read(volunteerDutyStatusProvider);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _orgController.dispose();
    _sectorController.dispose();
    _equipmentController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadDp(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 600,
    );
    if (picked == null) return;

    setState(() => _isUploadingDp = true);
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
          setState(() => _avatarUrl = newUrl);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Display Picture uploaded successfully!')),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading DP: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingDp = false);
    }
  }

  void _showDpSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take Photo with Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadDp(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadDp(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updatedProfile = widget.profile.copyWith(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        bio: _bioController.text.trim(),
        avatarUrl: _avatarUrl,
      );

      // Persist profile to Supabase
      final upsertProfile = ref.read(upsertUserProfileProvider);
      await upsertProfile(updatedProfile);

      // Persist preferences locally
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('volunteer_org', _orgController.text.trim());
      await prefs.setString('volunteer_sector', _sectorController.text.trim());
      await prefs.setString('volunteer_equipment', _equipmentController.text.trim());
      await prefs.setString('volunteer_vehicle', _vehicleController.text.trim());
      await prefs.setStringList('volunteer_skills', _selectedSkills.toList());

      // Update duty status provider
      ref.read(volunteerDutyStatusProvider.notifier).state = _isOnDuty;

      // Refresh providers
      ref.invalidate(currentUserProfileProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Volunteer profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context, false),
            ),
            title: const Text('Edit Responder Profile'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── DP Avatar with Camera Badge ────────────────────────
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              width: 3,
                            ),
                          ),
                          child: _isUploadingDp
                              ? const SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: Center(
                                    child: CircularProgressIndicator(strokeWidth: 3),
                                  ),
                                )
                              : UserAvatar(
                                  imageUrl: _avatarUrl ?? '',
                                  size: 90,
                                ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Material(
                            color: colorScheme.primary,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              onTap: _isUploadingDp ? null : _showDpSourceSheet,
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 20,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isUploadingDp ? null : _showDpSourceSheet,
                    icon: const Icon(Icons.upload_rounded, size: 16),
                    label: const Text('Change Display Picture'),
                  ),
                  const Divider(height: 32),

                  // ── Volunteer Identity Fields ──────────────────────────
                  _buildSectionHeader(theme, 'Volunteer Identity', Icons.badge_outlined),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'e.g. Alex Morgan',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Phone Number',
                      hintText: '+91 98765 43210',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Dispatch Base / City',
                      hintText: 'e.g. Koramangala, Bengaluru',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Bio & Field Experience',
                      hintText: 'e.g. 5+ years handling urban stray rescues and K9 emergency trauma',
                      prefixIcon: Icon(Icons.info_outline),
                      border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                    ),
                  ),
                  const Divider(height: 32),

                  // ── Operations & Affiliation Fields ────────────────────
                  _buildSectionHeader(theme, 'Operations & Affiliation', Icons.shield_outlined),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _orgController,
                    decoration: const InputDecoration(
                      labelText: 'Rescue Organization / NGO',
                      hintText: 'e.g. Animal Rescue Trust',
                      prefixIcon: Icon(Icons.business_outlined),
                      border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _sectorController,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Dispatch Sector',
                      hintText: 'e.g. Sector 4 • Central Command',
                      prefixIcon: Icon(Icons.map_outlined),
                      border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _vehicleController,
                    decoration: const InputDecoration(
                      labelText: 'Response Vehicle / Transport',
                      hintText: 'e.g. SUV with Pet Crate & Partition',
                      prefixIcon: Icon(Icons.directions_car_outlined),
                      border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _equipmentController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Equipment Checklist',
                      hintText: 'e.g. Pet First Aid Kit, Animal Carrier, Microchip Scanner, Safety Gloves, Slip Leash',
                      prefixIcon: Icon(Icons.medical_services_outlined),
                      border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── On-Duty Toggle ────────────────────────────────────
                  SwitchListTile(
                    title: const Text('Active Duty Status'),
                    subtitle: Text(
                      _isOnDuty
                          ? 'Broadcasting live responder beacon for emergency dispatch'
                          : 'Off duty • Standby mode',
                    ),
                    value: _isOnDuty,
                    activeThumbColor: colorScheme.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _isOnDuty = val),
                  ),
                  const Divider(height: 32),

                  // ── Specialization Skills Chips ────────────────────────
                  _buildSectionHeader(theme, 'Specialization Skills & Training', Icons.star_outline),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSkills.map((skill) {
                      final isSelected = _selectedSkills.contains(skill);
                      return FilterChip(
                        label: Text(skill),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSkills.add(skill);
                            } else {
                              _selectedSkills.remove(skill);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // ── Save Button ────────────────────────────────────────
                  AppButton(
                    text: _isSaving ? 'Saving Changes...' : 'Save Responder Profile',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _saveProfile,
                    backgroundColor: colorScheme.primary,
                    textColor: colorScheme.onPrimary,
                    isFullWidth: true,
                    height: 52,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
      ],
    );
  }
}
