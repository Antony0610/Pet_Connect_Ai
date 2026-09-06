import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:petconnect_ai/core/config/env.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/core/utils/qr_generator_helper.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/domain/entities/pet.dart';
import 'package:share_plus/share_plus.dart';

/// Modal dialog for generating and exporting high-impact Lost Pet Posters.
/// Designed after the classic cream-and-crimson missing pet poster template.
class LostPetPosterDialog extends ConsumerStatefulWidget {
  const LostPetPosterDialog({
    required this.pet,
    this.initialLocation,
    this.initialReward,
    this.initialPhone,
    this.initialNotes,
    super.key,
  });

  final Pet pet;
  final String? initialLocation;
  final String? initialReward;
  final String? initialPhone;
  final String? initialNotes;

  static Future<void> show(
    BuildContext context, {
    required Pet pet,
    String? lastSeenLocation,
    String? rewardAmount,
    String? contactPhone,
    String? contactEmail,
    String? notes,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => LostPetPosterDialog(
        pet: pet,
        initialLocation: lastSeenLocation,
        initialReward: rewardAmount,
        initialPhone: contactPhone,
        initialNotes: notes,
      ),
    );
  }

  @override
  ConsumerState<LostPetPosterDialog> createState() => _LostPetPosterDialogState();
}

class _LostPetPosterDialogState extends ConsumerState<LostPetPosterDialog> {
  late TextEditingController _locationController;
  late TextEditingController _rewardController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  bool _isGeneratingPdf = false;
  bool _isGeneratingImage = false;
  int _selectedPalette = 0;
  final GlobalKey _posterKey = GlobalKey();

  static const List<Map<String, dynamic>> _palettes = [
    {
      'name': 'Classic Crimson',
      'bg': Color(0xFFFAF6EE),
      'banner': Color(0xFFB91C1C),
      'accent': Color(0xFFB45309),
      'border': Color(0xFFE5E0D0),
      'textPrimary': Color(0xFF1F2937),
      'textHeader': Color(0xFFB91C1C),
      'badgeText': Colors.white,
      'rewardBg': Color(0xFFFFFBEB),
      'rewardBorder': Color(0xFFD97706),
      'qrFg': Colors.black,
      'pdfBg': '#FAF6EE',
      'pdfBanner': '#B91C1C',
      'pdfBorder': '#E5E0D0',
      'pdfText': '#1F2937',
    },
    {
      'name': 'Neon Amber',
      'bg': Color(0xFF18181B),
      'banner': Color(0xFFD97706),
      'accent': Color(0xFFFBBF24),
      'border': Color(0xFFF59E0B),
      'textPrimary': Color(0xFFF4F4F5),
      'textHeader': Color(0xFFFBBF24),
      'badgeText': Colors.black,
      'rewardBg': Color(0xFF27272A),
      'rewardBorder': Color(0xFFFBBF24),
      'qrFg': Colors.black,
      'pdfBg': '#18181B',
      'pdfBanner': '#D97706',
      'pdfBorder': '#F59E0B',
      'pdfText': '#F4F4F5',
    },
    {
      'name': 'Midnight Dark',
      'bg': Color(0xFF0F172A),
      'banner': Color(0xFFEF4444),
      'accent': Color(0xFF38BDF8),
      'border': Color(0xFF334155),
      'textPrimary': Color(0xFFF8FAFC),
      'textHeader': Color(0xFFEF4444),
      'badgeText': Colors.white,
      'rewardBg': Color(0xFF1E293B),
      'rewardBorder': Color(0xFFEF4444),
      'qrFg': Colors.black,
      'pdfBg': '#0F172A',
      'pdfBanner': '#EF4444',
      'pdfBorder': '#334155',
      'pdfText': '#F8FAFC',
    },
    {
      'name': 'Royal Cobalt',
      'bg': Color(0xFFFFFFFF),
      'banner': Color(0xFF1D4ED8),
      'accent': Color(0xFFDC2626),
      'border': Color(0xFF3B82F6),
      'textPrimary': Color(0xFF1E293B),
      'textHeader': Color(0xFF1D4ED8),
      'badgeText': Colors.white,
      'rewardBg': Color(0xFFEFF6FF),
      'rewardBorder': Color(0xFF3B82F6),
      'qrFg': Color(0xFF1D4ED8),
      'pdfBg': '#FFFFFF',
      'pdfBanner': '#1D4ED8',
      'pdfBorder': '#3B82F6',
      'pdfText': '#1E293B',
    },
  ];

  Future<void> _exportImage(Pet pet) async {
    if (_isGeneratingImage) return;
    setState(() => _isGeneratingImage = true);
    await HapticFeedback.mediumImpact();
    try {
      final boundary = _posterKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Poster canvas render boundary unavailable');
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to encode PNG buffer');
      }
      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final sanitizedPetName = pet.name.replaceAll(RegExp(r'[^\w\s]+'), '').trim().toLowerCase();
      final file = File('${tempDir.path}/missing_${sanitizedPetName}_poster.png');
      await file.writeAsBytes(pngBytes, flush: true);

      await ExternalActions.shareFiles(
        [file.path],
        text: '🚨 MISSING PET ALERT: ${pet.name.toUpperCase()}!\n'
            'Please help spread the word and report any sightings immediately.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not export poster image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingImage = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final String ownerDefaultLocation = (profile?.city != null && profile!.city!.trim().isNotEmpty)
        ? profile.city!.trim()
        : 'Home Vicinity / Local Neighborhood';

    _locationController = TextEditingController(
      text: (widget.initialLocation != null && widget.initialLocation!.trim().isNotEmpty)
          ? widget.initialLocation!
          : ownerDefaultLocation,
    );
    _rewardController = TextEditingController(
      text: widget.initialReward ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialPhone ?? (profile?.phone ?? ''),
    );
    _notesController = TextEditingController(
      text: widget.initialNotes ?? 'Please help find ${widget.pet.name}. Call immediately if spotted.',
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _rewardController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _openEditDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Customize Poster Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Last Seen Location',
                  hintText: 'e.g. Near City Park, Elm Street',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _rewardController,
                decoration: const InputDecoration(
                  labelText: 'Reward Amount (Optional)',
                  hintText: 'e.g. RS. 5,000',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Phone',
                  hintText: 'e.g. +91 9876543210',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Save & Update'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  static String _cleanText(String input) {
    return input
        .replaceAll('₹', 'RS. ')
        .replaceAll('•', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('\u2022', '-')
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        .replaceAll('\u20B9', 'RS. ')
        .replaceAll(RegExp(r'[^\x00-\x7F]'), ' ')
        .trim();
  }

  Future<Uint8List?> _fetchImageBytes(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 8);
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode == 200) {
          final bytes = await response.fold<List<int>>([], (p, e) => p..addAll(e));
          return Uint8List.fromList(bytes);
        }
      } else {
        final f = File(url);
        if (f.existsSync()) {
          return await f.readAsBytes();
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;

    final ownerPhone = _cleanText(_phoneController.text.isNotEmpty ? _phoneController.text : (profile?.phone ?? '8921998733'));
    final ownerEmail = _cleanText(profile?.email ?? 'antonythomson0610@gmail.com');
    final lastSeenLocation = _cleanText(_locationController.text);
    final rewardAmount = _cleanText(_rewardController.text);
    final todayStr = DateFormat('dd MMM').format(DateTime.now());
    final baseUrl = Env.webBaseUrl;
    final petNameEnc = Uri.encodeComponent(pet.name);
    final phoneEnc = Uri.encodeComponent(ownerPhone);

    final qrPayload = '$baseUrl/missing/${pet.id}?phone=$phoneEnc&name=$petNameEnc';
    final palette = _palettes[_selectedPalette];
    final pBg = palette['bg'] as Color;
    final pBanner = palette['banner'] as Color;
    final pAccent = palette['accent'] as Color;
    final pBorder = palette['border'] as Color;
    final pTextPrimary = palette['textPrimary'] as Color;
    final pTextHeader = palette['textHeader'] as Color;
    final pBadgeText = palette['badgeText'] as Color;
    final pRewardBg = palette['rewardBg'] as Color;
    final pRewardBorder = palette['rewardBorder'] as Color;
    final pQrFg = palette['qrFg'] as Color;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── PALETTE SELECTOR BAR ──────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Theme: ',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    for (int i = 0; i < _palettes.length; i++)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedPalette = i);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedPalette == i ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 11,
                            backgroundColor: _palettes[i]['banner'] as Color,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── POSTER CANVAS WRAPPED IN REPAINT BOUNDARY ─────────────
              RepaintBoundary(
                key: _posterKey,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: pBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: pBorder, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── TOP BANNER PILL ─────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: pBanner,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'MISSING ${pet.species.toUpperCase()}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: pBadgeText,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: 2.0,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                      AppSpacing.vGapMd,

                      // ── PET NAME & BREED ───────────────────────────────────
                      Text(
                        pet.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: pTextHeader,
                          letterSpacing: 1.5,
                          fontFamily: 'serif',
                        ),
                      ),
                      Text(
                        pet.breedLine.toLowerCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: pTextPrimary,
                        ),
                      ),
                      AppSpacing.vGapMd,

                      // ── HERO PET PHOTO ─────────────────────────────────────
                      Container(
                        width: 220,
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFFE5E7EB),
                          border: Border.all(color: pBorder, width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: pet.imageUrl != null && pet.imageUrl!.isNotEmpty
                              ? Image.network(
                                  pet.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildFallbackAvatar(pet),
                                )
                              : _buildFallbackAvatar(pet),
                        ),
                      ),
                      AppSpacing.vGapMd,

                      // ── DETAILS ROWS ───────────────────────────────────────
                      InkWell(
                        onTap: _openEditDialog,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LAST SEEN LOCATION: ',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: pTextPrimary),
                              ),
                              Expanded(
                                child: Text(
                                  lastSeenLocation.isNotEmpty ? lastSeenLocation : 'Neighborhood / Home Area',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pTextPrimary.withValues(alpha: 0.85)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 12, thickness: 1.0, color: pBorder),
                      InkWell(
                        onTap: _openEditDialog,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text(
                                'MISSING SINCE: ',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: pTextPrimary),
                              ),
                              Text(
                                todayStr,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: pTextPrimary.withValues(alpha: 0.85)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(height: 12, thickness: 1.0, color: pBorder),
                      AppSpacing.vGapSm,

                      // ── REWARD BOX ──────────────────────────────────
                      if (rewardAmount.isNotEmpty)
                        InkWell(
                          onTap: _openEditDialog,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: pRewardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: pRewardBorder, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.stars_rounded, color: pAccent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'REWARD: $rewardAmount',
                                  style: TextStyle(
                                    color: pAccent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 1.0,
                                    fontFamily: 'serif',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        InkWell(
                          onTap: _openEditDialog,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: pRewardBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: pRewardBorder, width: 1.2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline, size: 16, color: pAccent),
                                const SizedBox(width: 8),
                                Text(
                                  '+ Set Cash Reward (e.g. ₹5,000)',
                                  style: TextStyle(
                                    color: pAccent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      AppSpacing.vGapMd,

                      // ── EMERGENCY CONTACT & QR CODE ─────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'IF FOUND OR SIGHTED, PLEASE CALL IMMEDIATELY:',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: pTextPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ownerPhone,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: pTextHeader,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Email: $ownerEmail',
                                  style: TextStyle(fontSize: 9.5, color: pTextPrimary.withValues(alpha: 0.7)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Generated via PetConnect AI Emergency Rescue Network • Scan QR to report sighting',
                                  style: TextStyle(fontSize: 7.5, color: pTextPrimary.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: pBorder, width: 1.0),
                            ),
                            child: PetQrCodeView(
                              data: qrPayload,
                              size: 72,
                              padding: 2,
                              foregroundColor: pQrFg,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── ACTION BUTTONS ──────────────────────────────────────
              Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: pBanner,
                              foregroundColor: pBadgeText,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: _isGeneratingImage
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: pBadgeText),
                                  )
                                : const Icon(Icons.image_rounded, size: 18),
                            label: Text(_isGeneratingImage ? 'Exporting...' : 'Share Image (PNG)'),
                            onPressed: _isGeneratingImage ? null : () => _exportImage(pet),
                          ),
                        ),
                        AppSpacing.hGapSm,
                        Expanded(
                          child: FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: _isGeneratingPdf
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                            label: Text(_isGeneratingPdf ? 'Generating...' : 'Export PDF'),
                            onPressed: _isGeneratingPdf
                                ? null
                                : () async {
                                    setState(() => _isGeneratingPdf = true);
                                    try {
                                      final imgBytes = await _fetchImageBytes(pet.imageUrl);

                                      final doc = pw.Document(
                                        title: 'MISSING PET: ${pet.name}',
                                        author: 'PetConnect AI Emergency Rescue',
                                      );

                                      final pdfBg = PdfColor.fromHex(palette['pdfBg'] as String);
                                      final pdfBanner = PdfColor.fromHex(palette['pdfBanner'] as String);
                                      final pdfBorder = PdfColor.fromHex(palette['pdfBorder'] as String);
                                      final pdfText = PdfColor.fromHex(palette['pdfText'] as String);

                                      doc.addPage(
                                        pw.Page(
                                          pageFormat: PdfPageFormat.a4,
                                          margin: const pw.EdgeInsets.all(28),
                                          build: (pw.Context ctx) {
                                            return pw.Container(
                                              decoration: pw.BoxDecoration(
                                                color: pdfBg,
                                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
                                                border: pw.Border.all(color: pdfBorder, width: 2),
                                              ),
                                              padding: const pw.EdgeInsets.all(24),
                                              child: pw.Column(
                                                crossAxisAlignment: pw.CrossAxisAlignment.center,
                                                children: [
                                                  // ── TOP BANNER PILL ──
                                                  pw.Container(
                                                    width: double.infinity,
                                                    padding: const pw.EdgeInsets.symmetric(vertical: 14),
                                                    decoration: pw.BoxDecoration(
                                                      color: pdfBanner,
                                                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                                                    ),
                                                    child: pw.Text(
                                                      'MISSING ${pet.species.toUpperCase()}',
                                                      textAlign: pw.TextAlign.center,
                                                      style: const pw.TextStyle(
                                                        color: PdfColors.white,
                                                        fontSize: 32,
                                                        fontWeight: pw.FontWeight.bold,
                                                        letterSpacing: 2.5,
                                                      ),
                                                    ),
                                                  ),
                                                  pw.SizedBox(height: 14),

                                                  // ── PET NAME & BREED ──
                                                  pw.Text(
                                                    pet.name.toUpperCase(),
                                                    style: pw.TextStyle(
                                                      fontSize: 36,
                                                      fontWeight: pw.FontWeight.bold,
                                                      color: pdfBanner,
                                                      letterSpacing: 1.5,
                                                    ),
                                                  ),
                                                  pw.SizedBox(height: 2),
                                                  pw.Text(
                                                    _cleanText(pet.breedLine.toLowerCase()),
                                                    style: pw.TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: pw.FontWeight.bold,
                                                      color: pdfText,
                                                    ),
                                                  ),
                                                  pw.SizedBox(height: 14),

                                                  // ── HERO PET PHOTO ──
                                                  if (imgBytes != null)
                                                    pw.Container(
                                                      height: 280,
                                                      width: 340,
                                                      child: pw.ClipRRect(
                                                        horizontalRadius: 16,
                                                        verticalRadius: 16,
                                                        child: pw.Image(
                                                          pw.MemoryImage(imgBytes),
                                                          fit: pw.BoxFit.cover,
                                                        ),
                                                      ),
                                                    )
                                                  else
                                                    pw.Container(
                                                      height: 200,
                                                      width: 200,
                                                      decoration: pw.BoxDecoration(
                                                        color: PdfColor.fromHex('#E5E7EB'),
                                                        shape: pw.BoxShape.circle,
                                                      ),
                                                      child: pw.Center(
                                                        child: pw.Text(
                                                          pet.name.isNotEmpty ? pet.name[0].toUpperCase() : 'PET',
                                                          style: pw.TextStyle(fontSize: 60, fontWeight: pw.FontWeight.bold, color: pdfBanner),
                                                        ),
                                                      ),
                                                    ),
                                                  pw.SizedBox(height: 16),

                                                  // ── DETAILS ROWS ──
                                                  pw.Row(
                                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                    children: [
                                                      pw.Text(
                                                        'LAST SEEN LOCATION: ',
                                                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: pdfText),
                                                      ),
                                                      pw.Expanded(
                                                        child: pw.Text(
                                                          lastSeenLocation.isNotEmpty ? lastSeenLocation : 'Neighborhood / Home Area',
                                                          style: pw.TextStyle(fontSize: 13, color: pdfText),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  pw.SizedBox(height: 6),
                                                  pw.Divider(color: pdfBorder, thickness: 1.0),
                                                  pw.SizedBox(height: 6),
                                                  pw.Row(
                                                    children: [
                                                      pw.Text(
                                                        'MISSING SINCE: ',
                                                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: pdfText),
                                                      ),
                                                      pw.Text(
                                                        todayStr,
                                                        style: pw.TextStyle(fontSize: 13, color: pdfText),
                                                      ),
                                                    ],
                                                  ),
                                                  pw.SizedBox(height: 6),
                                                  pw.Divider(color: pdfBorder, thickness: 1.0),
                                                  pw.SizedBox(height: 12),

                                                  // ── REWARD BOX ──
                                                  if (rewardAmount.isNotEmpty)
                                                    pw.Container(
                                                      width: double.infinity,
                                                      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                      decoration: pw.BoxDecoration(
                                                        color: PdfColor.fromHex('#FEF3C7'),
                                                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                                                        border: pw.Border.all(color: PdfColor.fromHex('#D97706'), width: 2),
                                                      ),
                                                      child: pw.Row(
                                                        mainAxisAlignment: pw.MainAxisAlignment.center,
                                                        children: [
                                                          pw.Text(
                                                            'REWARD: $rewardAmount',
                                                            style: pw.TextStyle(
                                                              color: PdfColor.fromHex('#78350F'),
                                                              fontWeight: pw.FontWeight.bold,
                                                              fontSize: 16,
                                                              letterSpacing: 1.0,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  pw.Spacer(),

                                                  // ── EMERGENCY CONTACT & QR CODE ──
                                                  pw.Row(
                                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                                                    children: [
                                                      pw.Expanded(
                                                        child: pw.Column(
                                                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                                                          children: [
                                                            pw.Text(
                                                              'IF FOUND OR SIGHTED, PLEASE CALL IMMEDIATELY:',
                                                              style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: pdfText),
                                                            ),
                                                            pw.SizedBox(height: 4),
                                                            pw.Text(
                                                              ownerPhone,
                                                              style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: pdfBanner),
                                                            ),
                                                            pw.SizedBox(height: 2),
                                                            pw.Text('Email: $ownerEmail', style: pw.TextStyle(fontSize: 10, color: pdfText)),
                                                            pw.SizedBox(height: 4),
                                                            pw.Text(
                                                              'Generated via PetConnect AI Emergency Rescue Network * Scan QR code to notify owner immediately',
                                                              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      pw.SizedBox(width: 14),
                                                      pw.BarcodeWidget(
                                                        data: qrPayload,
                                                        barcode: pw.Barcode.qrCode(),
                                                        width: 85,
                                                        height: 85,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      );

                                      final pdfBytes = await doc.save();
                                      final tempDir = await getTemporaryDirectory();
                                      final sanitized = pet.name.replaceAll(RegExp(r'[^\w\s]+'), '').trim();
                                      final file = File('${tempDir.path}/${sanitized}_Missing_Poster.pdf');
                                      await file.writeAsBytes(pdfBytes, flush: true);

                                      // ignore: deprecated_member_use
                                      await Share.shareXFiles(
                                        [XFile(file.path, mimeType: 'application/pdf')],
                                        text: '🚨 Missing Pet Poster (PDF) for ${pet.name}. Print or distribute immediately.',
                                        subject: 'MISSING PET POSTER: ${pet.name}',
                                      );
                                    } catch (_) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Failed to generate poster PDF. Please try again.')),
                                        );
                                      }
                                    } finally {
                                      if (mounted) setState(() => _isGeneratingPdf = false);
                                    }
                                  },
                              ),
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
        );
      }

  Widget _buildFallbackAvatar(Pet pet) {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: Center(
        child: Text(
          pet.name.isNotEmpty ? pet.name[0].toUpperCase() : 'P',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Color(0xFFB91C1C),
          ),
        ),
      ),
    );
  }
}
