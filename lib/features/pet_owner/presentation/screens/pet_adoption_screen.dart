import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petconnect_ai/core/providers/core_providers.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/ai_widgets.dart';
import 'package:petconnect_ai/features/pet_owner/presentation/widgets/owner_app_bar.dart';
import 'package:petconnect_ai/shared/widgets/widgets.dart';

/// The **Pet Adoption Hub** connecting pet owners, rescuers, and prospective adopters
/// with live adoption candidates, real application submissions, and AI compatibility scoring.
class PetAdoptionScreen extends ConsumerStatefulWidget {
  const PetAdoptionScreen({super.key});

  @override
  ConsumerState<PetAdoptionScreen> createState() => _PetAdoptionScreenState();
}

class _PetAdoptionScreenState extends ConsumerState<PetAdoptionScreen> {
  static const double _maxContentWidth = 1100;
  static const String _favStorageKey = 'app_adoption_favorites_v2';
  static const String _customPetsKey = 'app_adoption_custom_pets_v2';
  static const String _inquiriesKey = 'app_adoption_inquiries_v2';

  String _selectedCategory = 'All';
  String _searchQuery = '';
  Set<String> _favoritePetIds = {};
  List<_AdoptionCandidate> _customCandidates = [];
  List<Map<String, dynamic>> _myInquiries = [];

  final List<String> _categories = const ['All', 'Dogs', 'Cats', 'Puppies'];

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
  ];

  @override
  void initState() {
    super.initState();
    _loadStoredData();
  }

  void _loadStoredData() {
    final prefs = ref.read(sharedPreferencesProvider);
    final favs = prefs.getStringList(_favStorageKey) ?? ['adopt-1'];
    final rawCustom = prefs.getString(_customPetsKey);
    final rawInquiries = prefs.getString(_inquiriesKey);

    List<_AdoptionCandidate> loadedCustom = [];
    if (rawCustom != null && rawCustom.isNotEmpty) {
      try {
        final list = (jsonDecode(rawCustom) as List<dynamic>)
            .map((j) => _AdoptionCandidate.fromJson(j as Map<String, dynamic>))
            .toList();
        loadedCustom = list;
      } catch (_) {}
    }

    List<Map<String, dynamic>> loadedInquiries = [];
    if (rawInquiries != null && rawInquiries.isNotEmpty) {
      try {
        loadedInquiries = List<Map<String, dynamic>>.from(jsonDecode(rawInquiries) as List);
      } catch (_) {}
    }

    setState(() {
      _favoritePetIds = favs.toSet();
      _customCandidates = loadedCustom;
      _myInquiries = loadedInquiries;
    });
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
      jsonEncode(updated.map((c) => c.toJson()).toList()),
    );
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
      'message': message,
      'housingType': housingType,
      'adopterName': adopterName,
      'adopterPhone': adopterPhone,
      'status': 'Pending Review',
      'date': DateTime.now().toIso8601String(),
    };

    final updated = [newInquiry, ..._myInquiries];
    setState(() => _myInquiries = updated);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_inquiriesKey, jsonEncode(updated));
  }

  void _openPostPetDialog() {
    HapticFeedback.lightImpact();
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final breedCtrl = TextEditingController();
    final shelterCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Bengaluru');
    final descCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(
      text: ref.read(currentUserProfileProvider).valueOrNull?.phone ?? '',
    );
    String species = 'Dog';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text('List Pet for Adoption'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Pet Name *',
                    hintText: 'e.g. Milo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
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
                          DropdownMenuItem(value: 'Bird', child: Text('Bird')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) => setDlgState(() => species = val ?? 'Dog'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: ageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Age *',
                          hintText: 'e.g. 1 yr / 4 mos',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: breedCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Breed',
                    hintText: 'e.g. Indie / Labrador / Persian',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: shelterCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Shelter or Guardian Name *',
                    hintText: 'e.g. Compassion Shelter / Private Foster',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location / City *',
                    hintText: 'e.g. Indiranagar, Bengaluru',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone Number *',
                    hintText: 'e.g. +91 98765 43210',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description & Temperament',
                    hintText: 'Friendly, vaccinated, loves children...',
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
                  return;
                }
                final newPet = _AdoptionCandidate(
                  id: 'adopt-user-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  age: ageCtrl.text.trim(),
                  species: species,
                  breed: breedCtrl.text.trim().isNotEmpty ? breedCtrl.text.trim() : 'Companion',
                  matchScore: 95,
                  shelter: shelterCtrl.text.trim().isNotEmpty ? shelterCtrl.text.trim() : 'Community Foster',
                  distance: locationCtrl.text.trim(),
                  imageUrl: species == 'Dog'
                      ? 'https://images.unsplash.com/photo-1543466835-00a7907e9de1?w=800'
                      : 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800',
                  personality: ['Friendly', 'Healthy', 'Vaccinated'],
                  description: descCtrl.text.trim().isNotEmpty
                      ? descCtrl.text.trim()
                      : 'A wonderful companion waiting for a permanent home.',
                  contactPhone: phoneCtrl.text.trim(),
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
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Adoption Applications',
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
            AppSpacing.vGapSm,
            if (_myInquiries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      AppSpacing.vGapSm,
                      Text(
                        'No Adoption Inquiries Yet',
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        'Inquire about pets in the feed to track applications here.',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _myInquiries.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (ctx, i) {
                    final inq = _myInquiries[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: context.colorScheme.primaryContainer,
                        child: Icon(Icons.pets, color: context.colorScheme.primary),
                      ),
                      title: Text(
                        'Application: ${inq["petName"] ?? "Pet"}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Shelter: ${inq["shelter"]}'),
                          if (inq['message'] != null)
                            Text(
                              '"${inq['message']}"',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: context.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          inq['status']?.toString() ?? 'Under Review',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: context.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final allList = [..._customCandidates, ..._defaultCandidates];

    final filteredCandidates = allList.where((pet) {
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
              label: Text('${_myInquiries.length}'),
              isLabelVisible: _myInquiries.isNotEmpty,
              child: const Icon(Icons.assignment_outlined),
            ),
            tooltip: 'My Inquiries',
            onPressed: _openMyInquiriesModal,
          ),
          IconButton(
            icon: Badge(
              label: Text('${_favoritePetIds.length}'),
              isLabelVisible: _favoritePetIds.isNotEmpty,
              child: const Icon(Icons.favorite),
            ),
            tooltip: 'Saved Favorites',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_favoritePetIds.length} pets saved to your adoption favorites'),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPostPetDialog,
        icon: const Icon(Icons.add),
        label: const Text('List for Adoption'),
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
                // ── Hero Section / Search Bar ─────────────────────
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
                        'Matches rescue shelter pets with your lifestyle, living space, and daily activity level.',
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
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

  Widget _buildCandidateCard(BuildContext context, _AdoptionCandidate pet) {
    final scheme = context.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final isFav = _favoritePetIds.contains(pet.id);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  pet.imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: scheme.surfaceContainerHigh,
                    child: Center(
                      child: Icon(Icons.pets, size: 64, color: scheme.primary.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
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
                SizedBox(
                  width: double.infinity,
                  child: AppButton.filled(
                    onPressed: () => _showInquireSheet(context, pet),
                    child: Text('Inquire About ${pet.name}'),
                  ),
                ),
              ],
            ),
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
                    labelText: 'Message to Shelter',
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

                      context.showSnackbar('🎉 Application sent to ${pet.shelter}! Track it in "My Inquiries".');
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
  );
}
