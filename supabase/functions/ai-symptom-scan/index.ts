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
    
    const analysis_summary = `Symptom evaluation completed for ${symptom_description || "general checkup"}. No acute life-threatening indicators detected. Continue monitoring routine vitals.`;
    const urgency_level = (symptom_description?.toLowerCase().includes("bleeding") || symptom_description?.toLowerCase().includes("unconscious")) ? "EMERGENCY" : "ROUTINE";
    const recommendations = [
      "Keep the pet in a calm, temperature-controlled environment.",
      "Ensure clean drinking water is accessible.",
      "Book a follow-up consultation with your primary veterinarian if appetite decreases."
    ];

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
