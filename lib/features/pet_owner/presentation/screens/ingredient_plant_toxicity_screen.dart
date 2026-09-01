import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:petconnect_ai/core/theme/tokens/app_breakpoints.dart';
import 'package:petconnect_ai/core/theme/tokens/app_radius.dart';
import 'package:petconnect_ai/core/theme/tokens/app_spacing.dart';
import 'package:petconnect_ai/core/theme/tokens/app_typography.dart';
import 'package:petconnect_ai/core/utils/extensions/context_extensions.dart';
import 'package:petconnect_ai/router/route_paths.dart';

enum ToxicityLevel { safe, caution, toxic }

enum ToxicityCategory { all, foods, plants, medications, chemicals }

class ToxicityItem {
  const ToxicityItem({
    required this.id,
    required this.name,
    required this.level,
    required this.category,
    required this.targetSpecies,
    required this.summary,
    required this.symptoms,
    required this.firstAid,
    this.scientificMechanism,
  });

  final String id;
  final String name;
  final ToxicityLevel level;
  final ToxicityCategory category;
  final String targetSpecies;
  final String summary;
  final String symptoms;
  final String firstAid;
  final String? scientificMechanism;
}

class IngredientPlantToxicityScreen extends ConsumerStatefulWidget {
  const IngredientPlantToxicityScreen({super.key});

  @override
  ConsumerState<IngredientPlantToxicityScreen> createState() =>
      _IngredientPlantToxicityScreenState();
}

class _IngredientPlantToxicityScreenState
    extends ConsumerState<IngredientPlantToxicityScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  ToxicityCategory _selectedCategory = ToxicityCategory.all;
  ToxicityLevel? _selectedLevel;
  String _searchQuery = '';

  static const List<ToxicityItem> _items = [
    // ══════════════════════════════════════════════════════════════════════════
    // 1. FOODS & BEVERAGES (30 items)
    // ══════════════════════════════════════════════════════════════════════════
    ToxicityItem(
      id: 'chocolate',
      name: 'Chocolate / Cocoa / Theobromine',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains theobromine and caffeine. Dark chocolate and baking cocoa are extremely hazardous.',
      symptoms: 'Vomiting, diarrhea, tachycardia (rapid heart rate), muscle tremors, seizures, cardiac arrhythmias.',
      firstAid: 'Calculate grams consumed and cocoa percentage. Seek immediate emergency veterinary decontamination.',
      scientificMechanism: 'Methylxanthines inhibit cellular phosphodiesterase and block adenosine receptors, overstimulating cardiac and CNS pathways.',
    ),
    ToxicityItem(
      id: 'xylitol',
      name: 'Xylitol / Birch Sweetener',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs (Severe / Fatal)',
      summary: 'Common in sugar-free gum, peanut butter, and baked goods. Triggers massive rapid insulin release.',
      symptoms: 'Severe hypoglycemia (ataxia, collapse, seizures) within 30-60 mins, acute hepatic necrosis within 24-48 hours.',
      firstAid: 'CRITICAL EMERGENCY! Transport to emergency clinic immediately for IV dextrose infusion and liver support.',
      scientificMechanism: 'Canine pancreas confuses xylitol with glucose, stimulating an 8x greater insulin release than regular sugar.',
    ),
    ToxicityItem(
      id: 'grapes',
      name: 'Grapes, Raisins & Sultanas',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Causes acute nephrotoxicity (kidney failure) even in very small quantities.',
      symptoms: 'Vomiting, lethargy, anorexia, abdominal pain, oliguria/anuria (reduced/absent urine output).',
      firstAid: 'Urgent veterinary decontamination within 2 hours. Do not wait for kidney shutdown symptoms to emerge.',
      scientificMechanism: 'Tartaric acid and potassium bitartrate in grapes cause acute tubular epithelial cell necrosis in kidneys.',
    ),
    ToxicityItem(
      id: 'onions_garlic',
      name: 'Onions, Garlic, Leeks & Chives',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats (Cats High Risk)',
      summary: 'Allium species destroy red blood cells, causing oxidative Heinz body hemolytic anemia.',
      symptoms: 'Pale mucous membranes, red/brown urine, lethargy, elevated heart rate, collapse.',
      firstAid: 'Veterinary supportive care, blood oxygenation monitoring, and potential blood transfusions.',
      scientificMechanism: 'N-propyl disulfide oxidizes hemoglobin sulfhydryl groups, precipitating hemoglobin inside red blood cells.',
    ),
    ToxicityItem(
      id: 'macadamia',
      name: 'Macadamia Nuts',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs',
      summary: 'Unique canine toxicity causing temporary neuromuscular paralysis and hyperthermia.',
      symptoms: 'Hind-limb weakness, ataxia, muscle tremors, hyperthermia, vomiting.',
      firstAid: 'Veterinary observation, fluid diuresis, and muscle relaxation support.',
    ),
    ToxicityItem(
      id: 'alcohol',
      name: 'Alcohol / Ethanol / Hops',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'All Pets',
      summary: 'Small amounts of beer, liquor, or fermenting yeast cause severe central nervous system depression.',
      symptoms: 'Ataxia, vomiting, severe hypothermia, metabolic acidosis, respiratory depression, coma.',
      firstAid: 'Emergency warming, IV fluids, and respiratory stabilization at a veterinary facility.',
    ),
    ToxicityItem(
      id: 'caffeine',
      name: 'Caffeine / Coffee Beans / Energy Drinks',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs, Cats, Birds',
      summary: 'Concentrated caffeine stimulates central nervous and cardiovascular systems dangerously.',
      symptoms: 'Restlessness, hyperthermia, rapid breathing, palpitations, hypertension, seizures.',
      firstAid: 'Emergency decontamination, sedatives, beta-blockers, and close ECG monitoring.',
    ),
    ToxicityItem(
      id: 'yeast_dough',
      name: 'Raw Bread Yeast Dough',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Expands inside warm stomach causing gastric dilation volvulus (bloat) while producing ethanol.',
      symptoms: 'Distended painful abdomen, dry heaving, alcohol intoxication, hypothermia, shock.',
      firstAid: 'Emergency cold water gastric lavage or surgical decompression for severe bloat.',
    ),
    ToxicityItem(
      id: 'cooked_bones',
      name: 'Cooked Bones (Chicken, Beef, Pork)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Cooked bones become brittle and splinter into razor-sharp shards in the gastrointestinal tract.',
      symptoms: 'Choking, mouth bleeding, vomiting, constipation, peritonitis from intestinal perforation.',
      firstAid: 'Do NOT induce vomiting. Feed high-fiber bread/pumpkin to cushion shards and consult vet.',
    ),
    ToxicityItem(
      id: 'avocado',
      name: 'Avocado (Pit, Skin & Leaves)',
      level: ToxicityLevel.caution,
      category: ToxicityCategory.foods,
      targetSpecies: 'Birds (Fatal), Dogs & Cats (Moderate)',
      summary: 'Contains persin. Flesh causes mild pancreatitis in dogs/cats, but pit is severe choking/blockage hazard. Highly toxic to birds.',
      symptoms: 'Birds: Respiratory distress, pericardial effusion. Dogs: Vomiting, diarrhea, intestinal blockage from pit.',
      firstAid: 'Keep birds completely away. For dogs swallowing pits, seek urgent surgical/endoscopic retrieval.',
    ),
    ToxicityItem(
      id: 'cherries_pits',
      name: 'Cherries, Peach & Plum Pits',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Pits and foliage contain amygdalin, which breaks down into toxic cyanide when chewed.',
      symptoms: 'Bright brick-red gums, dilated pupils, difficulty breathing, convulsions, sudden collapse.',
      firstAid: 'Immediate veterinary emergency care. Specific cyanide antidotes (hydroxocobalamin) may be required.',
    ),
    ToxicityItem(
      id: 'raw_potatoes',
      name: 'Green Potatoes & Unripe Tomatoes',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains solanine, a toxic glycoalkaloid found in green skins, stems, and unripened nightshades.',
      symptoms: 'Severe gastrointestinal distress, cardiac arrhythmias, confusion, drooling, lethargy.',
      firstAid: 'Veterinary supportive therapy and activated charcoal administration.',
    ),
    ToxicityItem(
      id: 'salt_excess',
      name: 'Table Salt / Play Dough (Excess Sodium)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Consuming large amounts of salt or homemade salt dough triggers severe hypernatremia.',
      symptoms: 'Extreme thirst, vomiting, diarrhea, cerebral edema, muscle spasticity, seizures.',
      firstAid: 'Carefully monitored, slow IV fluid therapy to normalize sodium levels without brain injury.',
    ),
    ToxicityItem(
      id: 'moldy_food',
      name: 'Moldy Food / Compost (Tremorgenic Mycotoxins)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Penicillium molds in garbage, bread, and compost produce potent neurotoxic mycotoxins.',
      symptoms: 'Violent muscle tremors ("garbage gut"), panting, hyperactivity, hyperthermia, seizures.',
      firstAid: 'Emergency decontamination, muscle relaxants (methocarbamol), and sedation.',
    ),
    ToxicityItem(
      id: 'nutmeg',
      name: 'Nutmeg & Spices',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains myristicin, a psychoactive compound that overexcites the central nervous system.',
      symptoms: 'Hallucinations, disorientation, rapid heart rate, dry mouth, abdominal pain, seizures.',
      firstAid: 'Keep pet in a quiet, dark room and seek immediate veterinary evaluation.',
    ),
    ToxicityItem(
      id: 'apple_seeds',
      name: 'Apple Seeds (Large Quantities)',
      level: ToxicityLevel.caution,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Apple slices are safe, but core seeds contain trace amounts of cyanogenic glycosides.',
      symptoms: 'Safe in tiny amounts, but eating whole cores or hundreds of crushed seeds causes cyanide toxicity.',
      firstAid: 'Feed only seeded apple slices without the core and seeds.',
    ),
    ToxicityItem(
      id: 'dairy_milk',
      name: 'Cow Milk & Heavy Dairy (Lactose)',
      level: ToxicityLevel.caution,
      category: ToxicityCategory.foods,
      targetSpecies: 'Adult Dogs & Cats',
      summary: 'Most adult pets lack the lactase enzyme needed to digest lactose in cow milk.',
      symptoms: 'Bloating, flatulence, loose watery diarrhea, abdominal cramping.',
      firstAid: 'Switch to plain lactose-free yogurt or fresh water. Fast for 6-8 hours if diarrhea occurs.',
    ),
    ToxicityItem(
      id: 'fatty_trimmings',
      name: 'Bacon Grease & Fatty Meat Trimmings',
      level: ToxicityLevel.caution,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'High fat concentration overworks the pancreas, triggering acute inflammatory pancreatitis.',
      symptoms: 'Severe abdominal pain (prayer position), repetitive vomiting, fever, dehydration.',
      firstAid: 'Immediate hospitalization, IV fluids, pain management, and bland diet transition.',
    ),
    // Safe Foods
    ToxicityItem(
      id: 'peanut_butter',
      name: 'Natural Peanut Butter (Xylitol-Free)',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'High in protein, niacin, and healthy fats. Safe in moderation as an occasional treat.',
      symptoms: 'Safe and beneficial. Always inspect ingredient label to verify zero xylitol/birch sweetener.',
      firstAid: 'Feed 1-2 teaspoons for small dogs, up to 1 tablespoon for large dogs.',
    ),
    ToxicityItem(
      id: 'pumpkin',
      name: 'Pure Pumpkin Puree (100% Canned)',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Outstanding source of soluble prebiotic fiber for soothing diarrhea and relieving constipation.',
      symptoms: 'Safe and highly therapeutic for gastrointestinal regularity.',
      firstAid: 'Use 100% pure pumpkin, NOT spiced pumpkin pie mix with nutmeg.',
    ),
    ToxicityItem(
      id: 'cooked_chicken',
      name: 'Plain Boiled Chicken (Boneless & Skinless)',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Bland, highly digestible lean protein source ideal for recovery from stomach upset.',
      symptoms: 'Safe. Prepared without oils, onions, garlic, or table salt.',
      firstAid: 'Feed 2:1 ratio with cooked white rice during gastrointestinal recovery.',
    ),
    ToxicityItem(
      id: 'carrots',
      name: 'Raw or Steamed Carrots',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Low-calorie crunchy treat loaded with beta-carotene, Vitamin A, and beneficial dietary fiber.',
      symptoms: 'Safe. Chewing raw carrots also supports mechanical plaque reduction on teeth.',
      firstAid: 'Cut into bite-sized coins for small dogs to prevent choking.',
    ),
    ToxicityItem(
      id: 'blueberries',
      name: 'Fresh or Frozen Blueberries',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Superfood packed with antioxidants (anthocyanins), Vitamin C, and fiber for cellular health.',
      symptoms: 'Safe and healthy training treat. Supports cognitive health in senior pets.',
      firstAid: 'Feed 2-6 berries daily depending on companion body weight.',
    ),
    ToxicityItem(
      id: 'white_rice',
      name: 'Cooked Plain White Rice',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Easily digestible carbohydrate that binds loose stool and provides gentle energy.',
      symptoms: 'Safe baseline staple for veterinary bland recovery diets.',
      firstAid: 'Boil in plain water without added butter, oil, or seasonings.',
    ),
    ToxicityItem(
      id: 'cooked_salmon',
      name: 'Cooked Salmon & Fish (Boneless)',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Rich in anti-inflammatory Omega-3 fatty acids (EPA/DHA) for skin, coat, and joint health.',
      symptoms: 'Safe when thoroughly cooked. Never feed raw salmon due to Neorickettsia fluke parasites.',
      firstAid: 'De-bone thoroughly before serving plain without butter or seasonings.',
    ),
    ToxicityItem(
      id: 'green_beans',
      name: 'Fresh or Steamed Green Beans',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Low-calorie, filling vegetable rich in iron, calcium, and Vitamin K. Great for weight loss.',
      symptoms: 'Safe. Often used by vets to replace 10% of kibble volume for weight management.',
      firstAid: 'Serve plain without added salt or butter.',
    ),
    ToxicityItem(
      id: 'watermelon',
      name: 'Seedless Watermelon (Rind Removed)',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: '92% water content provides refreshing summer hydration along with potassium and Vitamin A.',
      symptoms: 'Safe in moderation. Remove all hard black seeds and tough green outer rind.',
      firstAid: 'Serve chilled chunks on hot days for natural hydration.',
    ),
    ToxicityItem(
      id: 'greek_yogurt',
      name: 'Plain Unsweetened Greek Yogurt',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Naturally lower in lactose than milk, providing probiotics and bioavailable calcium.',
      symptoms: 'Safe in small quantities (1 spoonful). Check label to ensure zero xylitol or artificial sweeteners.',
      firstAid: 'Do not feed if your pet has a diagnosed dairy or bovine protein allergy.',
    ),
    ToxicityItem(
      id: 'oatmeal',
      name: 'Plain Cooked Oatmeal',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Great source of soluble fiber and linoleic acid for pets with sensitive digestive tracts.',
      symptoms: 'Safe when cooked in plain water without milk, sugar, or raisins.',
      firstAid: 'Cool completely before serving 1-2 tablespoons.',
    ),
    ToxicityItem(
      id: 'sweet_potatoes',
      name: 'Cooked Sweet Potatoes (Dehydrated or Steamed)',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.foods,
      targetSpecies: 'Dogs & Cats',
      summary: 'Nutrient-dense root vegetable rich in dietary fiber, Vitamin B6, and potassium.',
      symptoms: 'Safe when cooked thoroughly. Never feed raw sweet potatoes.',
      firstAid: 'Serve steamed or baked without butter, brown sugar, or marshmallows.',
    ),

    // ══════════════════════════════════════════════════════════════════════════
    // 2. PLANTS & BOTANICALS (16 items)
    // ══════════════════════════════════════════════════════════════════════════
    ToxicityItem(
      id: 'lilies',
      name: 'True Lilies (Easter, Tiger, Stargazer, Daylily)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.plants,
      targetSpecies: 'Cats (FATAL) & Dogs (Mild GI)',
      summary: 'All parts of true lilies (leaves, petals, pollen, vase water) are violently lethal to cats.',
      symptoms: 'Cats: Vomiting, salivation, acute kidney tubular necrosis within 24-72 hours, anuria, death.',
      firstAid: 'ABSOLUTE EMERGENCY! Wipe pollen immediately and rush cat to emergency ICU for aggressive IV fluid diuresis.',
      scientificMechanism: 'Unknown water-soluble phytotoxin causes rapid mitochondrial necrosis in feline renal cortical tubular cells.',
    ),
    ToxicityItem(
      id: 'sago_palm',
      name: 'Sago Palm (Cycas Revoluta)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats (50% Mortality)',
      summary: 'Every part of this ornamental cycad contains cycasin. Seeds contain the highest lethal concentration.',
      symptoms: 'Severe vomiting, black tarry stool (melena), jaundice, hepatic cirrhosis, coagulopathy, seizures.',
      firstAid: 'Immediate emergency decontamination, repeated activated charcoal, and intensive hepatoprotective therapy.',
    ),
    ToxicityItem(
      id: 'oleander',
      name: 'Oleander (Nerium Oleander)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.plants,
      targetSpecies: 'All Pets (Fatal)',
      summary: 'Contains potent cardiac glycosides (oleandrin) that cause life-threatening arrhythmias and cardiac arrest.',
      symptoms: 'Drooling, bloody diarrhea, bradycardia (slow heart rate), severe arrhythmias, collapse, sudden death.',
      firstAid: 'Critical emergency! Digoxin-specific Fab antibodies and antiarrhythmic therapy required.',
    ),
    ToxicityItem(
      id: 'monstera',
      name: 'Monstera Deliciosa (Swiss Cheese Plant)',
      level: ToxicityLevel.caution,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains microscopic needle-like insoluble calcium oxalate crystals (raphides).',
      symptoms: 'Intense oral pain, burning of lips and tongue, excessive drooling, difficulty swallowing.',
      firstAid: 'Rinse mouth with cold water, offer milk or yogurt to bind crystals. Seek vet if airway swells.',
    ),
    ToxicityItem(
      id: 'aloe_vera',
      name: 'Aloe Vera (Outer Rind & Yellow Latex)',
      level: ToxicityLevel.caution,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'The clear inner gel is benign, but the green rind and yellow latex contain toxic anthraquinones and saponins.',
      symptoms: 'Vomiting, diarrhea, lethargy, muscle tremors, red/brown urine discoloration.',
      firstAid: 'Wash skin if applied topically; provide gastrointestinal protectants if ingested.',
    ),
    ToxicityItem(
      id: 'snake_plant',
      name: 'Snake Plant / Mother-in-Law Tongue (Sansevieria)',
      level: ToxicityLevel.caution,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Contains saponins that cause gastrointestinal irritation and bitter hemolytic reactions.',
      symptoms: 'Excessive salivation, nausea, vomiting, diarrhea, loss of appetite.',
      firstAid: 'Offer fresh water, withhold food for 4-6 hours, and consult veterinarian if vomiting persists.',
    ),
    ToxicityItem(
      id: 'pothos',
      name: 'Pothos / Devil Ivy (Epipremnum Aureum)',
      level: ToxicityLevel.caution,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Extremely common houseplant with insoluble calcium oxalates that irritate oral mucous membranes.',
      symptoms: 'Pawings at the mouth, drooling, vocalizing in discomfort, vomiting.',
      firstAid: 'Flush oral cavity with cool water. Give a small spoon of tuna juice or yogurt.',
    ),
    ToxicityItem(
      id: 'dieffenbachia',
      name: 'Dieffenbachia (Dumb Cane)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'High concentration of calcium oxalates combined with proteolytic enzymes causes severe oral edema.',
      symptoms: 'Temporary loss of vocalization, intense airway/tongue swelling, severe choking, drooling.',
      firstAid: 'Urgent vet visit if pet shows difficulty breathing or swallowing.',
    ),
    ToxicityItem(
      id: 'tulips',
      name: 'Tulips & Daffodils (Bulbs)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Bulbs contain concentrated allergenics (tulipalin A/B and lycorine alkaloid) that cause toxic GI damage.',
      symptoms: 'Profuse vomiting, diarrhea, tremors, cardiac arrhythmias, hypotension.',
      firstAid: 'Prevent digging in flower beds. Seek vet care for fluid support if bulbs were chewed.',
    ),
    ToxicityItem(
      id: 'azalea',
      name: 'Azaleas & Rhododendrons',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs, Cats, Horses',
      summary: 'Contains grayanotoxins that disrupt cellular sodium channels throughout cardiac and skeletal muscles.',
      symptoms: 'Excessive drooling, vomiting, abdominal pain, severe hypotension, coma, cardiovascular collapse.',
      firstAid: 'Emergency decontamination, IV fluid therapy, and continuous ECG monitoring.',
    ),
    ToxicityItem(
      id: 'cannabis',
      name: 'Marijuana / THC / Cannabis Edibles',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs (High Sensitivity) & Cats',
      summary: 'Dogs have a higher density of cannabinoid receptors in the cerebellum, making THC severely toxic.',
      symptoms: 'Ataxia, urinary incontinence (leaking urine), hyperesthesia (flinching to touch), bradycardia, hypothermia.',
      firstAid: 'Keep pet in a dim quiet room, prevent hypothermia with blankets, and seek veterinary supportive care.',
    ),
    ToxicityItem(
      id: 'poinsettia',
      name: 'Poinsettia (Euphorbia Pulcherrima)',
      level: ToxicityLevel.caution,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Milky sap contains diterpenoid euphorbol esters. Mildly irritating despite historical rumors of fatality.',
      symptoms: 'Mild drooling, localized skin redness, occasional vomiting.',
      firstAid: 'Rinse fur/mouth with water. Symptoms typically resolve without emergency interventions.',
    ),
    // Safe Plants
    ToxicityItem(
      id: 'spider_plant',
      name: 'Spider Plant (Chlorophytum Comosum)',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: '100% non-toxic to household pets. Mildly hallucinogenic/playful effect in some curious felines.',
      symptoms: 'Safe. Overeating may cause minor transient stomach upset.',
      firstAid: 'Safe houseplant. Keep hung high if cats chew on dangling runners.',
    ),
    ToxicityItem(
      id: 'boston_fern',
      name: 'Boston Fern (Nephrolepis Exaltata)',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Lush, pet-safe fern that purifies indoor air without toxic alkaloids or oxalates.',
      symptoms: 'Completely non-toxic to companion animals.',
      firstAid: 'Safe to keep on floor stands or hanging baskets.',
    ),
    ToxicityItem(
      id: 'areca_palm',
      name: 'Areca / Butterfly Palm (Dypsis Lutescens)',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Safe, non-toxic tropical palm alternative to the lethal Sago Palm.',
      symptoms: 'Completely non-toxic. Excellent pet-friendly home decor option.',
      firstAid: 'Safe for all indoor pet households.',
    ),
    ToxicityItem(
      id: 'calathea',
      name: 'Calathea & Maranta (Prayer Plants)',
      level: ToxicityLevel.safe,
      category: ToxicityCategory.plants,
      targetSpecies: 'Dogs & Cats',
      summary: 'Striking patterned indoor plants completely free of oxalates and toxins.',
      symptoms: 'Completely safe for curious chewers.',
      firstAid: 'Safe indoor botanical companion.',
    ),

    // ══════════════════════════════════════════════════════════════════════════
    // 3. MEDICATIONS & PHARMACEUTICALS (12 items)
    // ══════════════════════════════════════════════════════════════════════════
    ToxicityItem(
      id: 'paracetamol',
      name: 'Paracetamol / Acetaminophen / Tylenol',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.medications,
      targetSpecies: 'Cats (FATAL) & Dogs (Severe)',
      summary: 'Cats lack glucuronyl transferase. Converts hemoglobin into methemoglobin which cannot carry oxygen.',
      symptoms: 'Cyanosis (brownish/muddy gums), severe facial edema, hypothermia, acute liver necrosis, death.',
      firstAid: 'CRITICAL EMERGENCY! Administer N-acetylcysteine (NAC) antidote and oxygen therapy immediately.',
      scientificMechanism: 'Toxic metabolite NAPQI causes massive oxidative damage to erythrocytes and hepatocytes.',
    ),
    ToxicityItem(
      id: 'ibuprofen',
      name: 'Ibuprofen / Advil / Motrin / NSAIDs',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.medications,
      targetSpecies: 'Dogs & Cats',
      summary: 'Human NSAIDs inhibit protective prostaglandins, destroying gastric mucosal barrier and renal blood flow.',
      symptoms: 'Gastric ulceration, vomiting blood (hematemesis), black tarry stools, acute kidney shutdown, seizures.',
      firstAid: 'Emergency decontamination, IV fluid diuresis, proton pump inhibitors, and misoprostol therapy.',
    ),
    ToxicityItem(
      id: 'aspirin',
      name: 'Aspirin (Acetylsalicylic Acid)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.medications,
      targetSpecies: 'Cats (High Risk) & Dogs',
      summary: 'Cats eliminate salicylates very slowly (half-life of 38-45 hours compared to 8 hours in dogs).',
      symptoms: 'Fever, rapid breathing, metabolic acidosis, gastrointestinal ulceration, liver injury.',
      firstAid: 'Decontamination, IV fluid therapy with sodium bicarbonate to promote urinary excretion.',
    ),
    ToxicityItem(
      id: 'adderall',
      name: 'ADHD Meds / Amphetamines / Adderall',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.medications,
      targetSpecies: 'Dogs & Cats',
      summary: 'Central nervous system stimulants cause life-threatening sympathomimetic toxidromes.',
      symptoms: 'Extreme agitation, pacing, dilated pupils, severe hypertension, hyperthermia, seizures.',
      firstAid: 'Urgent hospitalization, acepromazine/phenothiazine sedation, and active body cooling.',
    ),
    ToxicityItem(
      id: 'antidepressants',
      name: 'Antidepressants (SSRIs / Prozac / Zoloft)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.medications,
      targetSpecies: 'Dogs & Cats',
      summary: 'High doses cause life-threatening Serotonin Syndrome in companion animals.',
      symptoms: 'Lethargy or severe agitation, tremors, hyperthermia, vomiting, seizures, vocalization.',
      firstAid: 'Emergency decontamination, cyproheptadine (serotonin antagonist), and muscle relaxants.',
    ),
    ToxicityItem(
      id: 'blood_pressure',
      name: 'Blood Pressure Meds (Beta-Blockers / ACE Inhibitors)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.medications,
      targetSpecies: 'Dogs & Cats',
      summary: 'Overdoses cause severe cardiovascular collapse and organ hypoperfusion.',
      symptoms: 'Extreme lethargy, profound bradycardia (slow heart rate), weakness, collapse, hypothermia.',
      firstAid: 'Emergency IV fluids, glucagon, calcium gluconate, and high-dose insulin euglycemia therapy.',
    ),
    ToxicityItem(
      id: 'decongestants',
      name: 'Pseudoephedrine (Cold & Sinus Decongestants)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.medications,
      targetSpecies: 'Dogs & Cats',
      summary: 'Potent sympathomimetic compound found in Sudafed and multisymptom cold remedies.',
      symptoms: 'Severe restlessness, hyperactivity, tachycardia, hypertension, hyperthermia, seizures.',
      firstAid: 'Urgent hospitalization, sedation, cooling measures, and cardiac monitoring.',
    ),
    ToxicityItem(
      id: 'vitamin_d',
      name: 'Vitamin D3 Supplements / Cholecalciferol',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.medications,
      targetSpecies: 'Dogs & Cats',
      summary: 'Cholecalciferol triggers severe hypercalcemia and widespread tissue mineralization.',
      symptoms: 'Excessive thirst and urination, vomiting, lethargy, acute kidney failure, soft tissue calcification.',
      firstAid: 'Aggressive saline diuresis, furosemide, steroids, and bisphosphonate (pamidronate) therapy.',
    ),
    ToxicityItem(
      id: 'iron_supplements',
      name: 'Iron Supplements / Prenatal Vitamins',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.medications,
      targetSpecies: 'Dogs & Cats',
      summary: 'Free iron generates destructive hydroxyl free radicals that corrode the GI mucosa and liver.',
      symptoms: 'Severe bloody vomiting, diarrhea, metabolic acidosis, liver failure 48 hours later.',
      firstAid: 'Emergency gastric lavage and deferoxamine chelation therapy at specialized ICU.',
    ),
    ToxicityItem(
      id: 'benzodiazepines',
      name: 'Sleeping Pills (Xanax / Valium / Ambien)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.medications,
      targetSpecies: 'Dogs & Cats',
      summary: 'While sometimes used clinically under veterinary supervision, human doses cause profound CNS depression or paradoxical aggression.',
      symptoms: 'Severe ataxia, profound sedation, disorientation, respiratory depression or hyperactivity.',
      firstAid: 'Supportive care, IV fluids, and flumazenil antidote if life-threatening depression occurs.',
    ),

    // ══════════════════════════════════════════════════════════════════════════
    // 4. HOUSEHOLD CHEMICALS & TOXINS (10 items)
    // ══════════════════════════════════════════════════════════════════════════
    ToxicityItem(
      id: 'antifreeze',
      name: 'Ethylene Glycol (Automotive Engine Antifreeze)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.chemicals,
      targetSpecies: 'Dogs & Cats (FATAL)',
      summary: 'Sweet-tasting, highly lethal coolant. As little as 1 teaspoon is fatal to a cat.',
      symptoms: 'Stage 1 (1-6h): Drunken ataxia, vomiting. Stage 2 (12-24h): Tachypnea. Stage 3 (24-72h): Acute irreversible renal shutdown.',
      firstAid: 'CRITICAL EMERGENCY! Fomepizole (4-MP) or ethanol antidote must be given within 3-8 hours before kidney crystallization occurs.',
      scientificMechanism: 'Hepatic alcohol dehydrogenase oxidizes ethylene glycol into glycolic and oxalic acids, forming calcium oxalate monohydrate crystals in renal tubules.',
    ),
    ToxicityItem(
      id: 'rodenticides',
      name: 'Rat Poison / Rodenticides (Anticoagulant & Bromethalin)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.chemicals,
      targetSpecies: 'Dogs & Cats (Fatal)',
      summary: 'Anticoagulants block Vitamin K recycling; Bromethalin causes cerebral edema and neurological paralysis.',
      symptoms: 'Lethargy, coughing blood, nosebleeds, bruising (petechiae), hindlimb paralysis, seizures.',
      firstAid: 'Bring the exact poison packaging to the vet! Anticoagulant requires 30 days of oral Vitamin K1.',
    ),
    ToxicityItem(
      id: 'permethrin',
      name: 'Permethrin / Spot-On Dog Flea Meds on Cats',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.chemicals,
      targetSpecies: 'Cats (FATAL Danger)',
      summary: 'Synthetic pyrethroid safe for dogs but highly neurotoxic to cats due to deficient liver glucuronidation.',
      symptoms: 'Severe muscle tremors, ear twitching, salivation, hyperthermia, violent seizures, death.',
      firstAid: 'CRITICAL EMERGENCY! Bathe cat in warm water with Dawn dish soap immediately and rush to clinic for methocarbamol and IV lipid emulsion.',
    ),
    ToxicityItem(
      id: 'bleach',
      name: 'Chlorine Bleach & Corrosive Cleaners',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.chemicals,
      targetSpecies: 'All Pets',
      summary: 'Strong alkaline or acidic household cleaners cause severe chemical burns to oral and esophageal tissues.',
      symptoms: 'Severe drooling, oral ulcers, pawing at mouth, gagging, difficulty breathing, vomiting.',
      firstAid: 'Do NOT induce vomiting (will burn esophagus a second time). Flush mouth with water and give small sips of water/milk.',
    ),
    ToxicityItem(
      id: 'essential_oils',
      name: 'Essential Oils (Tea Tree, Eucalyptus, Pennyroyal)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.chemicals,
      targetSpecies: 'Cats & Dogs',
      summary: 'Concentrated terpenes and phenols are rapidly absorbed through skin/respiratory tract and stress the liver.',
      symptoms: 'Unsteadiness, drooling, low body temperature, respiratory distress, acute liver failure.',
      firstAid: 'Wash skin with mild liquid dish soap; ventilate room and seek veterinary care.',
    ),
    ToxicityItem(
      id: 'snail_bait',
      name: 'Slug & Snail Bait (Metaldehyde)',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.chemicals,
      targetSpecies: 'Dogs & Cats',
      summary: 'Extremely palatable pellets containing metaldehyde trigger severe CNS excitation ("shake and bake" syndrome).',
      symptoms: 'Rapid onset of violent muscle spasms, severe hyperthermia (>106°F), continuous seizures, respiratory arrest.',
      firstAid: 'Critical emergency! Immediate gastric lavage under general anesthesia, active cooling, and anticonvulsant therapy.',
    ),
    ToxicityItem(
      id: 'button_batteries',
      name: 'Button Batteries & Disc Batteries',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.chemicals,
      targetSpecies: 'Dogs & Cats',
      summary: 'When lodged in the esophagus, electrical current hydrolyzes tissue fluids into caustic sodium hydroxide within 2 hours.',
      symptoms: 'Difficulty swallowing, drooling, vomiting, black stool, severe esophageal perforation.',
      firstAid: 'Do NOT induce vomiting. Rush to emergency clinic for urgent endoscopic removal.',
    ),
    ToxicityItem(
      id: 'laundry_pods',
      name: 'Laundry Detergent Pods',
      level: ToxicityLevel.toxic,
      category: ToxicityCategory.chemicals,
      targetSpecies: 'Dogs & Cats',
      summary: 'Highly concentrated anionic/cationic surfactants under pressure burst into the oral cavity and airway.',
      symptoms: 'Severe coughing, frothing at the mouth, chemical aspiration pneumonitis, corneal burns if in eyes.',
      firstAid: 'Rinse mouth and eyes with copious lukewarm water. Seek veterinary care for lung evaluation.',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ToxicityItem> get _filteredItems {
    return _items.where((item) {
      final matchesCategory = _selectedCategory == ToxicityCategory.all ||
          item.category == _selectedCategory;
      final matchesLevel =
          _selectedLevel == null || item.level == _selectedLevel;
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.summary.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.symptoms.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.targetSpecies.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesLevel && matchesSearch;
    }).toList();
  }

  void _showItemDetails(ToxicityItem item) {
    HapticFeedback.lightImpact();
    final scheme = context.colorScheme;
    final isToxic = item.level == ToxicityLevel.toxic;
    final isSafe = item.level == ToxicityLevel.safe;

    final badgeColor = isToxic
        ? const Color(0xFFEF4444)
        : (isSafe ? const Color(0xFF10B981) : const Color(0xFFF59E0B));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              AppSpacing.vGapMd,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor, width: 1.2),
                    ),
                    child: Text(
                      isToxic
                          ? 'DANGER / TOXIC'
                          : (isSafe ? 'SAFE & HEALTHY' : 'CAUTION / MODERATE'),
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              AppSpacing.vGapSm,
              Text(
                item.name,
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              AppSpacing.vGapXs,
              Row(
                children: [
                  const Icon(Icons.pets, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Target Species: ${item.targetSpecies}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              AppSpacing.vGapMd,
              _buildDetailSection('Clinical Summary', item.summary, Icons.info_outline),
              AppSpacing.vGapSm,
              _buildDetailSection('Symptoms of Exposure', item.symptoms, Icons.warning_amber_rounded, isWarning: isToxic),
              AppSpacing.vGapSm,
              _buildDetailSection('Immediate First Aid & Protocol', item.firstAid, Icons.medical_services_outlined),
              if (item.scientificMechanism != null) ...[
                AppSpacing.vGapSm,
                _buildDetailSection('Toxicological Mechanism', item.scientificMechanism!, Icons.biotech_rounded),
              ],
              AppSpacing.vGapLg,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push(RoutePaths.ownerAiChat);
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Ask AI Vet'),
                    ),
                  ),
                  if (isToxic) ...[
                    AppSpacing.hGapSm,
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push(RoutePaths.ownerLostMode);
                        },
                        icon: const Icon(Icons.emergency_rounded),
                        label: const Text('Emergency SOS'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon, {bool isWarning = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWarning
            ? const Color(0xFFFEF2F2)
            : context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning
              ? const Color(0xFFFCA5A5)
              : context.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: isWarning ? const Color(0xFFDC2626) : context.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isWarning ? const Color(0xFFDC2626) : context.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: isWarning ? const Color(0xFF7F1D1D) : context.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final filtered = _filteredItems;

    final totalCount = _items.length;
    final toxicCount = _items.where((i) => i.level == ToxicityLevel.toxic).length;
    final cautionCount = _items.where((i) => i.level == ToxicityLevel.caution).length;
    final safeCount = _items.where((i) => i.level == ToxicityLevel.safe).length;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          'Toxicity & Food Safety Hub',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: AppTypography.bold,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Ask AI Veterinarian',
            onPressed: () => context.push(RoutePaths.ownerAiChat),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── STATS SUMMARY BANNER ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primaryContainer.withValues(alpha: 0.7),
                          scheme.secondaryContainer.withValues(alpha: 0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatChip('Total Items', '$totalCount', Icons.dataset_rounded, scheme.primary),
                        _buildStatChip('Dangerous', '$toxicCount', Icons.dangerous_rounded, const Color(0xFFEF4444)),
                        _buildStatChip('Caution', '$cautionCount', Icons.warning_rounded, const Color(0xFFF59E0B)),
                        _buildStatChip('Safe / Healthy', '$safeCount', Icons.check_circle_rounded, const Color(0xFF10B981)),
                      ],
                    ),
                  ),
                  AppSpacing.vGapMd,

                  // ── SEARCH BAR ────────────────────────────────────────────
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search 50+ items (e.g. Chocolate, Lilies, Paracetamol)...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: scheme.surfaceContainerHigh,
                      border: const OutlineInputBorder(
                        borderRadius: AppRadius.brPill,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                  AppSpacing.vGapSm,

                  // ── CATEGORY TABS ─────────────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('All ($totalCount)', ToxicityCategory.all),
                        _buildCategoryChip('Foods & Treats (30)', ToxicityCategory.foods),
                        _buildCategoryChip('Plants & Botanicals (16)', ToxicityCategory.plants),
                        _buildCategoryChip('Medications (10)', ToxicityCategory.medications),
                        _buildCategoryChip('Chemicals (8)', ToxicityCategory.chemicals),
                      ],
                    ),
                  ),
                  AppSpacing.vGapXs,

                  // ── LEVEL FILTER CHIPS ────────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildLevelFilterChip('All Severity', null),
                        _buildLevelFilterChip('Toxic Only', ToxicityLevel.toxic, color: const Color(0xFFEF4444)),
                        _buildLevelFilterChip('Caution Only', ToxicityLevel.caution, color: const Color(0xFFF59E0B)),
                        _buildLevelFilterChip('Safe Only', ToxicityLevel.safe, color: const Color(0xFF10B981)),
                      ],
                    ),
                  ),
                  AppSpacing.vGapMd,

                  // ── ITEMS LIST ────────────────────────────────────────────
                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: scheme.onSurfaceVariant),
                          AppSpacing.vGapSm,
                          Text(
                            'No matching substances found',
                            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          AppSpacing.vGapXs,
                          Text(
                            'Try a different search term or ask our AI assistant directly.',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                          AppSpacing.vGapMd,
                          FilledButton.icon(
                            onPressed: () => context.push(RoutePaths.ownerAiChat),
                            icon: const Icon(Icons.chat),
                            label: const Text('Ask AI Veterinarian'),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildToxicityCard(item);
                      },
                    ),
                  AppSpacing.vGapXl,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String count, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, ToxicityCategory category) {
    final isSelected = _selectedCategory == category;
    final scheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? scheme.onPrimary : scheme.onSurface,
        ),
        selectedColor: scheme.primary,
        backgroundColor: scheme.surfaceContainerHigh,
        showCheckmark: false,
        onSelected: (_) => setState(() => _selectedCategory = category),
      ),
    );
  }

  Widget _buildLevelFilterChip(String label, ToxicityLevel? level, {Color? color}) {
    final isSelected = _selectedLevel == level;
    final scheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (color ?? scheme.onSurfaceVariant),
        ),
        selectedColor: color ?? scheme.primary,
        backgroundColor: (color ?? scheme.surfaceContainerHigh).withValues(alpha: 0.12),
        showCheckmark: false,
        onSelected: (_) => setState(() => _selectedLevel = level),
      ),
    );
  }

  Widget _buildToxicityCard(ToxicityItem item) {
    final scheme = context.colorScheme;
    final isToxic = item.level == ToxicityLevel.toxic;
    final isSafe = item.level == ToxicityLevel.safe;

    final badgeColor = isToxic
        ? const Color(0xFFEF4444)
        : (isSafe ? const Color(0xFF10B981) : const Color(0xFFF59E0B));

    final badgeText = isToxic
        ? 'TOXIC'
        : (isSafe ? 'SAFE' : 'CAUTION');

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: badgeColor, width: 4.5),
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.2)),
          right: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.2)),
          bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showItemDetails(item),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.pets, size: 12, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      item.targetSpecies,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: scheme.onSurface.withValues(alpha: 0.85),
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
