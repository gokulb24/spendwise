# Publishing SpendWise to Google Play

Everything you need to put the app on the Play Store. The signed App Bundle is
already built; the rest is the Google side + a couple of decisions.

---

## 0) 🔐 BACK UP YOUR SIGNING KEY (do this first — critical)
The app is now signed with a real **upload key**. If you lose it, **you can never
update the app again** (you'd have to publish a brand-new listing). Save these somewhere
safe (password manager + a backup drive):

- **Keystore file:** `/Users/gokulb/family-expense-app/upload-keystore.jks`
- **Store & key password:** _(not stored in this repo — see `android/key.properties`
  on your Mac, and your password manager backup)_
- **Key alias:** `upload`

(The password lives in `flutter_app/android/key.properties` — keep that file private;
never share it or put it in a public repo.)

## 1) The file to upload
```
flutter_app/build/app/outputs/bundle/release/app-release.aab
```
Rebuild anytime with: `flutter build appbundle --release`
(Bump the version in `pubspec.yaml` — e.g. `1.0.0+1` → `1.0.1+2` — before each new upload.)

## 2) App name — **SpendWise** ✅
Already set as the on-device name (`android:label`) and across the app UI, the web
manifest, and this listing. Use **SpendWise** as the app title in Play Console.
(If "SpendWise" is taken on Play, fall back to "SpendWise — Family Expenses".)

## 3) Store listing text
**Short description (≤80 chars):**
> Track your whole family's expenses, budgets, goals & loans — synced live, with AI.

**Full description:**
> SpendWise keeps your entire family's money in one place — and everyone stays in
> sync automatically. When your brother adds an expense, it shows on your phone within a second.
>
> • Add expenses in seconds — category, member, payment method, tags and notes
> • Live family sync — one shared expense book across everyone's phones
> • Monthly budgets, income by member, and a clear budget-vs-actual view
> • Beautiful charts — spending by category and by member
> • Savings goals & emergency fund with progress tracking
> • Debt tracker — home, gold, personal & car loans, EMIs and payment history
> • Investment tracker — mutual funds, stocks, gold, FDs with returns
> • Recurring transactions — rent, EMIs and subscriptions added automatically
> • Reminders with notifications — "buy this today", bill due dates and more
> • AI Assistant — summarise your month and ask questions in plain language
> • One-tap monthly PDF report
> • App lock with fingerprint / PIN
> • Works offline and syncs when you're back online
>
> All amounts in Indian Rupees (₹). Free to use.

**Category:** Finance   **Tags:** budget, expense, family, money manager

## 4) Data Safety form answers (Play Console → App content → Data safety)
Declare that the app **collects** and the data is **encrypted in transit**:
| Data type | Collected? | Shared? | Purpose |
|---|---|---|---|
| Name | Yes | No | Account, app functionality |
| Email address | Yes | No | Account management |
| Financial info (spending, budgets, etc.) | Yes | No | App functionality |
| App activity / in-app content you enter | Yes | No | App functionality |
- Data is **encrypted in transit**: Yes
- Users can **request deletion**: Yes (via the email in the privacy policy)
- No data sold. No ads. No location/contacts/photos.
> If you enable the AI feature, note that the current month's summary is sent to Groq to
> answer questions — you can mention this under "financial info → shared with third party"
> if you want to be extra conservative.

## 5) Privacy Policy URL (required)
Host `privacy-policy.html` (in the project root) and use its public URL. Easiest options:
- Deploy your web app folder to Vercel → URL becomes `https://<your-app>.vercel.app/privacy-policy.html`
- Or upload the file to GitHub Pages / Google Sites and use that link.

## 6) Screenshots (need 2–8; phone)
Good ready-made renders are in `flutter_app/test/goldens/` (dashboard light & dark,
goals, investments, debts, expenses). I can also capture fresh ones from your phone when
it's unlocked. Play also wants a **512×512 app icon** (your logo) and a **1024×500 feature graphic**
(I can generate one).

## 7) Steps only you can do (Google account)
1. Create a **Google Play Developer account**: https://play.google.com/console — **$25 one-time**,
   then complete **identity verification** (can take 1–2 days).
2. For a **paid app**: set up a **Payments profile** (bank account) under Play Console → Setup → Payments.
3. **Create app** → fill store listing (text above) + screenshots + privacy policy URL.
4. **Production → Create release** → upload `app-release.aab` → let Google enable **Play App Signing** (recommended).
5. Complete **Data safety**, **Content rating** (finance app, no sensitive content), **Target audience**.
6. Set the **price** (₹49–₹99) under Monetisation → set as **Paid**.
7. Submit for review (first review often 1–7 days).

## 8) ⚠️ After you upload — keep Google Sign-In working
Play re-signs your app with **Google's** key, so you must add that key's SHA-1 to Firebase:
1. Play Console → your app → **Setup → App signing** → copy the **SHA-1** under
   "App signing key certificate".
2. Firebase Console → Project settings → your Android app → **Add fingerprint** → paste it → Save.
(I already registered your upload key's SHA-1, so Google Sign-In works on the build you test locally.)

## 9) Known review considerations
- **USE_EXACT_ALARM permission** (used for reminders): Play limits this to alarm/reminder-type
  apps. A reminder feature qualifies, but if review objects I can switch reminders to the
  user-granted `SCHEDULE_EXACT_ALARM` flow instead.
- **Financial app**: keep the listing factual; don't imply it's a licensed financial service.
- **applicationId** is `com.familyexpense.family_expense_tracker` (permanent once published).

## 10) Security hardening — **DONE** ✅
Firestore rules are now locked down (deployed 2026-07):
- A family document (names + member emails) is readable **only by its members** —
  no signed-in stranger can read or list families anymore.
- Joining uses a separate `invites/{code}` lookup collection that holds **only** a
  family id (no personal data) and can't be enumerated; a non-member can add **only
  themselves** to a family and nothing else.
- All family sub-data (expenses, goals, debts, investments, reminders) stays members-only.
- Existing families were backfilled with invite docs, so their share codes still work.

Rules live in `firebase-project/firestore.rules`; redeploy with
`firebase deploy --only firestore:rules --project family-expenses-2b31c`.
