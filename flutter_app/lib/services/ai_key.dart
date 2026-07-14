// Baked-in default Groq API key so the AI assistant works out of the box for
// the whole family without anyone pasting a key.
//
// SECURITY NOTE: this key ships inside the app, so anyone who obtains the APK
// could extract and use it (spending your Groq free quota). That's an accepted
// trade-off for a privately shared family app. If it is ever misused, just
// regenerate the key at console.groq.com and replace it here, then rebuild.
const String kDefaultGroqApiKey =
    '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';
