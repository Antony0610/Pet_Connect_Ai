# 🚀 Free Vercel Deployment Guide for PetConnect AI Web Portal

You do **NOT** need to buy any domain like `petconnect.ai`. You can deploy the web portal to **Vercel for 100% free** under `petconnect-ai.vercel.app` (or any free subdomain you choose) in under 2 minutes.

---

## ⚡ Option A: Instant Command Line Deployment (1 Minute)

1. Open PowerShell or Terminal and navigate to the `web_portal` directory:
   ```bash
   cd d:\Downloads\Pet_Connect_Ai\web_portal
   ```

2. Run Vercel CLI directly via npx (no global install needed):
   ```bash
   npx vercel
   ```

3. Follow the 4 simple prompts:
   - **Set up and deploy?**: `y`
   - **Which scope?**: Press `Enter` (your personal free Vercel account)
   - **Link to existing project?**: `N`
   - **What's your project's name?**: `petconnect-ai`
   - **In which directory is your code located?**: `./`

4. For production deployment:
   ```bash
   npx vercel --prod
   ```

Done! Your site is live immediately at:
`https://petconnect-ai.vercel.app`

---

## 🌐 Option B: GitHub 1-Click Auto Deployment

1. Push this repository to GitHub.
2. Go to [https://vercel.com/new](https://vercel.com/new) and log in with your free account.
3. Import your repository and set the **Root Directory** to `web_portal`.
4. Click **Deploy**.

Every time you scan a Missing Pet Poster or Emergency Pass QR code, it will instantly open the live webpage on any phone!

---

## 📱 Features Included in the Web Portal
- `/missing/:id` — Live Missing Pet Poster with GPS directions, Call Guardian button, WhatsApp sighting alert, and online sighting form.
- `/emergency/:id` — First Responder / Vet Emergency Clinical Dossier.
- `/adopt/:id` — Pet Adoption Listing with instant inquiry.
- `/verify/vaccine/:id` — Digital vaccination authenticity certificate.
- `index.html` — Platform overview landing page.
