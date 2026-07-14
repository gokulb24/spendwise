# Family Expense Tracker — Mobile App

A single-page, installable expense tracker (INR) that any family can use. Works offline once loaded, installs to your phone's home screen like a native app, and can optionally sync live across the whole family.

## Features
- **Family sync (optional):** sign in with email + password, create or join a family with an invite code, and everyone's entries sync live across phones. See **[SETUP-SYNC.md](SETUP-SYNC.md)**.
- **Works for any family:** member names are yours to set (not hardcoded).
- **Downloadable monthly PDF report** — one tap, from the ⋮ menu.
- Per-month income for each member
- Per-month category budgets + a directly-editable Total Budget override
- Add / edit / delete expenses, with dropdowns for category, member, payment
- Live KPIs (budget, spent, remaining, net savings) and charts by category & member
- Month switcher (current month through end of the financial year)
- Export / import your data as a JSON backup (move it between phones)
- Installable PWA with offline support

## Two modes
- **This device only** (default, no setup): data is stored privately on each phone via the browser. Nothing is shared automatically.
- **Family sync** (after a one-time Firebase setup): data lives in a shared, live-synced family. Follow **[SETUP-SYNC.md](SETUP-SYNC.md)** — about 5–10 minutes, done once by whoever sets up the app.

## Native Android app (Flutter)
A full Flutter port of this app lives in **[flutter_app/](flutter_app/)** — same features, same Firebase backend (web and Android share one live family book). To build and install it on a phone, follow **[flutter_app/BUILD-ANDROID.md](flutter_app/BUILD-ANDROID.md)**. It has been statically analyzed, unit/widget-tested, and web-compiled; producing the APK needs the Android toolchain (Android Studio) on your machine.

## Deploy to Vercel (easiest — no coding)
1. Go to https://vercel.com and sign up / log in (free).
2. Click **Add New… → Project**, then choose **Deploy** and look for the **drag-and-drop / upload** option (or install the Vercel CLI, see below).
3. Drag this whole `family-expense-app` folder in.
4. Vercel gives you a public URL like `https://your-app.vercel.app` in ~20 seconds.

### Alternative: Vercel CLI
```bash
npm i -g vercel
cd family-expense-app
vercel        # follow prompts; then:
vercel --prod # deploy to production
```

### Alternative: GitHub
Push this folder to a GitHub repo, then in Vercel click **Add New → Project → Import** that repo. No build settings needed — it's a static site.

## Install on your phone
Open your Vercel URL in the phone browser, then:
- **Android / Chrome:** tap the **Install** banner, or menu ⋮ → *Add to Home screen*.
- **iPhone / Safari:** tap **Share** → *Add to Home Screen*.

## Your data
Data is stored locally in each browser (localStorage), so it stays private on your device and is **not** shared across devices automatically. Use **menu ⋮ → Export** to back it up, and **Import** on another device to load it.

## Files
- `index.html` — the whole app (HTML/CSS/JS in one file)
- `firebase-config.js` — paste your Firebase keys here to enable family sync (see SETUP-SYNC.md)
- `SETUP-SYNC.md` — step-by-step guide to turn on cross-device family sync
- `manifest.webmanifest` — PWA metadata
- `sw.js` — service worker (offline cache)
- `icons/` — app icons
- `vercel.json` — hosting config (optional)
