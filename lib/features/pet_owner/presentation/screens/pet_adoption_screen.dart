import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:petconnect_ai/core/config/env.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/core/utils/external_actions.dart';
import 'package:petconnect_ai/core/utils/qr_generator_helper.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// The **Pet Adoption Hub** connecting pet owners, rescuers, and prospective adopters
/// with real candidate listings, custom photo uploads, an interactive AI Companion Matcher quiz,
/// and an Adoption Enquiries Manager for tracking incoming applications.
class PetAdoptionScreen extends ConsumerStatefulWidget {
  const PetAdoptionScreen({super.key});

  @override
  ConsumerState<PetAdoptionScreen> createState() => _PetAdoptionScreenState();
}

class _PetAdoptionScreenState extends ConsumerState<PetAdoptionScreen> {
  static const double _maxContentWidth = 1100;
  static const String _customPetsKey = 'app_adoption_custom_pets_v3';

  String get _currentUserId {
    final user = ref.read(currentUserProfileProvider).valueOrNull;
    return user?.id ?? 'anon';
  }

  String get _favStorageKey => 'app_adoption_favorites_${_currentUserId}_v4';
  String get _sentInquiriesKey => 'app_adoption_sent_inquiries_${_currentUserId}_v4';
  String get _receivedInquiriesKey => 'app_adoption_received_inquiries_${_currentUserId}_v4';

  String _selectedCategory = 'All';
  String _searchQuery = '';
  Set<String> _favoritePetIds = {};
  List<_AdoptionCandidate> _customCandidates = [];
  List<Map<String, dynamic>> _sentInquiries = [];
  List<Map<String, dynamic>> _receivedInquiries = [];

  final List<String> _categories = const ['All', 'Favorites', 'Dogs', 'Cats', 'Puppies'];

  static const List<_AdoptionCandidate> _defaultCandidates = [
    _AdoptionCandidate(
      id: 'adopt-1',
      name: 'Bella',
      age: '2 yrs',
      species: 'Dog',
      breed: 'Golden Retriever',
      matchScore: 98,
      shelter: 'Bangalore Animal Rescue & Care',
      distance: '2.5 km away (Indiranagar)',
      imageUrl: 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=800',
      personality: ['Gentle', 'Kid Friendly', 'Active'],
      description: 'Loving, gentle, and highly trainable. Thrives with daily walks and a caring family.',
      contactPhone: '+91 98765 43210',
    ),
    _AdoptionCandidate(
      id: 'adopt-2',
      name: 'Oliver',
      age: '3 mos',
      species: 'Cat',
      breed: 'Short-hair Tabby',
      matchScore: 94,
      shelter: 'Feline Haven Rescue',
      distance: '3.8 km away (Koramangala)',
      imageUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800',
      personality: ['Playful', 'Affectionate', 'Litter Trained'],
      description: 'Energetic kitten who loves climbing and catnip toys. Gets along great with other pets.',
      contactPhone: '+91 98111 22334',
    ),
    _AdoptionCandidate(
      id: 'adopt-3',
      name: 'Charlie',
      age: '4 mos',
      species: 'Dog',
      breed: 'Beagle Mix Puppy',
      matchScore: 89,
      shelter: 'Hope for Paws Foundation',
      distance: '5.1 km away (Whitefield)',
      imageUrl: 'https://images.unsplash.com/photo-1537151625747-768eb6cf92b2?w=800',
      personality: ['Curious', 'Food Motivated', 'Social'],
      description: 'Sweet Beagle puppy with a keen nose for adventure. Vaccinated and ready for a loving home.',
      contactPhone: '+91 97444 55667',
    ),
    _AdoptionCandidate(
      id: 'adopt-4',
      name: 'Luna',
      age: '1 yr',
      species: 'Cat',
      breed: 'Calico Cat',
      matchScore: 91,
      shelter: 'Community Pet Welfare',
      distance: '4.2 km away (HSR Layout)',
      imageUrl: 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=800',
      personality: ['Calm', 'Independent', 'Cuddle Bug'],
      description: 'Quiet and sweet companion who enjoys sunny window sills and gentle scratches.',
      contactPhone: '+91 96555 88990',
    ),
    _AdoptionCandidate(
      id: 'adopt-5',
      name: 'Rocky',
      age: '1.5 yrs',
      species: 'Dog',
      breed: 'Indian Pariah (Indie)',
      matchScore: 99,
      shelter: 'Compassion Unlimited Plus Action (CUPA)',
      distance: '1.8 km away (Kochi / Bengaluru)',
      imageUrl: 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=800',
      personality: ['Extremely Resilient', 'Loyal', 'Tropical Adapted'],
      description: 'Healthy, highly intelligent native Indie. Perfectly adapted to local climate with natural disease resistance.',
      contactPhone: '+91 94000 12345',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadStoredData();
    _syncWithSupabase();
  }

  void _loadStoredData() {
    final prefs = ref.read(sharedPreferencesProvider);
    final favs = prefs.getStringList(_favStorageKey) ?? ['adopt-1'];
    final rawCustom = prefs.getString(_customPetsKey);
    final rawSent = prefs.getString(_sentInquiriesKey);
    final rawReceived = prefs.getString(_receivedInquiriesKey);

    List<_AdoptionCandidate> loadedCustom = [];
    if (rawCustom != null && rawCustom.isNotEmpty) {
      try {
        final list = (jsonDecode(rawCustom) as List<dynamic>)
            .map((j) => _AdoptionCandidate.fromJson(j as Map<String, dynamic>))
            .toList();
        loadedCustom = list;
      } catch (_) {}
    }

    List<Map<String, dynamic>> loadedSent = [];
    if (rawSent != null && rawSent.isNotEmpty) {
      try {
        loadedSent = List<Map<String, dynamic>>.from(jsonDecode(rawSent) as List);
      } catch (_) {}
    }

    List<Map<String, dynamic>> loadedReceived = [];
    if (rawReceived != null && rawReceived.isNotEmpty) {
      try {
        loadedReceived = List<Map<String, dynamic>>.from(jsonDecode(rawReceived) as List);
      } catch (_) {}
    }

    setState(() {
      _favoritePetIds = favs.toSet();
      _customCandidates = loadedCustom;
      _sentInquiries = loadedSent;
      _receivedInquiries = loadedReceived;
    });
  }

  Future<void> _syncWithSupabase() async {
    try {
      final client = ref.read(supabaseClientProvider);
      
      // 1. Fetch active adoption listings from Supabase cloud
      final listings = await client
          .from('adoption_listings')
          .select('*')
          .eq('status', 'active')
          .order('created_at', ascending: false);

      if (listings is List && listings.isNotEmpty && mounted) {
        final List<_AdoptionCandidate> cloudCandidates = [];
        for (final item in listings) {
          final map = item as Map<String, dynamic>;
          final id = map['id']?.toString() ?? '';
          final name = map['name']?.toString() ?? 'Companion';
          final species = map['species']?.toString() ?? 'Dog';
          final breed = map['breed']?.toString() ?? 'Companion';
          final age = map['age']?.toString() ?? '1 yr';
          final desc = map['description']?.toString() ?? '';
          final loc = map['location']?.toString() ?? 'Kerala, India';
          final phone = map['contact_phone']?.toString();
          final owner = map['owner_id']?.toString();
          final images = map['images'] as List?;
          final img = (images != null && images.isNotEmpty)
              ? images.first.toString()
              : (species.toLowerCase() == 'dog'
                  ? 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=800'
                  : 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800');
          final traits = map['personality_traits'] as List?;
          final personalityList = traits != null
              ? traits.map((t) => t.toString()).toList()
              : ['Loving', 'Healthy', 'Vaccinated'];

          cloudCandidates.add(_AdoptionCandidate(
            id: id,
            name: name,
            age: age,
            species: species.substring(0, 1).toUpperCase() + (species.length > 1 ? species.substring(1) : ''),
            breed: breed,
            matchScore: 96,
            shelter: 'PetConnect Verified Hub',
            distance: loc,
            imageUrl: img,
            personality: personalityList,
            description: desc,
            contactPhone: phone,
            ownerId: owner,
            isUserListed: owner != null && owner == _currentUserId,
          ));
        }

        final existingIds = _customCandidates.map((c) => c.id).toSet();
        final newFromCloud = cloudCandidates.where((c) => !existingIds.contains(c.id)).toList();
        if (newFromCloud.isNotEmpty && mounted) {
          setState(() {
            _customCandidates = [...newFromCloud, ..._customCandidates];
          });
        }
      }

      // 2. Fetch live inquiries for this user's listed pets
      final currentUid = _currentUserId;
      if (currentUid != 'anon') {
        final inquiries = await client
            .from('adoption_inquiries')
            .select('*, adoption_listings!inner(owner_id, name, species)')
            .eq('adoption_listings.owner_id', currentUid)
            .order('created_at', ascending: false);

        if (inquiries is List && inquiries.isNotEmpty && mounted) {
          final List<Map<String, dynamic>> cloudInquiries = [];
          for (final inq in inquiries) {
            final m = inq as Map<String, dynamic>;
            final listing = m['adoption_listings'] as Map<String, dynamic>?;
            cloudInquiries.add({
              'id': m['id']?.toString() ?? '',
              'petId': m['listing_id']?.toString() ?? '',
              'petName': listing?['name']?.toString() ?? 'Your Pet',
              'petSpecies': listing?['species']?.toString() ?? 'Companion',
              'shelter': 'Your Listing',
              'adopterName': m['applicant_name']?.toString() ?? 'Applicant',
              'adopterPhone': m['applicant_phone']?.toString() ?? '',
              'housingType': m['living_arrangement']?.toString() ?? m['housing_type']?.toString() ?? 'Home',
              'message': m['message']?.toString() ?? '',
              'timestamp': m['created_at']?.toString() ?? DateTime.now().toIso8601String(),
              'status': m['status']?.toString() ?? 'Under Review',
              'isMyListedPet': true,
            });
          }

          final existingInqIds = _receivedInquiries.map((i) => i['id']?.toString()).toSet();
          final fresh = cloudInquiries.where((i) => !existingInqIds.contains(i['id'])).toList();
          if (fresh.isNotEmpty && mounted) {
            setState(() {
              _receivedInquiries = [...fresh, ..._receivedInquiries];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Supabase adoption sync notice: $e');
    }
  }

  Future<void> _toggleFavorite(String id) async {
    await HapticFeedback.lightImpact();
    final updated = Set<String>.from(_favoritePetIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    setState(() => _favoritePetIds = updated);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_favStorageKey, updated.toList());
  }

  Future<void> _addCustomCandidate(_AdoptionCandidate candidate) async {
    final updated = [candidate, ..._customCandidates];
    setState(() => _customCandidates = updated);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _customPetsKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );

    // Sync to Supabase cloud table
    try {
      final client = ref.read(supabaseClientProvider);
      final currentUid = _currentUserId;
      if (currentUid != 'anon') {
        client.from('adoption_listings').insert({
          'owner_id': currentUid,
          'name': candidate.name,
          'species': candidate.species.toLowerCase(),
          'breed': candidate.breed,
          'age': candidate.age,
          'description': candidate.description,
          'location': candidate.distance,
          'contact_phone': candidate.contactPhone,
          'adoption_fee': 'Free / Loving Home',
          'is_vaccinated': true,
          'personality_traits': candidate.personality,
          'images': [candidate.imageUrl],
          'status': 'active',
        }).then((_) {}, onError: (e) => debugPrint('Listing Supabase sync error: $e'));
      }
    } catch (_) {}
  }

  Future<void> _updateCustomCandidate(_AdoptionCandidate candidate) async {
    final updated = _customCandidates.map((c) {
      if (c.id == candidate.id) {
        return candidate;
      }
      return c;
    }).toList();
    setState(() => _customCandidates = updated);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _customPetsKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _deleteCustomCandidate(String id) async {
    final updated = _customCandidates.where((c) => c.id != id).toList();
    setState(() => _customCandidates = updated);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _customPetsKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );

    try {
      final client = ref.read(supabaseClientProvider);
      client.from('adoption_listings').delete().eq('id', id).then((_) {}, onError: (_) {});
    } catch (_) {}
  }

  Future<void> _recordInquiry({
    required _AdoptionCandidate pet,
    required String message,
    required String housingType,
    required String adopterName,
    required String adopterPhone,
  }) async {
    final newInquiry = {
      'id': 'inq-${DateTime.now().millisecondsSinceEpoch}',
      'petId': pet.id,
      'petName': pet.name,
      'petSpecies': pet.species,
      'shelter': pet.shelter,
      'adopterName': adopterName,
      'adopterPhone': adopterPhone,
      'housingType': housingType,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'Under Review',
      'isMyListedPet': pet.isUserListed,
    };

    final updatedSent = [newInquiry, ..._sentInquiries];
    List<Map<String, dynamic>> updatedReceived = _receivedInquiries;

    if (pet.isUserListed) {
      updatedReceived = [newInquiry, ..._receivedInquiries];
    }

    setState(() {
      _sentInquiries = updatedSent;
      _receivedInquiries = updatedReceived;
    });

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_sentInquiriesKey, jsonEncode(updatedSent));
    if (pet.isUserListed) {
      await prefs.setString(_receivedInquiriesKey, jsonEncode(updatedReceived));
    }
  }

  Future<void> _updateReceivedInquiryStatus(int index, String newStatus) async {
    await HapticFeedback.lightImpact();
    final updated = List<Map<String, dynamic>>.from(_receivedInquiries);
    updated[index]['status'] = newStatus;
    setState(() => _receivedInquiries = updated);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_receivedInquiriesKey, jsonEncode(updated));
  }

  void _openPostPetDialog() {
    HapticFeedback.lightImpact();
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final breedCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final shelterCtrl = TextEditingController();
    String species = 'Dog';
    String? selectedImagePath;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.pets, color: Color(0xFFEC4899)),
              SizedBox(width: 8),
              Text('List Pet for Adoption'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── REAL IMAGE PICKER / PREVIEW ─────────────────────
                Center(
                  child: InkWell(
                    onTap: () async {
                      final picker = ImagePicker();
                      final source = await showModalBottomSheet<ImageSource>(
                        context: context,
                        builder: (sheetCtx) => SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.photo_library_rounded),
                                title: const Text('Choose from Gallery'),
                                onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt_rounded),
                                title: const Text('Take a Photo'),
                                onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
                              ),
                            ],
                          ),
                        ),
                      );

                      if (source != null) {
                        try {
                          final picked = await picker.pickImage(source: source, maxWidth: 1200, maxHeight: 1200, imageQuality: 85);
                          if (picked != null) {
                            try {
                              final appDir = await getApplicationDocumentsDirectory();
                              final persistentPath = '${appDir.path}/adopt_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
                              await File(picked.path).copy(persistentPath);
                              setDlgState(() => selectedImagePath = persistentPath);
                            } catch (_) {
                              setDlgState(() => selectedImagePath = picked.path);
                            }
                          }
                        } catch (_) {}
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                      ),
                      child: selectedImagePath != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    File(selectedImagePath!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const Positioned(
                                  right: 8,
                                  top: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    radius: 16,
                                    child: Icon(Icons.edit, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, size: 36, color: Color(0xFFEC4899)),
                                SizedBox(height: 6),
                                Text(
                                  'Tap to Add Pet Photo',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF374151),
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Camera or Gallery',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Pet Name *',
                    hintText: 'e.g. Leo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: species,
                        decoration: const InputDecoration(
                          labelText: 'Species',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Dog', child: Text('Dog')),
                          DropdownMenuItem(value: 'Cat', child: Text('Cat')),
                        ],
                        onChanged: (v) => setDlgState(() => species = v ?? 'Dog'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: ageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Age *',
                          hintText: 'e.g. 8 mos, 2 yrs',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: breedCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Breed',
                    hintText: 'e.g. Indian Pariah, Indie Shorthair, Beagle',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location / City',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone / WhatsApp',
                    hintText: '+91 98765 43210',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description & Personality',
                    hintText: 'Health, temperament, good with children...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || ageCtrl.text.trim().isEmpty) {
                  context.showSnackbar('Please enter pet name and age');
                  return;
                }
                final finalImg = selectedImagePath ??
                    (species == 'Dog'
                        ? 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=800'
                        : 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800');

                final newPet = _AdoptionCandidate(
                  id: 'adopt-user-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  age: ageCtrl.text.trim(),
                  species: species,
                  breed: breedCtrl.text.trim().isNotEmpty ? breedCtrl.text.trim() : 'Companion',
                  matchScore: 96,
                  shelter: shelterCtrl.text.trim().isNotEmpty ? shelterCtrl.text.trim() : 'Community Foster',
                  distance: locationCtrl.text.trim(),
                  imageUrl: finalImg,
                  personality: const ['Friendly', 'Healthy', 'Vaccinated'],
                  description: descCtrl.text.trim().isNotEmpty
                      ? descCtrl.text.trim()
                      : 'A wonderful companion waiting for a loving permanent home.',
                  contactPhone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : '+91 Contact via App',
                  ownerId: _currentUserId,
                  isUserListed: true,
                );

                _addCustomCandidate(newPet);
                Navigator.pop(ctx);
                context.showSnackbar('🎉 Listed ${newPet.name} for adoption successfully!');
              },
              child: const Text('Publish Listing'),
            ),
          ],
        ),
      ),
    );
  }

  void _openMyInquiriesModal() {
    HapticFeedback.lightImpact();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Adoption Inquiries Hub',
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
              const TabBar(
                tabs: [
                  Tab(text: 'Applications Sent'),
                  Tab(text: 'Inquiries Received (My Pets)'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 380,
                child: TabBarView(
                  children: [
                    // Tab 1: Sent
                    _buildSentInquiriesList(),
                    // Tab 2: Received on Listed Pets
                    _buildReceivedInquiriesList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentInquiriesList() {
    if (_sentInquiries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_outlined, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text('No Applications Sent Yet', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Inquire about any pet in the feed to track here.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _sentInquiries.length,
      separatorBuilder: (_, __) => const Divider(height: 12),
      itemBuilder: (ctx, i) {
        final inq = _sentInquiries[i];
        final petName = inq['petName']?.toString() ?? 'Pet';
        final shelter = inq['shelter']?.toString() ?? 'Shelter';
        final status = inq['status']?.toString() ?? 'Under Review';
        final message = inq['message']?.toString() ?? '';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: context.colorScheme.primaryContainer,
            child: Icon(Icons.pets, color: context.colorScheme.primary),
          ),
          title: Text(
            'Application for $petName',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shelter / Guardian: $shelter', style: const TextStyle(fontSize: 12)),
              if (message.isNotEmpty)
                Text(
                  '"$message"',
                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF10B981)),
            ),
            child: Text(
              status,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceivedInquiriesList() {
    if (_receivedInquiries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text('No Incoming Inquiries Yet', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('When someone inquires about your listed pet, it appears here.', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _receivedInquiries.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (ctx, i) {
        final inq = _receivedInquiries[i];
        final petName = inq['petName']?.toString() ?? 'Pet';
        final applicantName = inq['adopterName']?.toString() ?? 'Adopter';
        final phone = inq['adopterPhone']?.toString() ?? '';
        final housing = inq['housingType']?.toString() ?? 'Apartment';
        final status = inq['status']?.toString() ?? 'Pending Review';
        final message = inq['message']?.toString() ?? '';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inquiry for $petName',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: status == 'Approved' ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: status == 'Approved' ? const Color(0xFF047857) : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Applicant: $applicantName • Home: $housing',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '"$message"',
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF6B7280)),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (phone.isNotEmpty) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => ExternalActions.callPhoneNumber(phone),
                      icon: const Icon(Icons.call, size: 14, color: Colors.green),
                      label: Text('Call $phone', style: const TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  if (status != 'Approved')
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _updateReceivedInquiryStatus(i, 'Approved'),
                      child: const Text('Approve Match', style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCompanionMatcherQuiz() {
    HapticFeedback.lightImpact();

    String livingSpace = 'Apartment';
    String activityLevel = 'Moderate (30-45 mins/day)';
    String household = 'Kids & Family';
    String sheddingPref = 'Low Shedding';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setQuizState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
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
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFEC4899), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Companion Matcher Quiz',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'Find the exact breed suited to your home & routine',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // 1. Living Space
                const Text('1. Your Living Environment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: ['Apartment', 'Independent House', 'House with Fenced Yard', 'Farm / Villa'].map((opt) {
                    final sel = livingSpace == opt;
                    return ChoiceChip(
                      label: Text(opt, style: TextStyle(fontSize: 11, color: sel ? Colors.white : Colors.black87)),
                      selected: sel,
                      selectedColor: const Color(0xFFEC4899),
                      onSelected: (_) => setQuizState(() => livingSpace = opt),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 2. Daily Activity
                const Text('2. Daily Walk & Exercise Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: ['Couch Potato (15 mins)', 'Moderate (30-45 mins/day)', 'High Athletic (1-2 hours/day)'].map((opt) {
                    final sel = activityLevel == opt;
                    return ChoiceChip(
                      label: Text(opt, style: TextStyle(fontSize: 11, color: sel ? Colors.white : Colors.black87)),
                      selected: sel,
                      selectedColor: const Color(0xFFEC4899),
                      onSelected: (_) => setQuizState(() => activityLevel = opt),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 3. Household Composition
                const Text('3. Household Composition', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: ['Solo Adult', 'Couple / Working Professionals', 'Kids & Family', 'Seniors / Quiet Home'].map((opt) {
                    final sel = household == opt;
                    return ChoiceChip(
                      label: Text(opt, style: TextStyle(fontSize: 11, color: sel ? Colors.white : Colors.black87)),
                      selected: sel,
                      selectedColor: const Color(0xFFEC4899),
                      onSelected: (_) => setQuizState(() => household = opt),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // 4. Shedding / Allergies
                const Text('4. Coat Shedding & Allergy Tolerance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: ['Low Shedding / Hypoallergenic', 'Moderate Grooming OK', 'No Preference'].map((opt) {
                    final sel = sheddingPref == opt;
                    return ChoiceChip(
                      label: Text(opt, style: TextStyle(fontSize: 11, color: sel ? Colors.white : Colors.black87)),
                      selected: sel,
                      selectedColor: const Color(0xFFEC4899),
                      onSelected: (_) => setQuizState(() => sheddingPref = opt),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEC4899),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showQuizResults(
                        livingSpace: livingSpace,
                        activityLevel: activityLevel,
                        household: household,
                        sheddingPref: sheddingPref,
                      );
                    },
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Calculate Compatibility & Recommendations'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuizResults({
    required String livingSpace,
    required String activityLevel,
    required String household,
    required String sheddingPref,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.verified, color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Your Top AI Breed Recommendations',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRecommendationCard(
                breed: 'Indian Pariah Dog (Indie / Desi)',
                species: 'Dog',
                matchPercent: 99,
                traits: 'Zero hereditary issues • Climate resilient • Extremely loyal',
                careNote: 'Top pick for South India/Kerala. Highly intelligent, minimal shedding, naturally hygienic.',
              ),
              const SizedBox(height: 10),
              _buildRecommendationCard(
                breed: 'Indian Domestic Shorthair (Indie Cat)',
                species: 'Cat',
                matchPercent: 97,
                traits: 'Affectionate • Self-grooming • High immunity',
                careNote: 'Perfect for apartment and villa living. Excellent hunter and companion with zero fungal coat risks.',
              ),
              const SizedBox(height: 10),
              _buildRecommendationCard(
                breed: 'Golden Retriever / Labrador',
                species: 'Dog',
                matchPercent: 93,
                traits: 'Gentle with kids • Highly trainable • Sociable',
                careNote: 'Outstanding family pet. Requires 45 mins daily exercise and brushing.',
              ),
              const SizedBox(height: 10),
              _buildRecommendationCard(
                breed: 'British Shorthair / Bombay Cat',
                species: 'Cat',
                matchPercent: 91,
                traits: 'Calm • Low vocalization • Independent',
                careNote: 'Ideal for busy professionals in flats who desire calm indoor companions.',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _searchQuery = 'Indie');
                  },
                  child: const Text('Filter Feed for Top Recommended Matches'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard({
    required String breed,
    required String species,
    required int matchPercent,
    required String traits,
    required String careNote,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                breed,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Text(
                  '$matchPercent% MATCH',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(traits, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4B5563))),
          const SizedBox(height: 4),
          Text(careNote, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final allList = [..._customCandidates, ..._defaultCandidates];

    final filteredCandidates = allList.where((pet) {
      if (_selectedCategory == 'Favorites' && !_favoritePetIds.contains(pet.id)) return false;
      if (_selectedCategory == 'Dogs' && pet.species != 'Dog') return false;
      if (_selectedCategory == 'Cats' && pet.species != 'Cat') return false;
      if (_selectedCategory == 'Puppies' && !pet.age.contains('mos')) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return pet.name.toLowerCase().contains(q) ||
            pet.breed.toLowerCase().contains(q) ||
            pet.shelter.toLowerCase().contains(q) ||
            pet.distance.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: OwnerGlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => GoRouter.of(context).pop(),
        ),
        title: Text(
          'Adopt a Pet',
          style: context.textTheme.headlineSmall?.copyWith(
            color: scheme.primary,
            fontWeight: AppTypography.bold,
            letterSpacing: -0.25,
          ),
        ),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${_receivedInquiries.length + _sentInquiries.length}'),
              isLabelVisible: (_receivedInquiries.length + _sentInquiries.length) > 0,
              child: const Icon(Icons.assignment_outlined),
            ),
            tooltip: 'Adoption Inquiries',
            onPressed: _openMyInquiriesModal,
          ),
          IconButton(
            icon: Badge(
              label: Text('${_favoritePetIds.length}'),
              isLabelVisible: _favoritePetIds.isNotEmpty,
              child: const Icon(Icons.favorite),
            ),
            tooltip: 'Saved Favorites',
            onPressed: () => _openFavoritesModal(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPostPetDialog,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('List Pet for Adoption'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── AI COMPANION MATCHER HERO CARD ────────────────
                AiGradientBorderCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: scheme.primary, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'AI Companion Matcher',
                            style: context.textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: AppTypography.bold,
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Take our 1-minute lifestyle quiz to find the perfect breed and adoptable companion for your home.',
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      AppSpacing.vGapMd,
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEC4899),
                        ),
                        onPressed: _openCompanionMatcherQuiz,
                        icon: const Icon(Icons.quiz_rounded, size: 18),
                        label: const Text('Take Lifestyle Compatibility Quiz'),
                      ),
                      AppSpacing.vGapMd,
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search by breed, age, shelter, or city...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: isDark
                              ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                              : scheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: scheme.outlineVariant.withValues(alpha: 0.3),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.vGapLg,

                // ── Category Filters ──────────────────────────────
                Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
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
                            HapticFeedback.lightImpact();
                            setState(() => _selectedCategory = cat);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapLg,

                // ── AI Recommended Matches ────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Adoption Candidates',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      '${filteredCandidates.length} Available',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapSm,

                if (filteredCandidates.isEmpty)
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.pets_outlined, size: 48, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                          AppSpacing.vGapSm,
                          Text('No Pets Matching "$_searchQuery"', style: context.textTheme.titleMedium),
                          AppSpacing.vGapXs,
                          Text('Try broadening your filters or list a new pet above.', style: context.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredCandidates.length,
                    separatorBuilder: (_, __) => AppSpacing.vGapLg,
                    itemBuilder: (context, index) {
                      final candidate = filteredCandidates[index];
                      return _buildCandidateCard(context, candidate);
                    },
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPetImage(
    String imageUrl,
    ColorScheme scheme, {
    double? height = 220,
    BoxFit fit = BoxFit.cover,
  }) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildImageFallback(scheme, height: height),
      );
    } else if (imageUrl.startsWith('data:image')) {
      try {
        final base64Data = imageUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Data),
          height: height,
          width: double.infinity,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildImageFallback(scheme, height: height),
        );
      } catch (_) {
        return _buildImageFallback(scheme, height: height);
      }
    } else if (imageUrl.isNotEmpty && File(imageUrl).existsSync()) {
      return Image.file(
        File(imageUrl),
        height: height,
        width: double.infinity,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildImageFallback(scheme, height: height),
      );
    } else {
      return _buildImageFallback(scheme, height: height);
    }
  }

  Widget _buildImageFallback(ColorScheme scheme, {double? height = 220}) {
    return Container(
      height: height,
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: Icon(Icons.pets, size: 64, color: scheme.primary.withValues(alpha: 0.5)),
      ),
    );
  }

  void _openPetPhotoModal(BuildContext context, _AdoptionCandidate pet) {
    final scheme = context.colorScheme;
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                width: double.infinity,
                color: Colors.black,
                child: InteractiveViewer(
                  maxScale: 4.0,
                  minScale: 0.8,
                  child: Center(
                    child: _buildPetImage(
                      pet.imageUrl,
                      scheme,
                      height: null,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pet.name} (${pet.age})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${pet.breed} • ${pet.shelter}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                    icon: const Icon(Icons.campaign_outlined, size: 18),
                    label: const Text('Poster'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openAdoptionPosterDialog(context, pet);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showInquireSheet(context, pet);
                    },
                    child: const Text('Adopt'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFavoritesModal(BuildContext context) {
    HapticFeedback.lightImpact();
    final scheme = context.colorScheme;
    final allList = [..._customCandidates, ..._defaultCandidates];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final currentFavs = allList.where((p) => _favoritePetIds.contains(p.id)).toList();
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.redAccent, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Saved Favorites (${currentFavs.length})',
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: AppTypography.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 16),
                if (currentFavs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.favorite_border, size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            'No Saved Favorites Yet',
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap the heart icon on any adoptable pet to save them here for quick review!',
                            textAlign: TextAlign.center,
                            style: context.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: currentFavs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final pet = currentFavs[i];
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: _buildPetImage(pet.imageUrl, scheme, height: 70, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${pet.name}, ${pet.age}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      '${pet.breed} • ${pet.shelter}',
                                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        FilledButton.tonal(
                                          style: FilledButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                          ),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _showInquireSheet(context, pet);
                                          },
                                          child: const Text('Inquire', style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(width: 6),
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            visualDensity: VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                          icon: const Icon(Icons.campaign_outlined, size: 14),
                                          label: const Text('Poster', style: TextStyle(fontSize: 12)),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _openAdoptionPosterDialog(context, pet);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.redAccent),
                                tooltip: 'Remove from favorites',
                                onPressed: () async {
                                  await _toggleFavorite(pet.id);
                                  setModalState(() {});
                                },
                              ),
                            ],
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

  void _openAdoptionPosterDialog(BuildContext context, _AdoptionCandidate pet) {
    HapticFeedback.mediumImpact();
    final GlobalKey posterKey = GlobalKey();
    bool isGenerating = false;
    int selectedPalette = 0;

    final palettes = [
      // 0: Nordic Slate
      {
        'name': 'Nordic Slate',
        'bg': const Color(0xFF1E293B),
        'accent': const Color(0xFF38BDF8),
        'badgeBg': const Color(0xFF0F172A),
        'textColor': Colors.white,
        'subtextColor': const Color(0xFF94A3B8),
        'chipBg': const Color(0xFF334155),
        'chipText': Colors.white,
        'border': const Color(0xFF475569),
        'qrFg': const Color(0xFF0F172A),
      },
      // 1: Warm Studio Cream
      {
        'name': 'Studio Cream',
        'bg': const Color(0xFFFAF7F2),
        'accent': const Color(0xFFC2410C),
        'badgeBg': const Color(0xFFEFE8DD),
        'textColor': const Color(0xFF1C1917),
        'subtextColor': const Color(0xFF57534E),
        'chipBg': const Color(0xFFE7DFD5),
        'chipText': const Color(0xFF1C1917),
        'border': const Color(0xFFD6C7B6),
        'qrFg': const Color(0xFF1C1917),
      },
      // 2: Terracotta Sunset
      {
        'name': 'Terracotta',
        'bg': const Color(0xFF7C2D12),
        'accent': const Color(0xFFFDBA74),
        'badgeBg': const Color(0xFF431407),
        'textColor': Colors.white,
        'subtextColor': const Color(0xFFFFEDD5),
        'chipBg': const Color(0xFF9A3412),
        'chipText': Colors.white,
        'border': const Color(0xFFEA580C),
        'qrFg': const Color(0xFF431407),
      },
      // 3: Forest Sage
      {
        'name': 'Forest Sage',
        'bg': const Color(0xFF064E3B),
        'accent': const Color(0xFF6EE7B7),
        'badgeBg': const Color(0xFF022C22),
        'textColor': Colors.white,
        'subtextColor': const Color(0xFFA7F3D0),
        'chipBg': const Color(0xFF047857),
        'chipText': Colors.white,
        'border': const Color(0xFF059669),
        'qrFg': const Color(0xFF022C22),
      },
    ];

    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final palette = palettes[selectedPalette];
          final pBg = palette['bg'] as Color;
          final pAccent = palette['accent'] as Color;
          final pTextColor = palette['textColor'] as Color;
          final pSubtextColor = palette['subtextColor'] as Color;
          final pChipBg = palette['chipBg'] as Color;
          final pChipText = palette['chipText'] as Color;
          final pBorder = palette['border'] as Color;
          final pQrFg = palette['qrFg'] as Color;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Palette Switcher ────────────────────────────────
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
                          'Palette:',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        for (int i = 0; i < palettes.length; i++) ...[
                          GestureDetector(
                            onTap: () => setDialogState(() => selectedPalette = i),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedPalette == i ? Colors.white : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 11,
                                backgroundColor: palettes[i]['bg'] as Color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Poster Canvas ───────────────────────────────────
                  RepaintBoundary(
                    key: posterKey,
                    child: Container(
                      width: 360,
                      decoration: BoxDecoration(
                        color: pBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: pBorder, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: pAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.pets, size: 15, color: pBg),
                                const SizedBox(width: 6),
                                Text(
                                  'LOOKING FOR A HOME',
                                  style: TextStyle(
                                    color: pBg,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            pet.name.toUpperCase(),
                            style: TextStyle(
                              color: pTextColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '${pet.breed} • ${pet.age}',
                            style: TextStyle(
                              color: pSubtextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: pBorder, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildPetImage(
                                pet.imageUrl,
                                Theme.of(context).colorScheme,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: pChipBg.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: pBorder.withValues(alpha: 0.5)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildPosterSpecItem('Species', pet.species, textColor: pTextColor, subColor: pSubtextColor),
                                    _buildPosterSpecItem('Age', pet.age, textColor: pTextColor, subColor: pSubtextColor),
                                    _buildPosterSpecItem('Health', 'Vaccinated', textColor: pTextColor, subColor: pSubtextColor),
                                  ],
                                ),
                                Divider(color: pBorder.withValues(alpha: 0.4), height: 16),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, color: pAccent, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${pet.shelter} (${pet.distance})',
                                        style: TextStyle(color: pSubtextColor, fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Clean solid pills without '#' hashtags
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: pet.personality.map((trait) {
                              final cleanTrait = trait.replaceAll('#', '').trim();
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: pChipBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: pBorder),
                                ),
                                child: Text(
                                  cleanTrait,
                                  style: TextStyle(
                                    color: pChipText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          // ISO Standard QR Code Container
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PetQrCodeView(
                                  data: '${Env.webBaseUrl}/adopt/${pet.id}?name=${Uri.encodeComponent(pet.name)}&breed=${Uri.encodeComponent(pet.breed)}&age=${Uri.encodeComponent(pet.age)}&species=${Uri.encodeComponent(pet.species)}&location=${Uri.encodeComponent(pet.shelter)}&phone=${Uri.encodeComponent(pet.contactPhone ?? '')}&fee=Free&img=${Uri.encodeComponent(pet.imageUrl)}&bio=${Uri.encodeComponent(pet.description)}',
                                  size: 76,
                                  padding: 0,
                                  foregroundColor: pQrFg,
                                  backgroundColor: Colors.transparent,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SCAN TO ADOPT OR INQUIRE',
                                        style: TextStyle(
                                          color: pQrFg,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        'Point phone camera or Google Lens to view full medical history & contact foster.',
                                        style: TextStyle(
                                          color: Color(0xFF475569),
                                          fontSize: 10,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'PETCONNECT AI • ADOPTION INITIATIVE',
                            style: TextStyle(
                              color: pSubtextColor.withValues(alpha: 0.7),
                              fontSize: 9,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          foregroundColor: Colors.white,
                        ),
                        icon: isGenerating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.share_rounded),
                        label: Text(isGenerating ? 'Exporting...' : 'Share Poster'),
                        onPressed: isGenerating
                            ? null
                            : () async {
                                setDialogState(() => isGenerating = true);
                                try {
                                  final boundary = posterKey.currentContext?.findRenderObject()
                                      as RenderRepaintBoundary?;
                                  if (boundary != null) {
                                    final image = await boundary.toImage(pixelRatio: 3.0);
                                    final byteData =
                                        await image.toByteData(format: ui.ImageByteFormat.png);
                                    if (byteData != null) {
                                      final pngBytes = byteData.buffer.asUint8List();
                                      final tempDir = await getTemporaryDirectory();
                                      final file = File(
                                          '${tempDir.path}/adopt_${pet.name.toLowerCase()}_poster.png');
                                      await file.writeAsBytes(pngBytes);
                                      await ExternalActions.shareFiles(
                                        [file.path],
                                        text: '🐾 Adopt ${pet.name}! Scan QR code or contact ${pet.shelter}.',
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Poster share notice: $e')),
                                    );
                                  }
                                } finally {
                                  if (ctx.mounted) {
                                    setDialogState(() => isGenerating = false);
                                  }
                                }
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPosterSpecItem(String label, String value, {Color? textColor, Color? subColor}) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: subColor ?? Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: textColor ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  void _openEditPetDialog(BuildContext context, _AdoptionCandidate pet) {
    HapticFeedback.lightImpact();
    final nameCtrl = TextEditingController(text: pet.name);
    final ageCtrl = TextEditingController(text: pet.age);
    final breedCtrl = TextEditingController(text: pet.breed);
    final shelterCtrl = TextEditingController(text: pet.shelter);
    final locationCtrl = TextEditingController(text: pet.distance);
    final phoneCtrl = TextEditingController(text: pet.contactPhone);
    final descCtrl = TextEditingController(text: pet.description);
    String species = pet.species;
    String? selectedImagePath = pet.imageUrl;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: Color(0xFFEC4899), size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Edit ${pet.name}\'s Listing',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1024,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      try {
                        final appDir = await getApplicationDocumentsDirectory();
                        final persistentPath = '${appDir.path}/adopt_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        await File(picked.path).copy(persistentPath);
                        setDlgState(() => selectedImagePath = persistentPath);
                      } catch (_) {
                        setDlgState(() => selectedImagePath = picked.path);
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                    ),
                    child: (selectedImagePath != null && selectedImagePath!.isNotEmpty)
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: _buildPetImage(selectedImagePath!, Theme.of(context).colorScheme),
                              ),
                              const Positioned(
                                right: 8,
                                top: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  radius: 16,
                                  child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_rounded, size: 36, color: Color(0xFFEC4899)),
                              SizedBox(height: 6),
                              Text(
                                'Tap to Update Pet Photo',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Pet Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: species,
                        decoration: const InputDecoration(
                          labelText: 'Species',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Dog', child: Text('Dog')),
                          DropdownMenuItem(value: 'Cat', child: Text('Cat')),
                        ],
                        onChanged: (v) => setDlgState(() => species = v ?? 'Dog'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: ageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Age *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: breedCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Breed',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location / City',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone / WhatsApp',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description & Personality',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty || ageCtrl.text.trim().isEmpty) {
                  context.showSnackbar('Please enter pet name and age');
                  return;
                }
                final updated = _AdoptionCandidate(
                  id: pet.id,
                  name: nameCtrl.text.trim(),
                  age: ageCtrl.text.trim(),
                  species: species,
                  breed: breedCtrl.text.trim().isNotEmpty ? breedCtrl.text.trim() : pet.breed,
                  matchScore: pet.matchScore,
                  shelter: shelterCtrl.text.trim().isNotEmpty ? shelterCtrl.text.trim() : pet.shelter,
                  distance: locationCtrl.text.trim().isNotEmpty ? locationCtrl.text.trim() : pet.distance,
                  imageUrl: selectedImagePath ?? pet.imageUrl,
                  personality: pet.personality,
                  description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : pet.description,
                  contactPhone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : pet.contactPhone,
                  ownerId: pet.ownerId ?? _currentUserId,
                  isUserListed: true,
                );
                _updateCustomCandidate(updated);
                Navigator.pop(ctx);
                context.showSnackbar('✓ Updated ${updated.name}\'s listing successfully!');
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateCard(BuildContext context, _AdoptionCandidate pet) {
    final scheme = context.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final isFav = _favoritePetIds.contains(pet.id);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _openPetPhotoModal(context, pet),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: _buildPetImage(pet.imageUrl, scheme),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.greenAccent, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, color: Colors.greenAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${pet.matchScore}% Match',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.redAccent : Colors.white,
                      ),
                      onPressed: () => _toggleFavorite(pet.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${pet.name}, ${pet.age}',
                      style: context.textTheme.titleLarge?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    Text(
                      pet.breed,
                      style: context.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapXs,
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${pet.shelter} • ${pet.distance}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                AppSpacing.vGapSm,
                Text(
                  pet.description,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    height: 1.35,
                  ),
                ),
                AppSpacing.vGapSm,
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: pet.personality.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer.withValues(alpha: isDark ? 0.3 : 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                AppSpacing.vGapMd,
                Row(
                  children: [
                    Expanded(
                      child: AppButton.filled(
                        onPressed: () => _showInquireSheet(context, pet),
                        child: Text('Inquire About ${pet.name}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.campaign_outlined),
                      tooltip: 'Generate Adoption Poster',
                      onPressed: () => _openAdoptionPosterDialog(context, pet),
                    ),
                    if (pet.isUserListed && (pet.ownerId == null || pet.ownerId == _currentUserId)) ...[
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit Listing',
                        onPressed: () => _openEditPetDialog(context, pet),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        icon: Icon(Icons.delete_outline, color: scheme.error),
                        tooltip: 'Delete Listing',
                        onPressed: () => _confirmDeletePet(context, pet),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePet(BuildContext context, _AdoptionCandidate pet) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            const Text('Delete Listing'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${pet.name} from adoption listings? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteCustomCandidate(pet.id);
              context.showSnackbar('✓ Removed ${pet.name}\'s listing.');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showInquireSheet(BuildContext context, _AdoptionCandidate pet) {
    HapticFeedback.lightImpact();
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final nameCtrl = TextEditingController(text: profile?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: profile?.phone ?? '');
    final noteCtrl = TextEditingController();
    String housing = 'Apartment';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
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
                      'Adoption Inquiry: ${pet.name}',
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
                  'Submit your adoption interest to ${pet.shelter}.',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSpacing.vGapMd,
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Your Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Your Phone Number *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: housing,
                  decoration: const InputDecoration(
                    labelText: 'Home / Living Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Apartment', child: Text('Apartment')),
                    DropdownMenuItem(value: 'Independent House', child: Text('Independent House')),
                    DropdownMenuItem(value: 'House with Gated Yard', child: Text('House with Gated Yard')),
                    DropdownMenuItem(value: 'Farm / Villa', child: Text('Farm / Villa')),
                  ],
                  onChanged: (v) => setSheetState(() => housing = v ?? 'Apartment'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message to Shelter / Guardian',
                    hintText: 'Introduce your home, daily routine, and experience with pets...',
                    border: OutlineInputBorder(),
                  ),
                ),
                AppSpacing.vGapMd,
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send Adoption Application'),
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                        context.showSnackbar('Please enter your name and phone number');
                        return;
                      }

                      _recordInquiry(
                        pet: pet,
                        message: noteCtrl.text.trim(),
                        housingType: housing,
                        adopterName: nameCtrl.text.trim(),
                        adopterPhone: phoneCtrl.text.trim(),
                      );

                      Navigator.pop(ctx);
                      HapticFeedback.lightImpact();

                      final client = ref.read(supabaseClientProvider);
                      final userId = client.auth.currentUser?.id;
                      if (userId != null) {
                        client.from('user_notifications').insert({
                          'user_id': userId,
                          'title': 'Adoption Application Sent: ${pet.name}',
                          'body': 'Your inquiry has been received by ${pet.shelter}. They will contact you shortly.',
                          'notification_type': 'ADOPTION',
                          'is_read': false,
                        }).then((_) {}, onError: (_) {});
                      }

                      context.showSnackbar('🎉 Application sent to ${pet.shelter}! Track it in "Adoption Inquiries".');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdoptionCandidate {
  const _AdoptionCandidate({
    required this.id,
    required this.name,
    required this.age,
    required this.species,
    required this.breed,
    required this.matchScore,
    required this.shelter,
    required this.distance,
    required this.imageUrl,
    required this.personality,
    required this.description,
    this.contactPhone,
    this.ownerId,
    this.isUserListed = false,
  });

  final String id;
  final String name;
  final String age;
  final String species;
  final String breed;
  final int matchScore;
  final String shelter;
  final String distance;
  final String imageUrl;
  final List<String> personality;
  final String description;
  final String? contactPhone;
  final String? ownerId;
  final bool isUserListed;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'species': species,
    'breed': breed,
    'matchScore': matchScore,
    'shelter': shelter,
    'distance': distance,
    'imageUrl': imageUrl,
    'personality': personality,
    'description': description,
    'contactPhone': contactPhone,
    'ownerId': ownerId,
    'isUserListed': isUserListed,
  };

  factory _AdoptionCandidate.fromJson(Map<String, dynamic> j) => _AdoptionCandidate(
    id: j['id'] as String,
    name: j['name'] as String,
    age: j['age'] as String,
    species: j['species'] as String,
    breed: j['breed'] as String,
    matchScore: (j['matchScore'] as num?)?.toInt() ?? 90,
    shelter: j['shelter'] as String,
    distance: j['distance'] as String,
    imageUrl: j['imageUrl'] as String,
    personality: List<String>.from(j['personality'] as List),
    description: j['description'] as String,
    contactPhone: j['contactPhone'] as String?,
    ownerId: j['ownerId'] as String?,
    isUserListed: j['isUserListed'] as bool? ?? false,
  );
}
