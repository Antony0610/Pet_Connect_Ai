// @ts-nocheck
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

declare const Deno: any;

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const { prompt, conversation_id, pet_id, rag_context, pets, history, gemini_api_key } = await req.json();

    if (!prompt) {
      return new Response(
        JSON.stringify({ error: "Missing prompt" }),
        { status: 400, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const geminiApiKey = gemini_api_key || Deno.env.get("GEMINI_API_KEY") || "";

    // 1. Fetch pet profile context if available
    let petContext = rag_context || "";
    let petList: any[] = Array.isArray(pets) ? pets : [];

    if (supabaseUrl && supabaseServiceKey && pet_id && !petContext) {
      try {
        const supabase = createClient(supabaseUrl, supabaseServiceKey);
        const { data: pet } = await supabase
          .from("pets")
          .select("id, name, species, breed, gender, date_of_birth, weight_kg, health_status, microchip_id")
          .eq("id", pet_id)
          .maybeSingle();

        if (pet) {
          const petName = pet.name || "Companion";
          const petSpecies = pet.species || "Pet";
          const petBreed = pet.breed || petSpecies;
          const petGender = pet.gender || "Not specified";
          const petWeight = pet.weight_kg ? `${pet.weight_kg} kg` : "Not recorded";
          const healthStatus = pet.health_status || "Optimal";

          petContext = `Active Pet Profile: Name: ${petName}, Species: ${petSpecies}, Breed: ${petBreed}, Gender: ${petGender}, Weight: ${petWeight}, Health: ${healthStatus}.`;
        }
      } catch (_e) {
        // Continue without blocking
      }
    }

    let reply = "";

    const clinicalSystemPrompt = `You are PetConnect AI, an intelligent, empathetic, certified veterinary specialist, companion animal scientist, and universal AI assistant.
${petContext ? `[ACTIVE PET CONTEXT]: ${petContext}` : "The user is interacting with PetConnect AI regarding their pets and general inquiries."}

CORE INSTRUCTIONS & CAPABILITIES:
1. UNIVERSAL ANSWERING: Answer ANY question accurately, effectively, and concisely:
   • Clinical Veterinary Medicine, Symptom Triage, First Aid, Pharmacology & Poisoning.
   • WSAVA Animal Nutrition, Safe/Unsafe Foods, Caloric Math, Homemade Diets.
   • Adoption, Rescue, Foster Preparation, Supplies Checklist.
   • Behavioral Psychology, Puppy Biting/Mouthing, Leash Manners, Crate & Potty Routines, Separation Anxiety, Grooming, Travel.
   • Exotic & Avian Care: Birds (PTFE fumes), Rabbits (GI stasis), Reptiles (UVB/MBD), Equine.
   • General Science, Biology, History, Mathematics, Calculations, Technology, Creative Writing, and Multi-language Translation.
2. TONE & CONCISENESS:
   • Give direct, crisp, structured, and actionable answers without conversational filler or disclaimers.
   • For greetings (e.g. "hi", "hello", "നമസ്കാരം"), reply warmly and concisely in 1-2 sentences.
   • For toxic substance questions (e.g. chocolate, lilies, onions), provide immediate toxicity levels, toxic doses (mg/kg), symptoms, and step-by-step first aid.
   • If the user asks in Malayalam (മലയാളം), reply in fluent, natural Malayalam.
   • Never output repetitive generic template disclaimers. Provide direct, evidence-based answers immediately.`;

    // Try Gemini API if key is configured
    if (geminiApiKey) {
      const modelsToTry = [
        "gemini-2.0-flash",
        "gemini-1.5-flash",
        "gemini-1.5-pro",
        "gemini-2.0-flash-exp",
      ];

      const conversationContents = [];
      if (Array.isArray(history) && history.length > 0) {
        for (const h of history) {
          if (h.role && h.parts) conversationContents.push(h);
        }
      }
      conversationContents.push({
        role: "user",
        parts: [{ text: `${clinicalSystemPrompt}\n\nUser Query: ${prompt}` }],
      });

      for (const model of modelsToTry) {
        if (reply) break;
        try {
          const response = await fetch(
            `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiApiKey}`,
            {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                contents: conversationContents,
                generationConfig: {
                  temperature: 0.7,
                  maxOutputTokens: 1500,
                },
              }),
            }
          );

          if (response.ok) {
            const data = await response.json();
            reply = data?.candidates?.[0]?.content?.parts?.[0]?.text || "";
          }
        } catch (_e) {
          // Continue to next model or fallback
        }
      }
    }

    // Comprehensive Dynamic Offline Knowledge Engine
    if (!reply) {
      const lower = prompt.toLowerCase().trim();
      const isMalayalam = /[\u0D00-\u0D7F]/.test(prompt);

      if (isMalayalam) {
        // Malayalam Knowledge Base
        if (/^(നമസ്കാരം|ഹലോ|ഹായ്|സുഖമാണോ|ഗുഡ് മോർണിംഗ്)[!.,? ]*$/.test(prompt) || /നമസ്കാരം|ഹലോ|ഹായ്/.test(prompt)) {
          reply = `നമസ്കാരം! 👋 ഞാൻ നിങ്ങളുടെ PetConnect AI അസിസ്റ്റന്റാണ്. നിങ്ങളുടെ വളർത്തുമൃഗങ്ങളുടെ ആരോഗ്യം, ഭക്ഷണം, പെരുമാറ്റ പരിശീലനം, ദത്തെടുക്കൽ, അല്ലെങ്കിൽ ഏതൊരു ചോദ്യങ്ങൾക്കും ഞാൻ ഇവിടെയുണ്ട്. എനിക്ക് എങ്ങനെ സഹായിക്കാനാകും?`;
        } else if (/ദത്തെടുക്കൽ|പട്ടിയെ ലഭിക്കാൻ|പൂച്ചയെ ലഭിക്കാൻ|എവിടെ നിന്ന് വാങ്ങാം|adopt|adoption/.test(prompt)) {
          reply = `🐶 **വളർത്തുമൃഗങ്ങളെ ദത്തെടുക്കുന്നതിനുള്ള വഴികൾ**:\n\n` +
            `1. **അനിമൽ ഷെൽട്ടറുകൾ & റെസ്ക്യൂ സംഘടനകൾ**: പ്രാദേശിക അനിമൽ റെസ്ക്യൂ സെന്ററുകൾ സന്ദർശിക്കുക.\n` +
            `2. **PetConnect കമ്മ്യൂണിറ്റി അഡോപ്ഷൻ ഹബ്**: ആപ്പിലെ **Community Hub $\\rightarrow$ Adoption** ടാബിൽ പരിശോധിക്കുക.\n` +
            `3. **ആവശ്യമായ മുൻകരുതലുകൾ**: ഭക്ഷണം, പാത്രങ്ങൾ, വാക്സിനേഷൻ രേഖകൾ എന്നിവ മുൻകൂട്ടി തയ്യാറാക്കുക.`;
        } else if (/ചോക്ലേറ്റ്|വിഷം|ഭക്ഷണം|തീറ്റ|എന്ത് നൽകണം/.test(prompt)) {
          reply = `🚨 **ചോക്ലേറ്റ് / ഭക്ഷണ വിഷബാധ വിവരങ്ങൾ**:\n\n` +
            `• ചോക്ലേറ്റിലെ തിയോബ്രോമിൻ (Theobromine) നായ്ക്കൾക്കും പൂച്ചകൾക്കും അതീവ വിഷാംശമുള്ളതാണ്.\n` +
            `• **ലക്ഷണങ്ങൾ**: ഛർദ്ദി, അതിസാരം, അമിത ദാഹം, വിറയൽ, വേഗത്തിലുള്ള ഹൃദയമിടിപ്പ്, അപസ്മാരം.\n` +
            `• **പ്രാഥമിക ശുശ്രൂഷ**: ഉടൻ തന്നെ അടുത്തുള്ള 24/7 വെറ്ററിനറി എമർജൻസി ഹോസ്പിറ്റലിൽ എത്തിക്കുക. സ്വന്തമായി ഛർദ്ദിപ്പിക്കാൻ ശ്രമിക്കരുത്.`;
        } else if (/ഛർദ്ദി|വയറിളക്കം|വയറുവേദന|പനി|അസുഖം/.test(prompt)) {
          reply = `🩺 **രോഗലക്ഷണങ്ങളും പ്രാഥമിക ശുശ്രൂഷയും**:\n\n` +
            `• **ഭക്ഷണം ക്രമീകരിക്കുക**: 8–12 മണിക്കൂർ കട്ടി ആഹാരം ഒഴിവാക്കി ശുദ്ധജലം മാത്രം നൽകുക.\n` +
            `• **ലഘു ഭക്ഷണം**: പിന്നീട് ചെറിയ അളവിൽ വേവിച്ച ചോറും വേവിച്ച ചിക്കനും നൽകുക.\n` +
            `• ഛർദ്ദി തുടരുകയോ ക്ഷീണം കൂടുകയോ ചെയ്താൽ ഉടൻ വെറ്ററിനറി ഡോക്ടറെ കാണിക്കുക.`;
        } else {
          reply = `🐾 **PetConnect AI വിവരങ്ങൾ**:\n\n` +
            `"${prompt}" എന്ന വിഷയത്തെക്കുറിച്ച്:\n\n` +
            `നിങ്ങളുടെ വളർത്തുമൃഗങ്ങളുടെ ആരോഗ്യ സംരക്ഷണത്തിലും പൊതുവിജ്ഞാനത്തിലും ആവശ്യമായ കൃത്യമായ വിവരങ്ങൾ നൽകാൻ ഞാൻ സദാ സന്നദ്ധനാണ്. കൂടുതൽ വിശദമായി ചോദിക്കൂ!`;
        }
      } else {
        // English Universal Knowledge Base

        // 1. Casual Greetings & Pleasantries
        if (/^(hi|hello|hey|greetings|good morning|good afternoon|good evening|howdy|sup|whats up|what's up|hi there|hello there|hola)[!.,? ]*$/i.test(lower)) {
          const names = (petList && petList.length > 0)
            ? petList.map((p: any) => p.name).join(' and ')
            : 'your companions';
          reply = `Hello! 👋 How can I assist you with ${names} today? Feel free to ask about health triage, food toxicology, nutrition calculations, behavior training, or any general questions!`;
        }

        // 2. Specific Chocolate / Cocoa Toxicity Query (Full clinical breakdown)
        else if (/\b(chocolate|cocoa|theobromine|cacao)\b/i.test(lower)) {
          reply = `🍫 **Veterinary Toxicology: Chocolate / Cocoa Safety & Emergency Guide**\n\n` +
            `• **Is Chocolate Safe?**: **NO — Chocolate is strictly toxic to dogs and cats.** It contains methylxanthines (**theobromine** and **caffeine**), which pets metabolize far more slowly than humans.\n\n` +
            `• **Toxic Thresholds & Doses**:\n` +
            `  - **Mild Upset** (vomiting, diarrhea, hyperactivity): **> 20 mg/kg** of theobromine.\n` +
            `  - **Cardiotoxicity** (tachycardia, arrhythmias, high blood pressure): **40–50 mg/kg**.\n` +
            `  - **Severe / Fatal** (muscle tremors, seizures, cardiac arrest): **> 60 mg/kg**.\n` +
            `  *(Note: Baking cocoa and dark chocolate contain 8–10x more theobromine per ounce than milk chocolate, making them life-threatening in very small quantities).*\n\n` +
            `• **Common Symptoms**:\n` +
            `  - Early (2–4 hours): Extreme thirst, pacing, vomiting, diarrhea, bloated stomach.\n` +
            `  - Severe (4–12 hours): Rapid panting, racing heart rate (>180 bpm), muscle spasms, rigidity, seizures.\n\n` +
            `• **Immediate First Aid & Action Steps**:\n` +
            `  1. **Do NOT induce vomiting at home** with salt or hydrogen peroxide unless specifically directed by an emergency veterinarian (high risk of fatal gastric aspiration and caustic gastritis).\n` +
            `  2. **Calculate Ingested Dose**: Note pet weight, chocolate type (milk, dark, cocoa powder), and ounces/grams consumed.\n` +
            `  3. **Emergency Transport**: Head immediately to an emergency veterinary clinic. Clinical decontamination (apomorphine emesis + activated charcoal + IV fluid diuresis) within 2–4 hours carries an excellent prognosis.`;
        }

        // 3. Companion Health Status / Overview
        else if (/\b(how('s| is) (my|the) pet('s)? health|pet('s)? health|how is miavv|how is my dog|how is my cat|health overview|health summary|check my pet)\b/i.test(lower)) {
          const petName = (petList && petList.length > 0) ? petList[0].name : 'your companion';
          const petBreed = (petList && petList.length > 0 && petList[0].breed) ? petList[0].breed : 'pet';
          const petWeight = (petList && petList.length > 0 && petList[0].weight) ? petList[0].weight : 'optimal weight';
          const petStatus = (petList && petList.length > 0 && petList[0].health_status) ? petList[0].health_status : 'Optimal';

          reply = `🩺 **Companion Health Dossier: ${petName}**\n\n` +
            `• **Clinical Status**: ${petStatus}\n` +
            `• **Breed & Weight Profile**: ${petBreed} • ${petWeight}\n` +
            `• **Wellness Highlights**:\n` +
            `  - **Vital Signs**: Alert, active resting posture, optimal hydration markers.\n` +
            `  - **Preventive Care**: Core vaccinations, regular deworming, and quarterly dental checks are recommended.\n` +
            `  - **Nutrition & Calorie Balance**: Ensure daily feeding aligns with resting energy requirements ($RER = 70 \\times BW_{kg}^{0.75}$).\n\n` +
            `Would you like to review specific vaccination records, log new symptoms, or calculate daily caloric targets for ${petName}?`;
        }

        // 4. Toxic Ingestion Emergencies (Xylitol, Grapes, Lilies, Onions, Chemicals)
        else if (/\b(xylitol|birch bark|grape|grapes|raisin|raisins|lily|lilies|onion|onions|garlic|paracetamol|tylenol|ibuprofen|advil|antifreeze|bleach|rat poison|sago palm|weed|marijuana|thc)\b/i.test(lower)) {
          reply = `🚨 **[EMERGENCY TOXICOLOGY TRIAGE]**\n\n` +
            `• **Immediate Veterinary Emergency**: This substance poses acute life-threatening toxicity.\n` +
            `  - **Grapes & Raisins**: Causes acute irreversible renal failure even at tiny doses in canines.\n` +
            `  - **Lilies in Cats**: True lilies (*Lilium* / *Hemerocallis*) cause fatal renal tubular necrosis within 24–72 hours.\n` +
            `  - **Xylitol**: Triggers massive insulin surge causing severe hypoglycemia and acute hepatic necrosis.\n` +
            `  - **Onions & Garlic**: Organosulfoxides destroy red blood cells causing Heinz-body hemolytic anemia.\n\n` +
            `• **Emergency Protocol**:\n` +
            `  1. Do NOT induce vomiting at home.\n` +
            `  2. Keep pet calm and collect the packaging or product name.\n` +
            `  3. Transport immediately to the nearest 24/7 Emergency Animal Hospital.`;
        }

        // 5. Food Safety & WSAVA Nutrition
        else if (/\b(can (dogs|cats|pets) eat|can my dog eat|can my cat eat|safe for dogs|safe for cats|apple|banana|watermelon|blueberry|carrot|pumpkin|egg|rice|chicken|bread|cheese|peanut butter)\b/i.test(lower)) {
          reply = `🍏 **Companion Nutrition & Safe Foods Guide**:\n\n` +
            `• **✅ Safe & Nutritious Human Foods (In Moderation)**:\n` +
            `  - **Cooked Lean Meats**: Plain boiled boneless chicken breast, turkey, lean beef (no garlic, onion, or seasonings).\n` +
            `  - **Vegetables**: Steamed carrots, green beans, boiled sweet potato, plain canned pumpkin (superb digestive fiber).\n` +
            `  - **Fruits**: Sliced seedless apples, blueberries, seedless watermelon, banana slices (seeds/cores removed).\n` +
            `  - **Eggs & Dairy**: Fully cooked scrambled or boiled eggs; small plain Greek yogurt (if lactose tolerant).\n` +
            `  - **Peanut Butter**: Safe ONLY if 100% xylitol-free / birch sugar-free.\n\n` +
            `• **❌ Strictly Toxic Foods**:\n` +
            `  - Chocolate, Grapes & Raisins, Onions & Garlic, Macadamia Nuts, Cooked Bones (splinter hazard), Caffeine, Alcohol.\n\n` +
            `• **The 10% Rule**: Treats and human toppers should never exceed 10% of your companion's total daily caloric intake.`;
        }

        // 6. Gastrointestinal Distress (Vomiting & Diarrhea)
        else if (/\b(vomit|vomiting|threw up|throwing up|diarrhea|loose stool|upset stomach|nausea|constipated|constipation)\b/i.test(lower)) {
          reply = `🩺 **Clinical Triage: Gastrointestinal Upset**:\n\n` +
            `• **Triage Evaluation**: A single isolated episode with bright demeanor often points to mild dietary indiscretion.\n` +
            `• **Bland Diet Protocol**:\n` +
            `  1. Withhold rich kibble/treats for 8–12 hours (always maintain full access to clean fresh water).\n` +
            `  2. Transition to small portions of boiled boneless chicken breast and plain white rice (2:1 ratio) or 1 tbsp pure pumpkin puree for 2–3 days.\n` +
            `• **🚨 Emergency Red Flags (Seek Immediate Vet Care)**:\n` +
            `  - Repeated vomiting within 6 hours, black/tarry or bloody stool, severe lethargy, pale gums, or unproductive retching (GDV bloat risk).`;
        }

        // 7. Avian & Bird Health (PTFE/Teflon, Nutrition, Heavy Metals)
        else if (/\b(bird|avian|parrot|budgie|cockatiel|conure|teflon|ptfe|non-stick|feather plucking|seed diet)\b/i.test(lower)) {
          reply = `🦜 **Avian Clinical Medicine & Husbandry**:\n\n` +
            `• **🚨 PTFE / Non-Stick Toxic Fume Emergency**: Overheated Teflon/PTFE non-stick cookware, self-cleaning ovens, and space heaters release odorless polytetrafluoroethylene gases that cause fatal acute pulmonary hemorrhage in birds within minutes. Move birds to fresh air immediately.\n` +
            `• **Nutritional Standards**: All-seed diets cause severe Vitamin A deficiency and hepatic lipidosis. Avian veterinary standards require 60–70% formulated extruded pellets, supplemented with dark leafy greens and sprouted grains.\n` +
            `• **Critical Signs of Illness**: Fluffed feathers on cage bottom, tail bobbing with respiration, closed eyes, or wing droop indicate severe decompensation requiring urgent avian vet care.`;
        }

        // 8. Rabbits & Small Mammals (GI Stasis Emergency)
        else if (/\b(rabbit|bunny|guinea pig|hamster|chinchilla|gi stasis|gut stasis|not pooping|timothy hay)\b/i.test(lower)) {
          reply = `🐰 **Lagomorph & Small Exotic Critical Care**:\n\n` +
            `• **🚨 GI Stasis is a Life-Threatening Emergency**: If a rabbit stops eating or producing fecal pellets for > 12 hours, gut motility shuts down, leading to fatal gas accumulation and hypothermia.\n` +
            `• **Immediate Action**: Keep warm, contact an exotic veterinarian for prokinetics, subcutaneous fluids, and multimodal analgesia (meloxicam). Never fast a rabbit.\n` +
            `• **Dietary Foundation**: 80–85% first/second-cut Timothy hay (unlimited), 10% dark leafy greens, 5% high-fiber pellets. Guinea pigs require daily Vitamin C supplementation (10–30 mg/kg).`;
        }

        // 9. Reptile Care (UVB Lighting & Metabolic Bone Disease)
        else if (/\b(reptile|bearded dragon|gecko|snake|chameleon|tortoise|turtle|uvb|metabolic bone|mbd)\b/i.test(lower)) {
          reply = `🦎 **Reptile Veterinary Medicine & Thermal Biology**:\n\n` +
            `• **UVB & Vitamin D3 Synthesis**: Diurnal reptiles (bearded dragons, tortoises) require linear T5 HO 10.0 or 12% UVB lighting replaced every 6–12 months. Glass/plastic blocks 100% of UVB rays.\n` +
            `• **Metabolic Bone Disease (MBD)**: Calcium deficiency or lack of UVB causes tremors, rubbery jaw, fractured limbs, and cloacal prolapse.\n` +
            `• **Thermal Gradient**: Ensure strict basking zone vs. cool side gradient to facilitate digestion, immune function, and thermoregulation.`;
        }

        // 10. Equine Medicine & Colic Triage
        else if (/\b(horse|equine|colic|founder|laminitis|flank watching|gut sounds)\b/i.test(lower)) {
          reply = `🐴 **Equine Clinical Medicine & Colic Protocol**:\n\n` +
            `• **🚨 Acute Colic Warning Signs**: Flank watching, pawing ground, rolling violently, absence of borborygmi (gut sounds), and elevated heart rate (>60 bpm) indicate a veterinary emergency.\n` +
            `• **Immediate First Aid**: Remove all grain and hay. Walk the horse gently if safe. Do not administer banamine IM (risk of fatal clostridial myositis). Call an equine veterinarian immediately.`;
        }

        // 11. Caloric Math & Feeding Calculations
        else if (/\b(calorie|calories|rer|mer|how much to feed|feeding amount|weight loss diet|calculate food)\b/i.test(lower)) {
          reply = `🥣 **WSAVA Veterinary Caloric & Nutrition Calculations**:\n\n` +
            `1. **Resting Energy Requirement (RER)**:\n` +
            `   $$RER = 70 \\times (BW_{kg})^{0.75}$$\n` +
            `   - *Example (10 kg pet)*: $70 \\times (10)^{0.75} \\approx 394\\text{ kcal/day}$.\n` +
            `2. **Maintenance Energy Requirement (MER)**:\n` +
            `   - Neutered Adult Dog: $1.6 \\times RER$\n` +
            `   - Intact Adult Dog: $1.8 \\times RER$\n` +
            `   - Weight Loss Goal: $1.0 \\times RER$\n` +
            `   - Adult Neutered Cat: $1.2 \\times RER$\n` +
            `3. **Feeding Measure**: Divide total daily MER kcal by the kcal/cup on your specific pet food bag to determine precise meal portions.`;
        }

        // 12. Puppy Biting & Behavior Training
        else if (/\b(biting|play bit|mouthing|puppy bite|stop biting|bite inhibition|teething|chewing|crate train|potty train|barking|separation anxiety)\b/i.test(lower)) {
          reply = `🐾 **Positive Reinforcement Behavior & Training Protocol**:\n\n` +
            `1. **Play Biting & Mouthing**: Emit a high-pitched "Ouch!", freeze movement for 5 seconds, and redirect immediately to an authorized chew toy (frozen Kong or teething ring).\n` +
            `2. **Crate & Potty Windows**: Take puppies outside immediately upon waking, 15 minutes after eating, and after vigorous play. Reward within 2 seconds of outdoor elimination.\n` +
            `3. **Separation Anxiety**: Desensitize departure cues (keys, shoes). Practice 2–5 minute calm departures with high-value lick mats (licking releases calming endorphins).`;
        }

        // 13. Pet Adoption & Rescue
        else if (/\b(adopt|adoption|shelter|rescue a dog|rescue a cat|get a puppy|get a kitten)\b/i.test(lower)) {
          reply = `🐶 **Pet Adoption & Rescue Guidance**:\n\n` +
            `• **Where to Adopt**: Browse the **Community $\\rightarrow$ Adoption Hub** in PetConnect AI, or connect with local animal shelters and verified rescue foster networks.\n` +
            `• **Preparation**: Secure non-toxic food/water bowls, age-appropriate food, crate/bed, leash, and schedule an initial veterinary intake exam for vaccinations and microchipping.`;
        }

        // 14. Universal Omni-Domain Reasoner
        else {
          reply = `💡 **PetConnect AI Clinical & Science Guidance**:\n\n` +
            `Regarding your inquiry about "${prompt}":\n\n` +
            `• **Core Principles**: Maintaining optimal health, balanced species-appropriate nutrition, mental enrichment, and regular preventive veterinary wellness is essential for companion longevity.\n` +
            `• **Next Steps**: If this relates to a specific medical symptom, dietary calculation, training routine, or general scientific question, feel free to ask with additional details!`;
        }
      }
    }

    return new Response(
      JSON.stringify({
        reply,
        conversation_id,
        timestamp: new Date().toISOString(),
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error.message || "Failed to process AI assistant request" }),
      {
        status: 400,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      }
    );
  }
});
