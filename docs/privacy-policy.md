# Privacy Policy — Only Me

**Effective date:** 2026-04-26
**Last updated:** 2026-04-26

---

## 1. Introduction

Only Me ("the app", "we", "our") is a personal tracker application developed by Webronic ("developer", "I"). This Privacy Policy explains what data the app collects, how it is stored, and your rights as a user.

**Short version:** Only Me stores all your data locally on your device. We do not collect, transmit, or share any personal information with anyone.

---

## 2. Information the app collects

Only Me stores the following information **locally on your device only**:

| Data | Where stored | Purpose |
|---|---|---|
| Tasks, debts, events, gym plan, weight log | Android SharedPreferences | Core app functionality |
| Snapshots / journal images | App internal documents directory | Display in Snapshots screen |
| Notes, saved links | Android SharedPreferences | Core app functionality |
| Vault entries (titles, usernames, passwords, URLs) | Android SharedPreferences | Password manager feature |
| Expenses | Android SharedPreferences | Expense tracking |
| Profile (name, date of birth, phone number, currency) | Android SharedPreferences | Personalisation |
| Custom alarm sound file | App internal documents directory | Alarm notifications |
| App preferences (theme, accent colour, last screen) | Android SharedPreferences | UI state |

### What we do NOT collect

- We do **not** collect any analytics or usage statistics.
- We do **not** use advertising SDKs or tracking libraries.
- We do **not** transmit any data to any server, cloud service, or third party.
- We do **not** require an account or any form of registration.
- We do **not** access your contacts, call logs, SMS, or location.

---

## 3. Permissions used

| Permission | Why it is needed |
|---|---|
| `CAMERA` | Capturing photos for Snapshots |
| `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE` | Picking existing photos for Snapshots |
| `POST_NOTIFICATIONS` | Displaying scheduled reminders |
| `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | Firing reminders at the exact scheduled time |
| `RECEIVE_BOOT_COMPLETED` | Re-scheduling reminders after device reboot |
| `VIBRATE`, `WAKE_LOCK` | Playing alarm notifications |
| `USE_FULL_SCREEN_INTENT` | Showing alarm notifications on a locked screen |
| `FOREGROUND_SERVICE` | Supporting alarm delivery |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Ensuring alarm notifications fire reliably on all devices |

All permissions are used solely for the features described above. No permission is used for data collection or advertising.

---

## 4. Data storage and security

All data is stored using Android's SharedPreferences and the app's internal documents directory. This storage is:

- **Sandboxed** — inaccessible to other apps under normal conditions.
- **Device-local** — never transmitted off the device.
- **Not encrypted at rest** — data in SharedPreferences and the documents directory is plain text / plain files. Users should be aware that on a rooted device or if a full device backup is performed, data (including vault entries) may be readable.

We recommend setting a device screen lock and keeping your device's operating system up to date.

---

## 5. Backup files

The app's "Export data" feature creates a JSON file containing all your data, including vault entries. This file is:

- Generated locally on your device.
- Shared via your device's native share sheet to a destination you choose (Google Drive, email, etc.).
- Not transmitted by the app to any server.

**You are responsible for the security of exported backup files.** Store them in a location you control and trust.

---

## 6. Third-party services

Only Me does **not** integrate any third-party analytics, advertising, crash-reporting, or cloud-sync services. The following open-source Flutter packages are used for local functionality only:

- `flutter_local_notifications` — local OS notifications
- `shared_preferences` — on-device key-value storage
- `path_provider` — accessing standard device directories
- `image_picker` — camera and gallery access for Snapshots
- `file_picker` — picking audio files for custom alarm sounds
- `share_plus` — opening the native share sheet for backup export
- `url_launcher` — opening bookmarked URLs in the browser
- `google_fonts` — loading fonts from the bundled font files

None of these packages send data to external servers in the context of this app.

---

## 7. Children's privacy

Only Me does not knowingly collect information from children under the age of 13. The app has no account registration and collects no data that leaves the device, making it safe for users of all ages. If you are a parent or guardian and believe your child has stored sensitive information in the app, you can delete it directly within the app or by uninstalling the app.

---

## 8. Data deletion

You can delete all app data at any time by:

- Deleting individual items within the app.
- Going to Android Settings → Apps → Only Me → Storage → Clear Data.
- Uninstalling the app (all data is permanently deleted).

There is no data stored on any server to request deletion of.

---

## 9. Changes to this policy

If we make material changes to this Privacy Policy, the updated policy will be included in the next app update. The "Last updated" date at the top of this document will be revised. Continued use of the app after an update constitutes acceptance of the revised policy.

---

## 10. Contact

If you have questions about this Privacy Policy, please contact:

**Webronic**
Email: [your-support-email@example.com]
Website: [your-website.com]

---

*This Privacy Policy applies to the Only Me Android application published on the Google Play Store.*
