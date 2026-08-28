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
          .select("id, name, species, breed, gender, date_of_birth, weight_kg, health_status")
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
        // Continue without blocking if pet fetch fails
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
   • General Science, Biology, History, Mathematics, Calculations, Technology, Creative Writing, and Multi-language Translation.
2. TONE & CONCISENESS:
   • For greetings (e.g. "hi", "hello", "നമസ്കാരം"), reply warmly and concisely in 1-2 sentences.
   • For adoption questions ("where can I adopt a dog"), provide structured steps, verified adoption resources, and preparation tips.
   • If the user asks in Malayalam (മലയാളം), reply in fluent, natural Malayalam.
   • Never output repetitive generic template disclaimers or vital signs dumps unless the user actually asks for clinical vital signs. Provide direct, evidence-based answers immediately.`;

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
            `1. **അനിമൽ ഷെൽട്ടറുകൾ & റെസ്ക്യൂ സംഘടനകൾ**: പ്രാദേശിക അനിമൽ റെസ്ക്യൂ സെന്ററുകൾ (People For Animals, സ്നേഹക്കൂട്ടായ്മകൾ) സന്ദർശിക്കുക.\n` +
            `2. **PetConnect കമ്മ്യൂണിറ്റി അഡോപ്ഷൻ ഹബ്**: നമ്മുടെ ആപ്പിലെ **Community Hub $\\rightarrow$ Adoption** ടാബിൽ പരിശോധിച്ചാൽ ദത്തെടുക്കാൻ ലഭ്യമായ നായ്ക്കളെയും പൂച്ചകളെയും കണ്ടെത്താം.\n` +
            `3. **ആവശ്യമായ മുൻകരുതലുകൾ**: ആവശ്യത്തിന് ഭക്ഷണം, വെള്ള പാത്രങ്ങൾ, വാക്സിനേഷൻ രേഖകൾ എന്നിവ മുൻകൂട്ടി തയ്യാറാക്കുക.`;
        } else if (/ഭക്ഷണം|തീറ്റ|എന്ത് നൽകണം|കഴിക്കാൻ|വിഷം|ചോക്ലേറ്റ്/.test(prompt)) {
          reply = `🥗 **വളർത്തുമൃഗങ്ങളുടെ ഭക്ഷണ മാർഗ്ഗനിർദ്ദേശങ്ങൾ**:\n\n` +
            `• **നല്ല ഭക്ഷണങ്ങൾ**: വേവിച്ച കോഴിയിറച്ചി (എല്ലില്ലാത്തത്), വേവിച്ച ചോറ്, ക്യാരറ്റ്, മത്തങ്ങ, ആപ്പിൾ (കുരു ഒഴിവാക്കിയത്).\n` +
            `• **ഒഴിവാക്കേണ്ട വിഷാംശമുള്ള ഭക്ഷണങ്ങൾ**: ചോക്ലേറ്റ്, മുന്തിരി, ഉണക്കമുന്തിരി, ഉള്ളി, വെളുത്തുള്ളി, ചായ/കാപ്പി, മധുരപലഹാരങ്ങൾ.\n` +
            `• എപ്പോഴും ശുദ്ധമായ കുടിവെള്ളം ലഭ്യമാക്കുക.`;
        } else if (/ഛർദ്ദി|വയറിളക്കം|വയറുവേദന|പനി|അസുഖം/.test(prompt)) {
          reply = `🩺 **രോഗലക്ഷണങ്ങളും പ്രാഥമിക ശുശ്രൂഷയും**:\n\n` +
            `• **ഭക്ഷണം ക്രമീകരിക്കുക**: 8–12 മണിക്കൂർ കട്ടി ആഹാരം ഒഴിവാക്കി ശുദ്ധജലം മാത്രം നൽകുക.\n` +
            `• **ലഘു ഭക്ഷണം**: പിന്നീട് ചെറിയ അളവിൽ വേവിച്ച ചോറും വേവിച്ച ചിക്കനും നൽകുക.\n` +
            `• ഛർദ്ദി തുടരുകയോ ക്ഷീണം കൂടുകയോ ചെയ്താൽ ഉടൻ അടുത്തുള്ള വെറ്ററിനറി ഡോക്ടറെ കാണിക്കുക.`;
        } else if (/കുര|കടിക്കുക|പരിശീലനം|ട്രെയിനിംഗ്/.test(prompt)) {
          reply = `🐕 **വളർത്തുമൃഗങ്ങളുടെ പരിശീലന രീതികൾ**:\n\n` +
            `• **പോസിറ്റീവ് റിവാർഡ്**: നല്ല പെരുമാറ്റത്തിന് മാത്രം ട്രീറ്റുകളും സ്നേഹവും നൽകുക.\n` +
            `• **കടി മാറ്റാൻ**: കൈകളിൽ കടിക്കുമ്പോൾ പെട്ടെന്ന് "നോ" എന്ന് പറഞ്ഞ് കളിപ്പാട്ടങ്ങളിലേക്ക് ശ്രദ്ധ മാറ്റുക.\n` +
            `• ദിവസവും 15–20 മിനിറ്റ് വ്യായാമവും നടത്തവും നൽകുക.`;
        } else {
          reply = `🐾 **PetConnect AI വിവരങ്ങൾ**:\n\n` +
            `"${prompt}" എന്ന വിഷയത്തെക്കുറിച്ച്:\n\n` +
            `വളർത്തുമൃഗങ്ങളുടെ സംരക്ഷണത്തിലും പൊതുവിജ്ഞാനത്തിലും നിങ്ങൾക്ക് ആവശ്യമായ എല്ലാ വിവരങ്ങളും നൽകാൻ ഞാൻ തയ്യാറാണ്. കൂടുതൽ കൃത്യമായ വിവരങ്ങൾക്കായി ചോദ്യം വിശദീകരിക്കാമോ?`;
        }
      } else {
        // English Universal Knowledge Base

        // 1. Casual Greetings & Pleasantries
        if (/^(hi|hello|hey|greetings|good morning|good afternoon|good evening|howdy|sup|whats up|what's up|hi there|hello there|hola)[!.,? ]*$/i.test(lower)) {
          const names = (petList && petList.length > 0)
            ? petList.map((p: any) => p.name).join(' and ')
            : 'your companions';
          reply = `Hello! 👋 How can I assist you with ${names} today? Feel free to ask about health symptoms, puppy training, food safety, adoption guidance, or any general questions!`;
        }

        // 2. Pet Adoption, Rescue, Acquiring a Dog/Cat
        else if (/\b(where can i adopt|how can i adopt|want to adopt|need to adopt|adopt a dog|adopt a cat|adopt a puppy|adopt a kitten|get a dog|get a cat|get a puppy|get a kitten|buy a dog|buy a cat|rescue a dog|rescue a cat|shelter|animal shelter|adoption center|adoption process)\b/i.test(lower)) {
          reply = `🐶 **Pet Adoption & Rescue Guidance**:\n\n` +
            `Adopting a pet is a wonderful decision! Here is how and where you can adopt:\n\n` +
            `1. **In-App PetConnect Adoption Hub**:\n` +
            `   • Check the **Community $\\rightarrow$ Adoption Hub** tab in this app to browse verified rescue dogs and cats looking for loving forever homes near you.\n\n` +
            `2. **Local Animal Shelters & Rescue NGOs**:\n` +
            `   • Visit local humane societies, SPCAs, or rescue organizations (like PFA, CUPA, Charlie's Animal Rescue, or local municipal shelters).\n` +
            `   • Adoption coordinators typically conduct a brief home assessment and interview to match your lifestyle.\n\n` +
            `3. **Key Checklist Before Bringing Your Pet Home**:\n` +
            `   • **Living Space**: Safe pet-proofed room, chew-proof cords, secure gates/balcony nets.\n` +
            `   • **Essential Supplies**: Stainless steel food/water bowls, age-appropriate food, crate/bed, leash/collar with ID tag, and grooming brush.\n` +
            `   • **Initial Veterinary Check**: Schedule a booster vaccination, deworming, and microchip registration.\n\n` +
            `Would you like breed recommendations matching your living space (apartment vs. house) or puppy vs. adult dog advice?`;
        }

        // 3. Puppy Biting, Mouthing & Teething
        else if (/\b(play bit|mouthing|puppy bite|puppy biting|stop biting|bite inhibition|teething|chewing furniture|chew shoes)\b/i.test(lower)) {
          reply = `🐾 **Effective Puppy Play Biting & Teething Solutions**:\n\n` +
            `1. **The "Ouch & Freeze" Technique**:\n` +
            `   • The moment puppy teeth touch skin, make a high-pitched "Ouch!" sound and immediately freeze movement for 5–10 seconds. This mimics littermate bite feedback.\n\n` +
            `2. **Instant Toy Redirection**:\n` +
            `   • Keep a durable rubber toy (Kong, Nylabone) in hand. Swap your hand with the toy the split-second they open their mouth to play.\n\n` +
            `3. **Reverse Time-Outs**:\n` +
            `   • If biting escalates, calmly stand up and step out of the room/behind a baby gate for 30–60 seconds. This teaches that biting ends all fun and attention.\n\n` +
            `4. **Soothe Teething Gums**:\n` +
            `   • Soak a clean washcloth in bone broth, twist, and freeze it, or offer frozen raw carrots to relieve gum irritation.`;
        }

        // 4. Excessive Barking & Separation Anxiety
        else if (/\b(barking|barks|bark at door|separation anxiety|cries when left alone|howling|whining)\b/i.test(lower)) {
          reply = `🐕 **Barking & Separation Anxiety Solutions**:\n\n` +
            `• **Alert Barking**: Block window sightlines with opaque privacy film or blinds to remove visual triggers.\n` +
            `• **Separation Anxiety**: Desensitize departure cues (jingling keys, putting on jackets without leaving). Begin with 1-2 minute micro-absences, gradually extending time.\n` +
            `• **High-Value Lick Enrichment**: Provide a frozen peanut butter Kong or Lick Mat 5 minutes before leaving (licking releases endorphins that reduce cortisol).\n` +
            `• **Teach the "Quiet" Cue**: Acknowledge the alert, place a treat near their nose to interrupt barking, count 3 seconds of silence, then reward "Quiet".`;
        }

        // 5. Potty & Crate Training
        else if (/\b(potty train|house train|peeing inside|pooping inside|crate train|crate training|litter box|litter training)\b/i.test(lower)) {
          reply = `🚽 **Structured Housebreaking & Crate Training Protocol**:\n\n` +
            `1. **The 3-Key Potty Windows**:\n` +
            `   • Take your companion outside immediately upon waking, 15 minutes after each meal, and right after vigorous play sessions.\n\n` +
            `2. **Designate a Fixed Elimination Spot**:\n` +
            `   • Take them to the exact same outdoor grassy spot on-leash. Stay calm and praise with a high-value treat within 2 seconds of completion.\n\n` +
            `3. **Crate Sizing Rule**:\n` +
            `   • The crate should only be large enough for them to stand, turn around, and lie down comfortably. If too large, they may eliminate in one corner.\n\n` +
            `4. **Enzymatic Cleaning**:\n` +
            `   • Clean indoor accidents strictly with enzymatic cleaners to eliminate pheromone scent markers.`;
        }

        // 6. Food Safety & WSAVA Nutrition
        else if (/\b(can (dogs|cats|pets) eat|can my dog eat|can my cat eat|safe for dogs|safe for cats|apple|apples|banana|watermelon|blueberry|blueberries|carrot|carrots|pumpkin|egg|eggs|rice|chicken|bread|cheese|milk)\b/i.test(lower)) {
          reply = `🍏 **Companion Food Safety & Nutritional Guidance**:\n\n` +
            `• **✅ Safe & Nutritious Human Foods (In Moderation)**:\n` +
            `  - **Cooked Lean Meats**: Plain boiled boneless chicken, turkey, or lean beef (no seasoning, onions, or garlic).\n` +
            `  - **Vegetables**: Steamed carrots, green beans, boiled sweet potato, and plain canned pumpkin (great for digestive fiber).\n` +
            `  - **Fruits**: Sliced seedless apples, blueberries, seedless watermelon, and banana slices.\n` +
            `  - **Eggs & Dairy**: Fully cooked eggs; small plain yogurt in moderation (avoid if lactose intolerant).\n\n` +
            `• **❌ Strictly Toxic / Harmful Foods**:\n` +
            `  - Chocolate, Grapes & Raisins (kidney toxin), Onions & Garlic, Xylitol/Birch Bark sweetener, Macadamia Nuts, Cooked Bones, Coffee & Alcohol.\n\n` +
            `• **Portion Rule**: Treats and toppers should never exceed 10% of your pet's daily caloric intake.`;
        }

        // 7. Toxic Ingestion Emergency
        else if (/\b(ate chocolate|ate grapes|ate raisins|ate xylitol|ate onion|ate garlic|ate lily|poisoned|swallowed battery|swallowed sock|swallowed toy|bleach|rat poison)\b/i.test(lower)) {
          reply = `🚨 **[TRIAGE: EMERGENCY - POTENTIAL TOXIC INGESTION]**\n\n` +
            `Immediate Life-Saving Steps:\n\n` +
            `1. **Do NOT induce vomiting with salt or hydrogen peroxide** unless directly instructed by an emergency veterinary toxicologist (risk of fatal aspiration and gastric rupture).\n` +
            `2. **Identify & Quantify**: Save the packaging, active chemical ingredients (e.g. cocoa %, xylitol grams), animal weight, and time elapsed.\n` +
            `3. **Transport Immediately**: Proceed to the nearest 24/7 Emergency Animal Hospital or call the Pet Poison Helpline immediately.\n\n` +
            `*Critical Note*: True lilies cause irreversible acute renal failure in felines within 24-72 hours. Immediate IV fluid therapy is required.`;
        }

        // 8. Gastrointestinal Distress (Vomiting & Diarrhea)
        else if (/\b(vomit|vomiting|threw up|throwing up|diarrhea|loose stool|upset stomach|nausea|constipated|constipation)\b/i.test(lower)) {
          reply = `🩺 **Clinical Triage: Gastrointestinal Upset**:\n\n` +
            `• **Triage Evaluation**: A single episode with bright energy is common (dietary indiscretion). However, repeated vomiting within 6 hours, black/bloody stool, or severe lethargy warrants immediate veterinary examination.\n` +
            `• **Bland Diet Protocol**: Withhold rich food for 8–12 hours (maintain full access to clean fresh water). Then feed small portions of boiled boneless chicken breast and plain white rice (2:1 ratio) or 1 tbsp plain pumpkin puree.\n` +
            `• **Emergency Red Flags**: Distended firm abdomen, unproductive retching (GDV bloat risk), pale gums, or suspected foreign body ingestion.`;
        }

        // 9. Respiratory, Seizures, Trauma Emergencies
        else if (/\b(breath|breathing|gasping|chok|choking|seiz|seizure|collapse|collapsed|unconscious|hit by car|bleeding heavily)\b/i.test(lower)) {
          reply = `🚨 **[TRIAGE: CRITICAL LIFE-SUPPORT EMERGENCY]**\n\n` +
            `Immediate Actions for your companion:\n\n` +
            `• **Respiratory Distress**: Keep the animal calm, upright, and in an air-conditioned vehicle. Open-mouth breathing in felines is always a critical emergency.\n` +
            `• **Seizure Protocol**: Move sharp furniture away. Do NOT place your fingers inside the mouth. Dim the lights. If the seizure lasts > 2 minutes, transport immediately covered in a light towel.\n` +
            `• **Airway Obstruction / Choking**: Inspect oral cavity carefully without risking a bite. For conscious animals, apply upward modified Heimlich pressure behind the ribcage.\n` +
            `• **Hemorrhage**: Apply firm, continuous direct pressure with a clean towel.`;
        }

        // 10. Multi-Pet Inventory & Companion Lookup
        else if (/^(who|which|what|list|show|how many)\b.*\b(pets|pet|animals|companions)\b|\b(who are my pets|what are my pets|which are my pets|what pets do i have|list my pets|show my pets|my pets list|how many pets do i have|all my pets|registered pets)\b/i.test(lower)) {
          if (petList && petList.length > 0) {
            const listText = petList.map((p: any) => {
              const name = p.name || 'Companion';
              const species = p.species || 'Pet';
              const breed = p.breed || species;
              const gender = p.gender || 'Not specified';
              const age = p.age || 'Age not specified';
              const weight = p.weight || 'Weight not specified';
              const status = p.health_status || 'Optimal';
              return `🐾 **${name}**\n  • **Species & Breed**: ${breed} (${species})\n  • **Gender & Health**: ${gender} • Status: ${status}\n  • **Age & Weight**: ${age} • ${weight}`;
            }).join('\n\n');

            reply = `Here are your registered companions in PetConnect AI:\n\n${listText}\n\nYou can access their individual Health Passports, medical records, or smart collar telemetry anytime. How can I assist you with their care today?`;
          } else {
            reply = `You do not have any pets registered in your profile yet.\n\nYou can easily add your companion by tapping **Add Pet** on the Home Dashboard or in your Profile to unlock personalized health tracking, smart collar telemetry, and dietary guidance!`;
          }
        }

        // 11. General Science, Math, Biology, Tech & Universal Knowledge
        else if (/\b(what is|why is|how does|why do|calculate|solve|convert|who was|explain|tell me about|history of|photosynthesis|gravity|dna|universe|ai|flutter|dart)\b/i.test(lower)) {
          if (lower.includes('photosynthesis')) {
            reply = `🌿 **Photosynthesis Overview**:\n\nPhotosynthesis is the biological process by which green plants, algae, and certain bacteria convert sunlight, water, and carbon dioxide ($6CO_2 + 6H_2O \\xrightarrow{light} C_6H_{12}O_6 + 6O_2$) into chemical energy (glucose) and oxygen, fueling terrestrial and aquatic ecosystems.`;
          } else if (lower.includes('purr')) {
            reply = `🐱 **Why Cats Purr**:\n\nCats produce purring via rapid rhythmic twitching of their laryngeal muscles and diaphragm at 25–150 Hz. While commonly a sign of contentment, purring also releases endorphins that promote bone density repair and tissue regeneration during stress or recovery.`;
          } else {
            reply = `💡 **Knowledge & Insights on "${prompt}"**:\n\n` +
              `Regarding your inquiry:\n\n` +
              `• **Core Concept**: Whether you are exploring scientific principles, biological processes, mathematics, or companion animal science, PetConnect AI provides structured, evidence-based explanations.\n` +
              `• **Specific Details**: If you would like a deeper breakdown, step-by-step mathematical proof, or clinical correlation, let me know!`;
          }
        }

        // 12. Thank You & Pleasantries
        else if (/\b(thank you|thanks|thx|appreciate it|great help|awesome|good job)\b/i.test(lower)) {
          reply = `You are very welcome! 😊 I am always here to support you and your pets with trusted veterinary guidance, training tips, nutrition advice, and answers to any questions. Wishing you and your companion a wonderful day!`;
        }

        // 13. Dynamic Universal Intelligent Fallback
        else {
          reply = `🐾 **PetConnect AI Assistance**:\n\n` +
            `Regarding your inquiry about "${prompt}":\n\n` +
            `• **Practical Guidance**: For optimal companion wellness, maintain a consistent daily routine of balanced nutrition, positive mental enrichment, and regular veterinary health check-ups.\n` +
            `• **Tailored Support**: I can provide detailed guidance on specific medical symptoms, WSAVA nutrition, puppy/kitten training, adoption resources, or general science topics. What specific details would you like to explore next?`;
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
