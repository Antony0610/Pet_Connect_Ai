import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/storage/presentation/providers/storage_providers.dart';
import 'package:petconnect_ai/features/veterinarian/data/models/vet_clinic_model.dart';
import 'package:petconnect_ai/features/veterinarian/domain/entities/vet_clinic.dart';
import 'package:petconnect_ai/features/veterinarian/presentation/providers/vet_providers.dart';
import 'package:petconnect_ai/shared/widgets/avatar/user_avatar.dart';
import 'package:petconnect_ai/shared/widgets/buttons/app_button.dart';

/// Modal dialog for editing full Veterinarian practitioner & clinic details with DP upload.
class EditVetProfileDialog extends ConsumerStatefulWidget {
  const EditVetProfileDialog({
    required this.profile,
    this.initialClinic,
    super.key,
  });

  final UserProfile profile;
  final VetClinic? initialClinic;

  static Future<bool?> show(
    BuildContext context, {
    required UserProfile profile,
    VetClinic? initialClinic,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: EditVetProfileDialog(
          profile: profile,
          initialClinic: initialClinic,
        ),
      ),
    );
  }

  @override
  ConsumerState<EditVetProfileDialog> createState() => _EditVetProfileDialogState();
}

class _EditVetProfileDialogState extends ConsumerState<EditVetProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _bioController;
  late TextEditingController _clinicNameController;
  late TextEditingController _licenseController;
  late TextEditingController _consultationFeeController;

  String? _avatarUrl;
  bool _isUploadingDp = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    final c = widget.initialClinic;

    _avatarUrl = p.avatarUrl;
    _nameController = TextEditingController(text: p.fullName);
    _phoneController = TextEditingController(text: p.phone ?? '');
    _cityController = TextEditingController(text: p.city ?? c?.address ?? '');
    _bioController = TextEditingController(text: p.bio ?? '');
    _clinicNameController = TextEditingController(
      text: c?.name ?? '${p.fullName.isNotEmpty ? p.fullName : "Veterinary"} Practice',
    );
    _licenseController = TextEditingController(
      text: c?.licenseNumber ?? 'VET-${p.id.length >= 6 ? p.id.substring(0, 6).toUpperCase() : "REG-01"}',
    );
    _consultationFeeController = TextEditingController(text: '500');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    _clinicNameController.dispose();
    _licenseController.dispose();
    _consultationFeeController.dispose();
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

      // Persist clinic if modified or creating
      final clinicRepo = ref.read(vetRepositoryProvider);
      if (widget.initialClinic != null) {
        // Updated existing clinic details
        final clinic = widget.initialClinic!;
        final updatedClinic = VetClinicModel(
          id: clinic.id,
          name: _clinicNameController.text.trim(),
          address: _cityController.text.trim(),
          phone: _phoneController.text.trim(),
          email: clinic.email,
          licenseNumber: _licenseController.text.trim(),
          ownerId: widget.profile.id,
          createdAt: clinic.createdAt,
          updatedAt: DateTime.now(),
        );
        await clinicRepo.createVetClinic(updatedClinic);
      } else if (_clinicNameController.text.trim().isNotEmpty) {
        final newClinic = VetClinicModel(
          id: '',
          name: _clinicNameController.text.trim(),
          address: _cityController.text.trim(),
          phone: _phoneController.text.trim(),
          email: widget.profile.email,
          licenseNumber: _licenseController.text.trim(),
          ownerId: widget.profile.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await clinicRepo.createVetClinic(newClinic);
      }

      // Refresh providers across the app
      ref.invalidate(currentUserProfileProvider);
      ref.invalidate(vetClinicsProvider);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor profile updated successfully!')),
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
            title: const Text('Edit Practitioner Profile'),
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

                  // ── Practitioner Identity Fields ───────────────────────
                  _buildSectionHeader(theme, 'Practitioner Details', Icons.badge_outlined),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Doctor Full Name *',
                      hintText: 'e.g. Dr. Sarah Jenkins',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter doctor name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone Number',
                      hintText: '+91 98450 12345',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Clinic City / Location',
                      hintText: 'e.g. Indiranagar, Bengaluru',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Bio & Clinical Specializations',
                      hintText: 'e.g. 10+ yrs in Small Animal Surgery & Internal Medicine',
                      prefixIcon: Icon(Icons.info_outline),
                      border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                    ),
                  ),
                  const Divider(height: 32),

                  // ── Clinic Practice Fields ─────────────────────────────
                  _buildSectionHeader(theme, 'Clinic & Medical Board Information', Icons.local_hospital_outlined),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clinicNameController,
                    decoration: const InputDecoration(
                      labelText: 'Clinic / Hospital Name',
                      hintText: 'e.g. Apex Veterinary Clinic',
                      prefixIcon: Icon(Icons.storefront_outlined),
                      border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _licenseController,
                    decoration: const InputDecoration(
                      labelText: 'Medical Board License Number',
                      hintText: 'e.g. VET-KA-2024-8841',
                      prefixIcon: Icon(Icons.verified_outlined),
                      border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _consultationFeeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Standard Consultation Fee (₹ INR)',
                      hintText: 'e.g. 500',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                      border: OutlineInputBorder(borderRadius: AppRadius.brCard),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Save Button ────────────────────────────────────────
                  AppButton(
                    text: _isSaving ? 'Saving Changes...' : 'Save Practitioner Profile',
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
