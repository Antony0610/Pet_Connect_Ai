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
    const geminiApiKey = gemini_api_key || Deno.env.get("GEMINI_API_KEY");

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

    const clinicalSystemPrompt = `You are PetConnect AI, a world-class universal AI assistant powered by Google Gemini, equipped with deep specialized veterinary knowledge and universal reasoning.
${petContext ? `[USER REGISTERED PET CONTEXT]: ${petContext}` : "The user is interacting with PetConnect AI."}

CORE CAPABILITIES & INSTRUCTIONS:
1. OPEN-DOMAIN ANSWERING: Answer ANY question accurately, brilliantly, and concisely like ChatGPT / Google Search across all domains:
   • General Science, Weather, Space, Chemistry, Physics, History, Geography, Trivia, Philosophy.
   • Programming, Software Engineering (Python, Flutter, Dart, SQL, etc.), Mathematics, Logic calculations.
   • Creative Writing, Essays, Summaries, Recipes, Translations, Everyday inquiries.
   • Clinical Veterinary Medicine: WSAVA Nutrition, Toxicity triage, Pharmacology, First aid, Puppy/Kitten training, Behavior psychology.
2. CONTEXT ADAPTIVITY:
   • When the user asks about pets or their companion, seamlessly apply the registered pet details without asking them to re-enter info.
   • When the user asks a general question (e.g. weather, coding, history), answer it directly without forcing pet references.
3. TONE & FORMATTING:
   • Give direct, crisp, structured, and actionable answers in clean Markdown.
   • NEVER output generic template disclaimers (e.g. "I am an AI..." or "Regarding your inquiry: Knowledge & Insights..."). Give direct, high-value answers immediately.
   • If the user asks in Malayalam (മലയാളം), reply in fluent, natural Malayalam.`;

    // Try Gemini API if key is configured
    if (geminiApiKey) {
      const modelsToTry = [
        "gemini-3.7-flash",
        "gemini-3.1-flash-lite",
        "gemini-3.6-flash",
        "gemini-3.8-flash",
      ];

      const conversationContents = [];
      if (Array.isArray(history) && history.length > 0) {
        for (const h of history) {
          if (h.role && h.parts) conversationContents.push(h);
        }
      }
      conversationContents.push({
        role: "user",
        parts: [{ text: prompt }],
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
                system_instruction: {
                  parts: [{ text: clinicalSystemPrompt }],
                },
                contents: conversationContents,
                generationConfig: {
                  temperature: 0.7,
                  maxOutputTokens: 2048,
                  thinkingConfig: { thinkingBudget: 0 },
                },
              }),
            }
          );

          if (response.ok) {
            const data = await response.json();
            const candidateParts = data?.candidates?.[0]?.content?.parts;
            if (Array.isArray(candidateParts)) {
              for (const part of candidateParts) {
                if (part.text && part.thought !== true) {
                  reply = part.text.trim();
                  break;
                }
              }
            }
          }
        } catch (_e) {
          // Continue to next model
        }
      }
    }

    if (!reply) {
      reply = "⚠️ Service temporarily unavailable. Please check your internet connection and try again.";
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
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
});
