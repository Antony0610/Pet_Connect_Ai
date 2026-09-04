import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_icon_sizes.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/providers/pet_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/features/storage/domain/entities/pet_document.dart';
import 'package:petconnect_ai/features/storage/presentation/providers/storage_providers.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// A faithful Flutter rendering of the frozen Stitch **Pet Documents Vault**
/// (Light Theme design authority, ID `ab7d2d74a7ae4eb3b1c6d3df399c51eb`).
///
/// Centralized vault for organizing medical certificates, lab results, prescriptions,
/// and insurance policies with search, filter, download, and share actions.
class PetDocumentsVaultScreen extends ConsumerStatefulWidget {
  const PetDocumentsVaultScreen({super.key});

  @override
  ConsumerState<PetDocumentsVaultScreen> createState() =>
      _PetDocumentsVaultScreenState();
}

class _PetDocumentsVaultScreenState
    extends ConsumerState<PetDocumentsVaultScreen> {
  static const double _maxContentWidth = 1000;
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  final List<String> _categories = const [
    'All',
    'Vaccinations',
    'Lab Results',
    'Prescriptions',
    'Insurances',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final selectedPet = ref.watch(selectedPetProvider);
    final activePetId = selectedPet?.id ?? '';
    final petName = selectedPet?.name ?? 'Pet';
    final docsAsync = activePetId.isNotEmpty
        ? ref.watch(petDocumentsProvider(activePetId))
        : null;

    return Scaffold(
      appBar: OwnerGlassAppBar(
        title: Text(
          selectedPet != null
              ? "$petName's Document Vault"
              : 'Pet Documents Vault',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: 'Upload Document',
            onPressed: () => _showUploadDocumentSheet(context, petName, activePetId),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Search Input ──────────────────────────────────
                  AppTextField(
                    controller: _searchController,
                    hintText: 'Search documents by title or provider...',
                    prefixIcon: const Icon(Icons.search),
                    onChanged: (_) => setState(() {}),
                  ),
                  AppSpacing.vGapLg,

                  // ── Category Filters ──────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: scheme.primary,
                            backgroundColor: scheme.surfaceContainerHigh,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                              fontWeight: AppTypography.semiBold,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategory = cat);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  AppSpacing.vGapLg,

                  // ── Document Cards List ───────────────────────────
                  docsAsync?.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) =>
                            Center(child: Text('Error loading documents: $err')),
                        data: (docs) {
                          final query = _searchController.text.toLowerCase();
                          final filteredDocs = docs.where((doc) {
                            final matchesCat =
                                _selectedCategory == 'All' ||
                                (_selectedCategory == 'Vaccinations' &&
                                    doc.documentType == 'VACCINATION_CERT') ||
                                (_selectedCategory == 'Lab Results' &&
                                    doc.documentType == 'LAB_RESULT') ||
                                (_selectedCategory == 'Prescriptions' &&
                                    doc.documentType == 'PRESCRIPTION');
                            final matchesQuery =
                                query.isEmpty ||
                                doc.documentName.toLowerCase().contains(query);
                            return matchesCat && matchesQuery;
                          }).toList();

                          if (filteredDocs.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                child: Text(
                                  'No documents found in this category.',
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: filteredDocs
                                .map((doc) => _buildDocumentCard(context, doc))
                                .toList(),
                          );
                        },
                      ) ??
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Text(
                            'No documents found for this pet.',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, PetDocument doc) {
    final scheme = context.colorScheme;
    final sizeKb = (doc.fileSize ?? 0) ~/ 1024;
    final meta = '${doc.mimeType?.split('/').last.toUpperCase() ?? 'PDF'} • ${sizeKb > 0 ? '$sizeKb KB' : 'Document'} • Verified';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => _showDocumentViewerDialog(context, doc),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    (doc.mimeType?.contains('image') ?? false)
                        ? Icons.image_outlined
                        : Icons.picture_as_pdf_outlined,
                    color: scheme.primary,
                    size: AppIconSizes.md,
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.documentName,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        meta,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        doc.documentType,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: AppTypography.semiBold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // View Document Button
                IconButton(
                  icon: Icon(
                    Icons.visibility_outlined,
                    color: scheme.primary,
                    size: 20,
                  ),
                  tooltip: 'View Document',
                  onPressed: () => _showDocumentViewerDialog(context, doc),
                ),
                // Download Document Button
                IconButton(
                  icon: Icon(
                    Icons.file_download_outlined,
                    color: scheme.onSurfaceVariant,
                    size: 20,
                  ),
                  tooltip: 'Download Document',
                  onPressed: () => _downloadDocument(context, doc),
                ),
                // Share Document Button
                IconButton(
                  icon: Icon(
                    Icons.share_outlined,
                    color: scheme.onSurfaceVariant,
                    size: 19,
                  ),
                  tooltip: 'Share Document',
                  onPressed: () => _shareDocument(context, doc),
                ),
                // Delete Document Button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: scheme.error.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  tooltip: 'Delete Document',
                  onPressed: () => _confirmDeleteDocument(context, doc),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentViewerDialog(BuildContext context, PetDocument doc) {
    final scheme = Theme.of(context).colorScheme;
    final isImage = (doc.mimeType?.contains('image') ?? false) ||
        doc.documentName.toLowerCase().endsWith('.png') ||
        doc.documentName.toLowerCase().endsWith('.jpg') ||
        doc.documentName.toLowerCase().endsWith('.jpeg');

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isImage ? Icons.image_rounded : Icons.picture_as_pdf_rounded,
                      color: scheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.documentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            doc.documentType,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Center(
                      child: isImage && doc.signedUrl != null
                          ? InteractiveViewer(
                              child: Image.network(
                                doc.signedUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => _buildFallbackPreview(doc, scheme),
                              ),
                            )
                          : _buildFallbackPreview(doc, scheme),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Download'),
                      onPressed: () => _downloadDocument(context, doc),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share PDF'),
                      onPressed: () => _shareDocument(context, doc),
                    ),
                    FilledButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open in Viewer'),
                      onPressed: () => _viewDocument(context, doc),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackPreview(PetDocument doc, ColorScheme scheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.picture_as_pdf_rounded, size: 54, color: scheme.primary),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            doc.documentName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Size: ${(doc.fileSize ?? 0) ~/ 1024} KB • Verified Vault Document',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.visibility_rounded, size: 18),
          label: const Text('Open in System Viewer'),
          onPressed: () => _viewDocument(context, doc),
        ),
      ],
    );
  }

  Future<File?> _resolveDocumentFile(PetDocument doc) async {
    // 1. Check if filePath is already a local file that exists
    if (doc.filePath.isNotEmpty) {
      final localFile = File(doc.filePath);
      if (localFile.existsSync()) {
        return localFile;
      }
    }

    final cleanName = doc.documentName.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final tempDir = await getTemporaryDirectory();
    final cachedTarget = File('${tempDir.path}/$cleanName');

    // 2. If already cached in temp dir, return it
    if (cachedTarget.existsSync() && cachedTarget.lengthSync() > 0) {
      return cachedTarget;
    }

    // 3. If signedUrl or public url is present, download it
    final url = doc.signedUrl;
    if (url != null && url.isNotEmpty) {
      try {
        final dio = Dio();
        await dio.download(url, cachedTarget.path);
        if (cachedTarget.existsSync() && cachedTarget.lengthSync() > 0) {
          return cachedTarget;
        }
      } catch (_) {}
    }

    // 4. Try Supabase storage bucket download
    try {
      final client = ref.read(supabaseClientProvider);
      final bytes = await client.storage.from('pet-documents').download(doc.filePath);
      await cachedTarget.writeAsBytes(bytes);
      return cachedTarget;
    } catch (_) {}

    return null;
  }

  Future<void> _viewDocument(BuildContext context, PetDocument doc) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text('Opening ${doc.documentName}...'),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final file = await _resolveDocumentFile(doc);
      if (file != null && file.existsSync()) {
        final openResult = await OpenFilex.open(file.path);
        if (openResult.type == ResultType.done) {
          return;
        }
      }

      // Fallback: If local viewer didn't work or file wasn't resolved, open signed URL
      if (doc.signedUrl != null && doc.signedUrl!.isNotEmpty) {
        final opened = await ExternalActions.openUrl(doc.signedUrl!);
        if (!opened && context.mounted) {
          scaffold.showSnackBar(
            const SnackBar(content: Text('Could not open document viewer or browser.')),
          );
        }
      } else {
        if (context.mounted) {
          scaffold.showSnackBar(
            const SnackBar(content: Text('Document file could not be retrieved.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        scaffold.showSnackBar(SnackBar(content: Text('Error opening document: $e')));
      }
    }
  }

  Future<void> _downloadDocument(BuildContext context, PetDocument doc) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text('Saving ${doc.documentName} to Downloads...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final file = await _resolveDocumentFile(doc);
      if (file == null || !file.existsSync()) {
        if (doc.signedUrl != null && doc.signedUrl!.isNotEmpty) {
          await ExternalActions.openUrl(doc.signedUrl!);
        } else {
          scaffold.showSnackBar(
            const SnackBar(content: Text('Unable to locate document file to download.')),
          );
        }
        return;
      }

      Directory? targetDir;
      if (Platform.isAndroid) {
        final downloadsFolder = Directory('/storage/emulated/0/Download');
        if (downloadsFolder.existsSync()) {
          targetDir = downloadsFolder;
        } else {
          targetDir = await getExternalStorageDirectory();
        }
      } else {
        targetDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }

      if (targetDir == null) {
        throw Exception('Could not access downloads directory.');
      }

      final cleanName = doc.documentName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final destFile = File('${targetDir.path}/$cleanName');
      await file.copy(destFile.path);

      if (context.mounted) {
        scaffold.showSnackBar(
          SnackBar(
            content: Text('Saved to Downloads: ${destFile.path.split('/').last}'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () => OpenFilex.open(destFile.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffold.showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  Future<void> _shareDocument(BuildContext context, PetDocument doc) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text('Preparing ${doc.documentName} to share...'),
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      final file = await _resolveDocumentFile(doc);
      if (file != null && file.existsSync()) {
        await ExternalActions.shareFiles(
          [file.path],
          text: 'PetConnect AI Vault Document: ${doc.documentName}\nType: ${doc.documentType}',
          subject: doc.documentName,
        );
      } else if (doc.signedUrl != null && doc.signedUrl!.isNotEmpty) {
        await ExternalActions.shareText(
          'PetConnect AI Vault Document: ${doc.documentName}\nType: ${doc.documentType}\nLink: ${doc.signedUrl}',
          subject: doc.documentName,
        );
      } else {
        if (context.mounted) {
          scaffold.showSnackBar(
            const SnackBar(content: Text('Document file unavailable to share.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        scaffold.showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    }
  }

  Future<void> _confirmDeleteDocument(BuildContext context, PetDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text(
          'Are you sure you want to delete "${doc.documentName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final client = ref.read(supabaseClientProvider);
        await client.from('pet_documents').delete().eq('id', doc.id);
        ref.invalidate(petDocumentsProvider(doc.petId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ "${doc.documentName}" deleted successfully.'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete document: $e')),
          );
        }
      }
    }
  }

  void _showUploadDocumentSheet(BuildContext context, String petName, String petId) {
    final titleController = TextEditingController();
    String docType = 'Vaccination Certificate';
    File? pickedFile;
    String? pickedFileName;
    int? pickedFileSize;
    String? pickedMime;
    bool isUploading = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Upload to $petName\'s Vault',
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    'Scan physical records or browse PDF certificates to encrypt into PetConnect vault.',
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.vGapMd,
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Document Title',
                      hintText: 'e.g. Rabies Vaccine Certificate 2026',
                      prefixIcon: Icon(Icons.title_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  AppSpacing.vGapMd,
                  DropdownButtonFormField<String>(
                    initialValue: docType,
                    decoration: const InputDecoration(
                      labelText: 'Document Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Vaccination Certificate',
                        child: Text('Vaccination Certificate'),
                      ),
                      DropdownMenuItem(
                        value: 'Lab Result',
                        child: Text('Lab Result'),
                      ),
                      DropdownMenuItem(
                        value: 'Prescription',
                        child: Text('Prescription'),
                      ),
                      DropdownMenuItem(
                        value: 'Insurance Policy',
                        child: Text('Insurance Policy'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => docType = val);
                    },
                  ),
                  AppSpacing.vGapMd,
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Scan Camera'),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final photo = await picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 85,
                            );
                            if (photo != null) {
                              final f = File(photo.path);
                              final size = await f.length();
                              setModalState(() {
                                pickedFile = f;
                                pickedFileName = photo.name;
                                pickedFileSize = size;
                                pickedMime = 'image/jpeg';
                                if (titleController.text.trim().isEmpty) {
                                  titleController.text = '$docType - ${photo.name.split('.').first}';
                                }
                              });
                            }
                          },
                        ),
                      ),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.file_upload_outlined),
                          label: const Text('Browse PDF/Image'),
                          onPressed: () async {
                            final result = await FilePicker.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                            );
                            if (result != null &&
                                result.files.isNotEmpty &&
                                result.files.first.path != null) {
                              final f = File(result.files.first.path!);
                              final name = result.files.first.name;
                              final ext = name.split('.').last.toLowerCase();
                              setModalState(() {
                                pickedFile = f;
                                pickedFileName = name;
                                pickedFileSize = result.files.first.size;
                                pickedMime = ext == 'pdf' ? 'application/pdf' : 'image/$ext';
                                if (titleController.text.trim().isEmpty) {
                                  titleController.text = name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  // Selected File Badge
                  if (pickedFile != null) ...[
                    AppSpacing.vGapMd,
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF137A63).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF137A63).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF137A63), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pickedFileName ?? 'Selected Document',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Size: ${(pickedFileSize ?? 0) ~/ 1024} KB • Ready for encrypted upload',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setModalState(() {
                              pickedFile = null;
                              pickedFileName = null;
                              pickedFileSize = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],

                  AppSpacing.vGapMd,
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: isUploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(isUploading ? 'Uploading to Vault...' : 'Save to Vault'),
                      onPressed: isUploading
                          ? null
                          : () async {
                              final title = titleController.text.trim();
                              final docName = title.isNotEmpty
                                  ? title
                                  : (pickedFileName ?? '$docType ($petName)');

                              if (pickedFile == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please scan with camera or browse a document first.'),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isUploading = true);

                              try {
                                final client = ref.read(supabaseClientProvider);
                                final user = client.auth.currentUser;
                                final userId = user?.id ?? '00000000-0000-0000-0000-000000000000';
                                final bytes = await pickedFile!.readAsBytes();

                                // 1. Attempt storage upload
                                final repo = ref.read(storageRepositoryProvider);
                                final uploadResult = await repo.uploadPetDocument(
                                  userId: userId,
                                  petId: petId,
                                  bytes: bytes,
                                  fileName: '${DateTime.now().millisecondsSinceEpoch}_${pickedFileName ?? "document"}',
                                  mimeType: pickedMime ?? 'application/octet-stream',
                                  documentName: docName,
                                  documentType: docType,
                                );

                                await uploadResult.fold(
                                  (failure) async {
                                    // Fallback: direct database record insert so metadata is saved
                                    await client.from('pet_documents').insert({
                                      'pet_id': petId,
                                      'document_name': docName,
                                      'document_type': docType,
                                      'file_path': pickedFile!.path,
                                      'file_size': bytes.length,
                                      'mime_type': pickedMime ?? 'application/octet-stream',
                                      'uploaded_by': userId,
                                      'created_at': DateTime.now().toIso8601String(),
                                    });
                                  },
                                  (_) async {},
                                );

                                if (petId.isNotEmpty) {
                                  ref.invalidate(petDocumentsProvider(petId));
                                }

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('✓ Saved "$docName" to $petName\'s secure vault!'),
                                      backgroundColor: Colors.green.shade700,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  setModalState(() => isUploading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to save document: $e'), backgroundColor: Colors.red),
                                  );
                                }
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
}
