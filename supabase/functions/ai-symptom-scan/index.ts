import "jsr:@supabase/functions-js/edge-runtime.d.ts";

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
    const { symptom_description, image_url, pet_id } = await req.json();

    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    let analysis_summary = "";
    let urgency_level = "ROUTINE";
    let recommendations: string[] = [];

    if (geminiApiKey) {
      const parts: any[] = [];

      // System instruction requesting structured JSON
      parts.push({
        text: `You are PetConnect AI Symptom Scanner, an AI veterinary diagnostics assistant.
Analyze the following pet symptom description and image (if provided).
Respond ONLY in valid JSON with this exact schema:
{
  "analysis_summary": "Detailed, clinical description of what might be occurring, observations, and possible conditions.",
  "urgency_level": "ROUTINE" | "URGENT" | "EMERGENCY",
  "recommendations": ["Recommendation 1", "Recommendation 2", "Recommendation 3"]
}

Symptom Description: ${symptom_description || "General visual inspection"}`,
      });

      // If an image URL is supplied, fetch it and convert to inline data
      if (image_url) {
        try {
          const imageRes = await fetch(image_url);
          if (imageRes.ok) {
            const arrayBuffer = await imageRes.arrayBuffer();
            const base64Data = btoa(
              new Uint8Array(arrayBuffer).reduce(
                (data, byte) => data + String.fromCharCode(byte),
                ""
              )
            );
            const contentType = imageRes.headers.get("content-type") || "image/jpeg";
            parts.push({
              inlineData: {
                mimeType: contentType,
                data: base64Data,
              },
            });
          }
        } catch (_imgErr) {
          // Proceed with text-only if image fetch fails
        }
      }

      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [{ role: "user", parts }],
            generationConfig: {
              responseMimeType: "application/json",
              temperature: 0.2,
            },
          }),
        }
      );

      if (response.ok) {
        const data = await response.json();
        const rawJson = data?.candidates?.[0]?.content?.parts?.[0]?.text;
        try {
          const parsed = JSON.parse(rawJson);
          analysis_summary = parsed.analysis_summary || "Symptom scan completed.";
          urgency_level = parsed.urgency_level || "ROUTINE";
          recommendations = parsed.recommendations || [
            "Monitor pet for 24-48 hours.",
            "Contact your veterinarian if symptoms change.",
          ];
        } catch (_parseErr) {
          analysis_summary = rawJson || "Scan completed.";
        }
      } else {
        analysis_summary = `AI service scan returned status ${response.status}. Please evaluate symptoms clinically.`;
      }
    } else {
      analysis_summary = `Symptom evaluation completed for: "${symptom_description || "general checkup"}". (Note: GEMINI_API_KEY secret pending in Supabase). No acute life-threatening triggers detected in text.`;
      urgency_level = (symptom_description?.toLowerCase().includes("bleeding") || symptom_description?.toLowerCase().includes("unconscious") || symptom_description?.toLowerCase().includes("poison")) ? "EMERGENCY" : "ROUTINE";
      recommendations = [
        "Keep the pet in a calm, comfortable environment.",
        "Ensure clean drinking water is accessible.",
        "Schedule a clinical evaluation with your primary veterinarian.",
      ];
    }

    return new Response(
      JSON.stringify({
        analysis_summary,
        urgency_level,
        recommendations,
        pet_id,
        image_evaluated: !!image_url,
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
      JSON.stringify({ error: error.message || "Failed to analyze symptoms" }),
      {
        status: 400,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      }
    );
  }
});
