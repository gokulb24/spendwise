# Turn on Family Sync (one-time, ~5–10 minutes)

By default the app saves data **only on each phone**. To make everyone in the
family share one live expense book — where your brother adds an expense and it
instantly shows on your phone — you connect a free **Firebase** project once.
It's Google's service; the free tier is far more than a family will ever use.

You only do this **once**, on the app itself. After that, family members just
open the app, sign up with email + password, and create or join a family — they
never touch Firebase.

---

## Step 1 — Create the Firebase project
1. Go to <https://console.firebase.google.com> and sign in with a Google account.
2. Click **Add project** → give it any name (e.g. `family-expenses`) → keep
   clicking **Continue** → **Create project**. (You can turn Google Analytics off.)

## Step 2 — Turn on Email/Password logins
1. In the left menu open **Build → Authentication → Get started**.
2. Under **Sign-in method**, click **Email/Password**, toggle it **Enable**, **Save**.

## Step 3 — Create the database
1. Left menu **Build → Firestore Database → Create database**.
2. Choose a location near you → start in **Production mode** → **Enable**.

## Step 4 — Paste the security rules
1. In **Firestore Database → Rules**, replace everything with the rules below,
   then click **Publish**. These make sure only signed-in family members can read
   or change a family's data.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Each user's private pointer to their family
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }

    match /families/{fid} {
      // signed-in users can look up a family (needed to join by invite code)
      allow read:   if request.auth != null;
      allow create: if request.auth != null;
      // existing members can edit; a signed-in user may add themselves (join)
      allow update, delete: if request.auth != null && (
        resource.data.members[request.auth.uid] != null ||
        request.resource.data.members[request.auth.uid] != null
      );

      // expenses + settings: only members of this family
      match /{document=**} {
        allow read, write: if request.auth != null &&
          get(/databases/$(database)/documents/families/$(fid)).data.members[request.auth.uid] != null;
      }
    }
  }
}
```

## Step 5 — Get your project's keys
1. Click the **gear icon → Project settings**.
2. Scroll to **Your apps**, click the **`</>` (Web)** icon.
3. Give it a nickname (e.g. `web`), click **Register app**.
4. Firebase shows a `const firebaseConfig = { ... }` block. Copy the **values**
   inside the `{ }` (apiKey, authDomain, projectId, etc.).

## Step 6 — Put the keys in the app
1. Open the file **`firebase-config.js`** (in this app folder).
2. Fill in the empty quotes with the matching values from Step 5. It should look like:

```js
window.FIREBASE_CONFIG = {
  apiKey: "AIza…",
  authDomain: "family-expenses.firebaseapp.com",
  projectId: "family-expenses",
  storageBucket: "family-expenses.appspot.com",
  messagingSenderId: "1234567890",
  appId: "1:1234567890:web:abc123"
};
```

3. Save the file and **re-deploy** (drag the folder to Vercel again, or `vercel --prod`).

That's it. It's safe for these keys to be public — Firebase is designed that way,
and the security rules above are what actually protect your data.

---

## How your family uses it
1. Everyone opens the app URL and taps **⋮ → 👨‍👩‍👧 Family sync & account**.
2. **You (first person):** create an account → **Create family** → give it a name and
   list the member names you want to track. You'll get a **6-character invite code**.
3. **Everyone else:** create their own account → **Join family** → enter your invite code.
4. Done. Any expense anyone adds now appears on every family member's phone within a
   second, and works offline (it syncs when they're back online).

You can change the family name, invite code holders, and tracked member names any
time from the same **Family sync & account** screen.

## Good to know
- **Cost:** A family's usage sits comfortably in Firebase's free "Spark" plan.
- **Privacy:** Only people who signed in *and* joined your family (via the invite
  code) can see the data. Keep the invite code within the family.
- **No sync set up?** The app still works fully on each device, and you can move data
  between phones with **⋮ → Export / Import**.
