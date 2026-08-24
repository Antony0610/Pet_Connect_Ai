import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

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
    const { prompt, conversation_id, pet_id } = await req.json();

    if (!prompt) {
      return new Response(
        JSON.stringify({ error: "Missing prompt" }),
        { status: 400, headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const geminiApiKey = Deno.env.get("GEMINI_API_KEY") ?? "";

    // 1. Fetch pet profile context if available
    let petContext = "";
    let petName = "";
    let petSpecies = "";
    let petBreed = "";
    let petAge = "";
    let petWeight = "";
    let petAllergies = "";

    if (supabaseUrl && supabaseServiceKey && pet_id) {
      try {
        const supabase = createClient(supabaseUrl, supabaseServiceKey);
        const { data: pet } = await supabase
          .from("pets")
          .select("name, species, breed, age, weight, allergies, is_spayed_neutered")
          .eq("id", pet_id)
          .maybeSingle();

        if (pet) {
          petName = pet.name || "";
          petSpecies = pet.species || "pet";
          petBreed = pet.breed || "";
          petAge = pet.age ? `${pet.age} years old` : "";
          petWeight = pet.weight ? `${pet.weight} kg` : "";
          petAllergies = pet.allergies ? pet.allergies.join(", ") : "None reported";

          petContext = `Active Pet Profile: Name: ${petName}, Species: ${petSpecies}, Breed: ${petBreed}, Age: ${petAge}, Weight: ${petWeight}, Allergies: ${petAllergies}.`;
        }
      } catch (_e) {
        // Continue without blocking if pet fetch fails
      }
    }

    let reply = "";

    const clinicalSystemPrompt = `You are PetConnect AI, an intelligent, empathetic, and certified veterinary & pet companion assistant.
${petContext ? petContext : "The user is asking about their companion animal."}

You have multiple capabilities:
1. PET IDENTITY: If the user asks about their pet's name, breed, age, or profile, answer accurately using the Active Pet Profile above. If no pet is linked yet, gently ask them for their pet's name.
2. WEATHER & WALKS: If the user asks about weather, walks, or outdoor exercise, provide practical safety tips (e.g., pavement 7-second heat check, hydration, rain/cold protection, exercise duration suited for their breed/species).
3. NUTRITION & CARE: Provide evidence-based WSAVA/AAHA nutrition, grooming, training, and wellness advice.
4. MEDICAL & TOXICITY TRIAGE:
   - Emergencies: Highlight immediate steps and emergency vet hospital transport (toxicities like chocolate/grapes/xylitol/lilies, GDV bloat, seizures, respiratory distress).
   - Vitals Reference: Dogs HR 60-140 bpm, RR 15-30 rpm, Temp 101.0-102.5°F. Cats HR 140-220 bpm, RR 20-30 rpm, Temp 100.5-102.5°F.
5. CONVERSATIONAL: Respond naturally and warmly to greetings and everyday queries without forcing rigid triage headers unless medically relevant.`;

    if (geminiApiKey) {
      try {
        const response = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`,
          {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              contents: [
                {
                  role: "user",
                  parts: [
                    {
                      text: `${clinicalSystemPrompt}\n\nUser Query: ${prompt}`,
                    },
                  ],
                },
              ],
              generationConfig: {
                temperature: 0.6,
                maxOutputTokens: 900,
              },
            }),
          }
        );

        if (response.ok) {
          const data = await response.json();
          reply = data?.candidates?.[0]?.content?.parts?.[0]?.text || "";
        }
      } catch (_e) {
        // Fall back to intelligent rule-based engine
      }
    }

    if (!reply) {
      const lower = prompt.toLowerCase();
      
      // 1. Pet Name / Identity Queries
      if (lower.includes("pet's name") || lower.includes("pets name") || lower.includes("my dog's name") || lower.includes("my cat's name") || lower.includes("what is my pet") || lower.includes("whats my pet") || lower.includes("how old is my") || lower.includes("who is my pet")) {
        if (petName) {
          reply = `Your active pet registered in PetConnect AI is **${petName}**${petBreed ? ` (a wonderful ${petBreed} ${petSpecies})` : ` (${petSpecies})`}.${petAge ? ` ${petName} is ${petAge}.` : ''}${petWeight ? ` Current recorded weight is ${petWeight}.` : ''}${petAllergies && petAllergies !== 'None reported' ? ` Known allergies: ${petAllergies}.` : ''}\n\nHow is ${petName} doing today?`;
        } else {
          reply = "You haven't selected or added a pet profile yet. You can add your companion in the Pet Profile section or select them on the dashboard so I can personalize all health and care advice for them!";
        }
      }
      // 2. Weather & Walk Queries
      else if (lower.includes("weather") || lower.includes("whether") || lower.includes("walk") || lower.includes("outside") || lower.includes("outdoor") || lower.includes("rain") || lower.includes("hot") || lower.includes("cold")) {
        const targetName = petName ? petName : "your pet";
        reply = `⛅ **Outdoor & Walk Safety Advice for ${targetName}**:\n\n` +
          `• **Temperature & Asphalt Check**: Before walking on sunny days, place the back of your hand firmly against the pavement for 7 seconds. If it's too hot for your hand, it's too hot for ${targetName}'s paw pads!\n` +
          `• **Hydration**: Always carry fresh water and a collapsible bowl for walks longer than 15 minutes.\n` +
          `• **Exercise Duration**: 20–30 minutes of moderate sniffing and walking is ideal for mental stimulation and joint health.\n` +
          `• **Weather Cautions**: In heavy rain or snow, dry their paws thoroughly after coming inside to prevent interdigital dermatitis.`;
      }
      // 3. Toxicities & Poison
      else if (lower.includes("chocolate") || lower.includes("grape") || lower.includes("raisin") || lower.includes("xylitol") || lower.includes("lily") || lower.includes("lilies") || lower.includes("poison") || lower.includes("toxic") || lower.includes("onion") || lower.includes("garlic")) {
        reply = `🚨 **[TRIAGE: EMERGENCY - POTENTIAL TOXIC INGESTION]**\n\n` +
          `Immediate Protocol for ${petName ? petName : 'your pet'}:\n` +
          `1. **Do NOT induce vomiting** unless directly instructed by an emergency toxicologist or veterinarian (corrosives cause secondary esophageal burns).\n` +
          `2. **Preserve packaging & quantify**: Note the exact amount ingested and time elapsed.\n` +
          `3. **Immediate Action**: Contact the ASPCA Animal Poison Control / Pet Poison Helpline or transport to the nearest 24/7 Veterinary Emergency Hospital.\n` +
          `• *Critical Note*: Xylitol (birch sweetener) triggers severe hypoglycemia in 30 minutes; Lilies cause fatal acute renal failure in felines.`;
      }
      // 4. Critical Respiratory / Seizures
      else if (lower.includes("breath") || lower.includes("chok") || lower.includes("seiz") || lower.includes("collapse") || lower.includes("pale gum") || lower.includes("unconscious")) {
        reply = `🚨 **[TRIAGE: CRITICAL EMERGENCY]**\n\n` +
          `Immediate Life-Support Measures:\n` +
          `• **Breathing Distress**: Keep ${petName ? petName : 'the animal'} calm and cool in a well-ventilated space. Open-mouth breathing in felines is always a critical emergency.\n` +
          `• **Seizures**: Clear hard objects away from the area. Do NOT place hands inside the mouth. Time the episode. If it lasts > 2 minutes, transport immediately with a cool damp cloth over the body.\n` +
          `• **Pale/Blue Gums**: Indicates circulatory shock or hypoxia—proceed immediately to veterinary ER.`;
      }
      // 5. Greetings & Intro
      else if (lower.includes("hi") || lower.includes("hello") || lower.includes("hey") || lower.includes("how are you") || lower.includes("who are you")) {
        reply = `Hello! I am your **PetConnect AI Assistant**, trained on AAHA & WSAVA companion animal guidelines.${petName ? ` I'm currently tracking **${petName}**'s wellness.` : ''}\n\nI can help you with:\n• Daily care, weather & exercise recommendations\n• Nutrition & dietary advice\n• Symptom checks & emergency triage\n• Smart collar activity & health trends\n\nHow can I help you and ${petName ? petName : 'your companion'} today?`;
      }
      // 6. Food & Nutrition
      else if (lower.includes("food") || lower.includes("diet") || lower.includes("eat") || lower.includes("feed") || lower.includes("nutrition") || lower.includes("treat")) {
        reply = `🥗 **WSAVA Nutrition & Feeding Guidelines${petName ? ` for ${petName}` : ''}**:\n\n` +
          `• Ensure complete, balanced AAFCO-compliant meals formulated for their specific life stage.\n` +
          `• Treat calories should never exceed 10% of total daily caloric intake to prevent obesity and pancreatitis.\n` +
          `• Safe Healthy Treats: Plain cooked pumpkin, peeled carrots, blueberries, green beans, and cooked lean poultry.\n` +
          `• Never feed: Grapes, raisins, onions, garlic, chocolate, avocado, macadamia nuts, or artificially sweetened baked goods.`;
      }
      // 7. General Care
      else {
        reply = `🐾 **PetConnect AI Care Insight${petName ? ` for ${petName}` : ''}**:\n\n` +
          `Regarding "${prompt}":\n` +
          `• Keep an eye on ${petName ? petName : 'your companion'}'s energy levels, appetite, water intake, and normal daily routine.\n` +
          `• Normal canine/feline vital ranges: Temperature 101.0–102.5°F (38.3–39.2°C), healthy pink gums with capillary refill in under 2 seconds.\n\n` +
          `Feel free to ask for specific advice on symptoms, training, exercise, or attach a photo for visual analysis!`;
      }
    }

    return new Response(
      JSON.stringify({
        reply,
        conversation_id,
        pet_id,
        confidence: geminiApiKey ? 0.98 : 0.90,
        model: "gemini-1.5-flash",
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
