import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Centralized utility for native device interactions:
/// Maps navigation, system sharing, URL launching, and phone calls.
class ExternalActions {
  const ExternalActions._();

  /// Opens native turn-by-turn map directions to the given coordinates.
  static Future<void> openMapDirections({
    required double latitude,
    required double longitude,
    String? label,
    BuildContext? context,
  }) async {
    final destination = '$latitude,$longitude';
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
    );
    final geoUrl = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude${label != null ? '($label)' : ''}');

    try {
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {
      // Fallback
    }

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Coordinates: $latitude, $longitude (${label ?? 'Target Location'})'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Opens native map searching for a given place or address.
  static Future<void> openMapSearch(String query, {BuildContext? context}) async {
    final encoded = Uri.encodeComponent(query);
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    final geoUrl = Uri.parse('geo:0,0?q=$encoded');

    try {
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location: $query'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Shares a wellness or health milestone via native device share sheet.
  static Future<void> shareMilestone({
    required String petName,
    required String species,
    required String status,
    double? weightKg,
    BuildContext? context,
  }) async {
    final weightStr = weightKg != null ? '${weightKg.toStringAsFixed(1)} kg' : 'optimal weight';
    final text = '🐾 PetConnect AI Health Milestone!\n\n'
        '$petName ($species) is in $status health with a current weight of $weightStr.\n'
        'Continuously monitored and tracked with PetConnect AI Health Passport.\n\n'
        '#PetConnectAI #PetHealth #WellnessMilestone';

    await shareText(text, subject: '$petName\'s Health Milestone');

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sharing $petName\'s milestone...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Native share text/link to any installed messaging or social application.
  static Future<void> shareText(String text, {String? subject}) async {
    try {
      // ignore: deprecated_member_use
      await Share.share(text, subject: subject);
    } catch (_) {
      // Ignore if cancelled
    }
  }

  /// Launches an external web URL or deep link.
  static Future<bool> openUrl(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null) return false;
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  /// Initiates a phone call dialer.
  static Future<bool> callPhoneNumber(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (_) {}
    return false;
  }

  /// Native share files with optional text and subject.
  static Future<void> shareFiles(
    List<String> filePaths, {
    String? text,
    String? subject,
  }) async {
    try {
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        filePaths.map((p) => XFile(p)).toList(),
        text: text,
        subject: subject,
      );
    } catch (_) {}
  }

  /// Alias for callPhoneNumber.
  static Future<bool> callPhone(String phoneNumber) => callPhoneNumber(phoneNumber);
}
