# Google Play Store Publishing Checklist

This document covers everything needed to publish Only Me on Google Play.

---

## Pre-publish checklist

### 1. App signing (REQUIRED — currently using debug keys)

The release build in `android/app/build.gradle.kts` currently signs with debug keys:

```kotlin
release {
    signingConfig = signingConfigs.getByName("debug")  // ← CHANGE THIS
}
```

**Steps:**

1. Generate a release keystore (keep this file safe — if lost, you cannot update the app):
   ```bash
   keytool -genkey -v -keystore ~/onlyme-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias onlyme
   ```

2. Create `android/key.properties` (already in `.gitignore` — do NOT commit this):
   ```
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=onlyme
   storeFile=<path-to>/onlyme-release.jks
   ```

3. Update `android/app/build.gradle.kts`:
   ```kotlin
   val keystoreProperties = Properties()
   val keystorePropertiesFile = rootProject.file("key.properties")
   if (keystorePropertiesFile.exists()) {
       keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
   }

   android {
       signingConfigs {
           create("release") {
               keyAlias = keystoreProperties["keyAlias"] as String
               keyPassword = keystoreProperties["keyPassword"] as String
               storeFile = file(keystoreProperties["storeFile"] as String)
               storePassword = keystoreProperties["storePassword"] as String
           }
       }
       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("release")
               isMinifyEnabled = false
           }
       }
   }
   ```

4. Build the release AAB (preferred over APK for Play Store):
   ```bash
   flutter build appbundle --release
   # output: build/app/outputs/bundle/release/app-release.aab
   ```

### 2. App version

Currently `version: 1.1.0+2` in `pubspec.yaml`. For Play Store:
- **Version name** (`1.1.0`) — shown to users.
- **Version code** (`2`) — must increment with every upload, never reuse.

Update `pubspec.yaml` before each upload:
```yaml
version: 1.1.0+3   # bump the build number (+3, +4, ...)
```

### 3. App ID

Application ID: `com.webronic.onlyme` — set in `android/app/build.gradle.kts`. This cannot be changed after the first upload.

### 4. Min / target SDK

Set in `build.gradle.kts` via Flutter defaults. Verify:
```bash
flutter build appbundle --release 2>&1 | grep -i sdk
```
Play Store currently requires `targetSdk >= 34`.

### 5. Privacy policy URL

Play Store requires a privacy policy URL for apps that handle personal data. Options:
- Host `docs/privacy-policy.md` as a web page (GitHub Pages, Notion, your own site).
- Use a service like Termly or PrivacyPolicies.com.

You will enter this URL in the Play Console under **App content → Privacy policy**.

### 6. Content rating questionnaire

Complete in Play Console → **Policy → App content → Ratings**. For Only Me:

- Contains user-generated content: **No** (all data is private, local)
- Violence / sexual content: **No**
- Ads: **No**
- Location: **No**
- Personal data: **Yes** (stored locally only)
- Likely rating result: **Everyone (E)**

### 7. Data safety form

Play Console → **Policy → App content → Data safety**. Fill out as follows:

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | N/A — no data is transmitted |
| Do you provide a way for users to request data deletion? | **Yes** — deleting all entries or clearing app data |

Explain in the notes: "All data is stored locally on the user's device using Android SharedPreferences and internal storage. No data is transmitted to any server."

### 8. Permissions declaration

In Play Console → **App content → Permissions**, justify:
- `SCHEDULE_EXACT_ALARM` — "Used to fire task and event reminders at the user's exact scheduled time."
- `USE_FULL_SCREEN_INTENT` — "Used to display alarm-mode notifications on the lock screen."
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` — "Used to ensure scheduled alarms fire reliably on all devices. Prompted only when needed."

---

## Store listing

### App name
`Only Me`

### Short description (80 chars max)
`Private personal tracker — tasks, finance, gym, notes & more. No account needed.`

### Full description (4000 chars max)

```
Only Me is a fully private, local-only personal organiser. Everything stays on your device — no account, no cloud, no ads, no tracking.

WHAT'S INSIDE

📋 Tasks
Create tasks with categories, icons, and colour accents. Set exact reminders with optional Alarm mode — fires even on silent. Track streaks for daily habits.

💰 Finance
Log debts both ways (I owe / they owe). Record partial payments. Auto-marks settled when fully paid. Supports any currency symbol.

📅 Events
Plan upcoming events with a budget checklist. Set reminders up to one day in advance. Track estimated vs. actual spend per item.

🏋️ Gym
Build a custom weekly workout plan. Log sets, reps, and weight per exercise. Track your body weight over time with a built-in chart.

📸 Snapshots
A private photo journal organised by category (Hair / Body / Skin). Add notes and colour tints to each entry.

💸 Expenses
Quick daily expense tracking with category breakdown (Food, Transport, Shopping, and more).

📝 Notes
Simple, fast note-taking. No formatting needed.

🔗 Saved Links
Bookmark URLs with titles. Tap to open in your browser.

🔒 Vault
Store passwords and credentials privately on your device.

PRIVACY FIRST
No account required. No internet permission. No analytics. No ads. All data is stored in Android's sandboxed storage and never leaves your device.

BACKUP & RESTORE
Export all your data as a single JSON file and share it anywhere (Drive, email, etc.). Import on a new device to restore everything instantly — including images and your custom alarm sound.

REMINDERS THAT WORK
Two notification modes: standard (respects silent mode) and Alarm (bypasses silent, fires at alarm volume). Uses Android's AlarmClock API for maximum reliability — fires even when the app is cleared from recents.

CLEAN DESIGN
iOS-inspired dark UI with 6 accent colour options (Mint, Blue, Purple, Rose, Gold, Slate). Toggle dark/light from the settings.
```

### Category
**Productivity** (primary) — or Lifestyle

### Tags
personal tracker, tasks, habits, finance, gym tracker, notes, password manager, expense tracker, journal, offline, no account

---

## Screenshots required

Play Store requires at least 2 screenshots per device type. Recommended:

| Screen | What to show |
|---|---|
| 1 | Home screen with tasks + finance summary |
| 2 | Tasks screen with a reminder set and alarm mode on |
| 3 | Finance / debt screen |
| 4 | Events screen with budget checklist |
| 5 | Gym screen — weekly strip + exercise list |
| 6 | More screen — notifications section with all grants |

Take on a **Pixel 6** or **Pixel 8** (or emulator) at 1080 × 2400 px. Play Store also accepts a feature graphic (1024 × 500 px).

---

## Build commands

```bash
# Verify no analysis issues
flutter analyze

# Run tests
flutter test

# Build release AAB for Play Store
flutter build appbundle --release

# Build split APKs for sideloading / testing
flutter build apk --release --split-per-abi
```

---

## After first publish

1. Add the Privacy Policy URL in Play Console → App content.
2. Complete the Data Safety form.
3. Complete the Content Rating questionnaire.
4. For future updates: bump version code in `pubspec.yaml`, build new AAB, upload to the release track.

---

## Sensitive notes

- Keep `android/key.properties` and the `.jks` keystore file out of version control. They are in `.gitignore`.
- Back up the keystore to multiple secure locations. Losing it means you cannot update the app.
- The `storeFile` path in `key.properties` should be an absolute path on the build machine.
