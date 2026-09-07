import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/config/env.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/router/route_paths.dart';

/// Public landing screen displayed when a QR code or web link is opened inside the app.
/// Handles:
/// - Missing pet sighting alerts (`/missing/:id`)
/// - Emergency clinical pet passes (`/emergency/:id`)
/// - Adoption inquiry profiles (`/adopt/:id`)
/// - Vaccination certificate verifications (`/verify/vaccine/:id` and `/verify/:id`)
class PublicQrLandingScreen extends StatelessWidget {
  const PublicQrLandingScreen({
    super.key,
    required this.type,
    required this.id,
    this.queryParams = const {},
  });

  final String type;
  final String id;
  final Map<String, String> queryParams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(RoutePaths.ownerHome);
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Share QR Link',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _shareCurrentAlert(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderBanner(context),
                  AppSpacing.vGapMd,
                  _buildMainCard(context, isDark),
                  AppSpacing.vGapMd,
                  _buildActionButtons(context),
                  AppSpacing.vGapLg,
                  _buildWebFallbackFooter(context),
                  AppSpacing.vGapXl,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _appBarTitle {
    switch (type) {
      case 'missing':
        return '🚨 Missing Pet Alert';
      case 'emergency':
        return '🛡️ Emergency Pass';
      case 'adopt':
        return '🐾 Adoption Profile';
      case 'verify':
        return '💉 Immunization Verification';
      default:
        return 'PetConnect QR Verification';
    }
  }

  Widget _buildHeaderBanner(BuildContext context) {
    Color bannerBg;
    Color bannerFg;
    IconData icon;
    String badgeText;
    String subtitle;

    switch (type) {
      case 'missing':
        bannerBg = const Color(0xFFB91C1C);
        bannerFg = Colors.white;
        icon = Icons.warning_amber_rounded;
        badgeText = 'ACTIVE MISSING PET ALERT';
        subtitle = 'If spotted or found, please notify the caregiver immediately.';
        break;
      case 'emergency':
        bannerBg = const Color(0xFFD97706);
        bannerFg = Colors.white;
        icon = Icons.emergency_rounded;
        badgeText = 'OFFICIAL PET EMERGENCY PASS';
        subtitle = 'Critical medical info & guardian emergency contact.';
        break;
      case 'adopt':
        bannerBg = const Color(0xFF0D9488);
        bannerFg = Colors.white;
        icon = Icons.volunteer_activism_rounded;
        badgeText = 'PET ADOPTION INITIATIVE';
        subtitle = 'Ready for a loving forever home.';
        break;
      case 'verify':
      default:
        bannerBg = const Color(0xFF15803D);
        bannerFg = Colors.white;
        icon = Icons.verified_rounded;
        badgeText = 'VERIFIED IMMUNIZATION RECORD';
        subtitle = 'Officially logged in PetConnect AI Clinical Registry.';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: bannerBg.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: bannerFg, size: 24),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badgeText,
                  style: TextStyle(
                    color: bannerFg,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: bannerFg.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard(BuildContext context, bool isDark) {
    final petName = queryParams['name'] ?? queryParams['pet'] ?? 'Companion';
    final species = queryParams['species'] ?? 'Pet';
    final breed = queryParams['breed'] ?? 'Registered Breed';
    final location = queryParams['location'] ?? queryParams['loc'] ?? 'Reported Area';
    final ownerName = queryParams['owner'] ?? 'Registered Guardian';
    final phone = queryParams['phone'] ?? '';
    final reward = queryParams['reward'] ?? '';
    final microchip = queryParams['microchip'] ?? '';
    final health = queryParams['health'] ?? '';
    final vaxName = queryParams['vax'] ?? '';
    final adminDate = queryParams['admin'] ?? '';
    final nextDue = queryParams['next'] ?? '';
    final batch = queryParams['batch'] ?? '';
    final doctor = queryParams['doc'] ?? '';
    final imgUrl = queryParams['img'] ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pet Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFFE2E8F0),
                ),
                clipBehavior: Clip.antiAlias,
                child: imgUrl.isNotEmpty && (imgUrl.startsWith('http://') || imgUrl.startsWith('https://'))
                    ? Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarFallback(petName),
                      )
                    : _buildAvatarFallback(petName),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      petName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$species • $breed',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    if (id.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${id.length > 12 ? id.substring(0, 12) : id}',
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Reward Banner if present
          if (reward.isNotEmpty) ...[
            AppSpacing.vGapMd,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFB45309), size: 22),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Text(
                      'GUARANTEED REWARD: ${reward.startsWith('₹') ? reward : '₹$reward'}',
                      style: const TextStyle(
                        color: Color(0xFF78350F),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          AppSpacing.vGapMd,
          const Divider(),
          AppSpacing.vGapSm,

          // Key Attributes
          if (type == 'missing') ...[
            _buildDataRow(context, 'Last Seen Location', location, Icons.location_on_outlined),
            _buildDataRow(context, 'Guardian / Owner', ownerName, Icons.person_outline),
            if (phone.isNotEmpty) _buildDataRow(context, 'Emergency Phone', phone, Icons.phone_outlined),
          ] else if (type == 'emergency') ...[
            if (microchip.isNotEmpty) _buildDataRow(context, 'Microchip ID', microchip, Icons.memory),
            if (health.isNotEmpty) _buildDataRow(context, 'Health Status', health, Icons.favorite_outline),
            _buildDataRow(context, 'Emergency Contact', '$ownerName ($phone)', Icons.contact_phone_outlined),
          ] else if (type == 'adopt') ...[
            _buildDataRow(context, 'Inquiry Pet', petName, Icons.pets),
            _buildDataRow(context, 'Shelter / Rescue', ownerName, Icons.home_outlined),
          ] else if (type == 'verify') ...[
            if (vaxName.isNotEmpty) _buildDataRow(context, 'Vaccine Administered', vaxName, Icons.medication_outlined),
            if (adminDate.isNotEmpty) _buildDataRow(context, 'Administration Date', adminDate, Icons.event_available_outlined),
            if (nextDue.isNotEmpty) _buildDataRow(context, 'Next Due / Booster', nextDue, Icons.alarm_outlined),
            if (batch.isNotEmpty) _buildDataRow(context, 'Batch / Lot Number', batch, Icons.qr_code_2_rounded),
            if (doctor.isNotEmpty) _buildDataRow(context, 'Veterinarian', doctor, Icons.medical_services_outlined),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Container(
      color: const Color(0xFFCBD5E1),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'P',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          AppSpacing.hGapSm,
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final phone = queryParams['phone'] ?? '';
    final petName = queryParams['name'] ?? queryParams['pet'] ?? 'Pet';

    return Column(
      children: [
        if (phone.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  label: const Text('Call Guardian Now'),
                  onPressed: () => ExternalActions.callPhoneNumber(phone),
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text('WhatsApp'),
                  onPressed: () {
                    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                    final msg = Uri.encodeComponent('Hi, I am contacting you regarding $petName on PetConnect AI!');
                    ExternalActions.openUrl('https://wa.me/$cleanPhone?text=$msg');
                  },
                ),
              ),
            ],
          ),
          AppSpacing.vGapSm,
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: const Icon(Icons.open_in_browser_rounded, size: 18),
            label: const Text('Open Web Portal Page'),
            onPressed: () => _openExternalWebPortal(),
          ),
        ),
      ],
    );
  }

  Widget _buildWebFallbackFooter(BuildContext context) {
    return Column(
      children: [
        Text(
          'Protected by PetConnect AI • Cryptographic Animal Health Network',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Destination: ${Env.webBaseUrl}/$type/$id',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5,
            fontFamily: 'monospace',
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  void _shareCurrentAlert(BuildContext context) {
    HapticFeedback.lightImpact();
    final url = _buildFullWebUrl();
    final petName = queryParams['name'] ?? queryParams['pet'] ?? 'Companion';
    ExternalActions.shareText(
      '🚨 PetConnect AI $type notice for $petName:\n$url',
      subject: 'PetConnect AI Notice: $petName',
    );
  }

  void _openExternalWebPortal() {
    final url = _buildFullWebUrl();
    ExternalActions.openUrl(url);
  }

  String _buildFullWebUrl() {
    return Uri.parse('${Env.webBaseUrl}/$type/$id').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    ).toString();
  }
}
