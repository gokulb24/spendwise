# Family Expense Tracker — Enhancement Roadmap

The big enhancement brief is a multi-phase program. **Phase 1 (Material 3 redesign
+ navigation) is done and verified.** The rest is grouped into phases below, each
with the setup/keys it needs, so you can pick what to build next.

---

## ✅ Phase 1 — DONE: Material 3 redesign + navigation
- Full M3 theme: light / dark / **system**, dynamic color (Android 12+ wallpaper),
  M3 typography, cards, buttons, dialogs, bottom sheets, chips, snackbars.
- Bottom **NavigationBar**: Dashboard · Expenses · Reports · Profile.
- Central **FAB** → Quick-Add expense bottom sheet.
- Dashboard: gradient welcome header, month selector, **Financial Health score**,
  KPI cards, income, charts, budget & member tables, recent transactions, pull-to-refresh.
- Expenses tab: **search** + member filter chips + category filter + running total,
  swipe-to-delete, tap-to-edit.
- Reports tab: monthly summary + PDF download.
- Profile tab: account, **theme switcher**, family management, invite code, logout.
- All existing features preserved; every screen theme-aware; verified with analyze,
  unit/widget tests, and light/dark screenshots.

No external services or keys were required for Phase 1.

---

## Phase 2 — Self-contained data features (no external services, no keys)
These are pure Firestore + UI, low risk, and reuse the new components.

### ✅ Phase 2a — DONE (this batch)
- **Savings goals + Emergency fund** — `goals` subcollection; new **Goals tab** with
  progress rings, target/deadline, "Add money" contributions, edit/delete.
- **Recurring transactions** — `recurring` subcollection + an on-open generator that
  materialises due occurrences (rent, EMIs, salary, subscriptions). Pause/resume/delete,
  managed from Profile → Recurring transactions. Generated entries use deterministic ids
  so two devices can't create duplicates.
- **Expense tags & notes** — `tags[]` + `note` on each expense; shown in the list and
  included in Expenses-tab search.
- **Duplicate detection** — warns when a new expense matches an existing amount+category+day.

> All Phase 2a data lives in **new subcollections/fields**, so existing users and the
> web app keep working unchanged (backwards-compatible).

### ✅ Phase 2b (partial) — DONE
- **Debt tracker** — `debts` subcollection. Track home/gold/personal/car/education/credit-card
  loans with amount, interest %, EMI, and the date taken. Record each repayment (with date =
  "when it was paid"), see payment history, payoff progress and total outstanding. Shown on
  the dashboard (summary card) and Profile → Debt tracker.
- **Unlimited month picker** — replaced the Jul→Mar financial-year dropdown with a
  calendar-style **month/year picker**: navigate to any month (past or future) and the whole
  app shows that month's real data. Used on the dashboard header and the Expenses tab.

> Verified: analyze clean, 14 tests pass (incl. recurring-generator + debt computations),
> web compiles, Debts screen & month picker screenshotted.

### ✅ Phase 2b (more) — DONE
- **Custom categories** — the "Category Budget vs. Actual" list is now editable: add/remove
  categories (stored on the family doc) and they flow through the budget table, charts,
  expense/recurring pickers and the Expenses filter. Falls back to the built-in defaults.
- **Investment tracker** — `investments` subcollection. Track mutual funds, stocks, SIPs, FDs,
  PPF, gold, real estate, bonds, crypto with invested amount and current value; see per-holding
  returns (₹ and %, green/red) and total portfolio value. Profile → Investments.
- **Chart fixes** — centred the category donut; the member bar chart now uses clean, evenly
  divided axis intervals so bars line up with the labels even above ₹8k.
- **Unlimited month/calendar picker** (from the previous change).

> Verified: analyze clean, 18 tests pass (added axis + investment math tests), web compiles,
> charts + Investments screen screenshotted.

### ⏳ Phase 2b — still remaining (no keys)
- **Subscription tracker** view (built on the recurring engine) with monthly/yearly totals.
- **Bill reminders (in-app)** — `bills` with due dates; dashboard "Upcoming / Due / Overdue".
- **Calendar view** (daily expenses) + **spending heatmap** (GitHub-style).
- **Net worth** = investments (assets) − debts (liabilities), with a trend chart.
- **Wishlist**, **family allowance**, **shared wallet** — small subcollection features.

## ✅ Reminders + AI (DONE)
- **Reminders with on-device notifications** — create reminders ("Buy X today", "Pay the
  bill") with a date & time; the app fires a local notification when due. Overdue / Upcoming /
  Done sections, mark-done, edit/delete. `reminders` subcollection; scheduled via
  `flutter_local_notifications` (inexact alarms, no special permission). Profile → Reminders,
  plus a "Send a test" button. (Notification firing needs a real device to observe.)
- **AI Assistant** — summarise the tracker and answer questions in plain language. Uses
  **`openai/gpt-oss-120b` via Groq** (OpenAI-compatible API). Paste a free Groq API key once
  (stored on-device); a chat screen with quick prompts ("Summarise this month", "Where can we
  cut spending?", "Who spent the most?"). The current month's tracker data is sent as context.
  Dashboard "AI Assistant" card + the chat screen. (Live answers need a Groq API key + network.)

> OCR intentionally **skipped** per request.

## Phase 3 — Receipts (needs device permissions / storage)
- **Receipt upload** (image/PDF) → Firebase **Storage** (must enable Storage + rules;
  Storage may require the Blaze pay-as-you-go plan).
- **OCR scan** to auto-fill merchant / amount / date:
  - On-device, free: `google_mlkit_text_recognition` (adds native ML Kit; larger app).
  - Cloud, higher accuracy: Google Cloud Vision or similar (**API key + billing**).
- Voice input: `speech_to_text` (mic permission).

## Phase 4 — Notifications (needs FCM setup)
- **Bill/renewal reminders** as real push notifications via **Firebase Cloud Messaging**
  + `flutter_local_notifications`. Requires notification permission and (for scheduled/
  server push) a small Cloud Function. iOS would also need an APNs key.

## Phase 5 — AI insights & natural-language search (needs an AI API key + budget)
- **AI Insights page**: monthly summary, overspending alerts, savings suggestions,
  anomaly detection, forecast.
- **Natural-language search**: "How much did we spend on groceries?", "Who spends the most?"
- Recommended: the **Claude API** (Anthropic). This needs an **API key** and has
  per-use cost. Best practice is to call it through a tiny backend / Cloud Function so
  the key isn't shipped in the app. I can wire this up when you're ready to add a key.

## Phase 6 — Reports & polish
- Upgrade the PDF: charts, goals, health score, net worth, debt/savings summaries.
- Multi-financial-year history & comparison.
- Tablet two-pane layouts; accessibility pass (TalkBack, large fonts, contrast);
  pagination/lazy-loading for very large histories.

---

## What needs your setup / keys (summary)
| Feature | Needs |
|---|---|
| Phase 2 (all) | nothing — I can build directly |
| Receipt upload | Enable Firebase **Storage** (may need Blaze plan) |
| OCR (cloud) | Cloud Vision **API key** + billing (on-device ML Kit is free) |
| Push notifications | **FCM** setup (+ Cloud Function for scheduling; APNs key for iOS) |
| AI insights / NL search | **Claude API key** + small backend, usage cost |

## Suggested next step
**Phase 2** gives the most new capability with zero setup and zero risk to your
live data. Tell me which items matter most (e.g. recurring transactions + savings
goals + custom categories) and I'll build that batch next.
