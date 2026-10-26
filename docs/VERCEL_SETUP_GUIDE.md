# 🚀 Vercel Deployment Guide for PetConnect AI Web Portal

You can deploy the PetConnect AI Web Portal to **Vercel for 100% free** under `petconnect-ai.vercel.app` (or any custom domain/subdomain) in under 2 minutes.

The web portal is a modern, responsive Single Page Application (SPA) built with **React 19**, **Vite**, and **TypeScript**, using an editorial warm-monochrome design system and direct Supabase database bindings.

---

## ⚡ Option A: Instant CLI Deployment (1 Minute)

1. Open PowerShell or Terminal and navigate to `web_portal`:
   ```bash
   cd petconnect_ai/web_portal
   ```

2. Run Vercel CLI via npx:
   ```bash
   npx vercel
   ```

3. Follow the guided prompts:
   - **Set up and deploy?**: `y`
   - **Which scope?**: Press `Enter` (your personal Vercel account)
   - **Link to existing project?**: `N`
   - **Project name?**: `petconnect-ai`
   - **Directory?**: `./`

4. For production release:
   ```bash
   npx vercel --prod
   ```

Your site is live immediately at:
`https://petconnect-ai.vercel.app`

---

## 🌐 Option B: GitHub 1-Click Auto Deployment

1. Push your repository changes to GitHub.
2. Visit [https://vercel.com/new](https://vercel.com/new) and log in.
3. Import the `Pet_Connect_Ai` repository.
4. Set **Root Directory** to `web_portal` (or `petconnect_ai/web_portal` depending on your repository root).
5. Framework preset will automatically detect **Vite**.
6. Set Environment Variables (optional, for live Supabase integration):
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
7. Click **Deploy**.

---

## 📱 Features Included in the Web Portal

- `/emergency/:id` — Live First Responder & Emergency Clinical Dossier (allergies, medical alerts, finder contact form, one-tap calling).
- `/missing/:id` — Missing Pet Radar with instant sighting submission and WhatsApp dispatch.
- `/adopt/:id` — Adoption Showcase with verified behavioral indicators and shelter inquiry.
- `/verify/:id` — Digital Rabies & Vaccination Authenticity Certificate.
- `TAG-PROTOTYPE-001` Simulator — Interactive QR code modal allowing immediate testing of the emergency response flow without physical collar hardware.
