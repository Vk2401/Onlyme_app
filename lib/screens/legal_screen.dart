import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

// ── Privacy Policy ────────────────────────────────────────────────────────────

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => _LegalScreen(
        title: 'Privacy Policy',
        lastUpdated: '26 April 2026',
        sections: _privacySections,
      );
}

// ── Terms & Conditions ────────────────────────────────────────────────────────

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => _LegalScreen(
        title: 'Terms & Conditions',
        lastUpdated: '26 April 2026',
        sections: _termsSections,
      );
}

// ── Shared renderer ───────────────────────────────────────────────────────────

class _LegalScreen extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final List<_Section> sections;
  const _LegalScreen({
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppState>().theme;
    final state = context.read<AppState>();
    return Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
        child: Row(children: [
          IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: theme.ink, size: 22),
            onPressed: () => state.setScreen('more'),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.ink,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ]),
      ),
      // Body
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Effective date: $lastUpdated',
                style: TextStyle(fontSize: 12, color: theme.muted),
              ),
              const SizedBox(height: 20),
              for (final s in sections) ...[
                Text(
                  s.heading,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.ink,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.body,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.ink2,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                'Contact: vipvasanth433@gmail.com',
                style: TextStyle(fontSize: 13, color: theme.muted),
              ),
              const SizedBox(height: 4),
              Text(
                'Vip Vasanth — Independent Developer',
                style: TextStyle(fontSize: 13, color: theme.muted),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}

class _Section {
  final String heading;
  final String body;
  const _Section(this.heading, this.body);
}

// ── Privacy Policy content ────────────────────────────────────────────────────

const _privacySections = [
  _Section(
    '1. Introduction',
    'Only Me is a personal tracker application developed by Vip Vasanth, an independent developer. This Privacy Policy explains what data the app stores, how it is stored, and your rights as a user.\n\nShort version: Only Me stores all your data locally on your device. No data is ever collected, transmitted, or shared with anyone.',
  ),
  _Section(
    '2. Information the app stores',
    'Only Me stores the following information locally on your device only:\n\n'
    '• Tasks, debts, events, gym plan, weight log — Android SharedPreferences\n'
    '• Snapshot / journal images — App internal documents directory\n'
    '• Notes, saved links — Android SharedPreferences\n'
    '• Vault entries (titles, usernames, encrypted passwords, URLs) — Android SharedPreferences\n'
    '• Expenses — Android SharedPreferences\n'
    '• Profile (name, date of birth, phone, currency) — Android SharedPreferences\n'
    '• Custom alarm sound — App internal documents directory\n'
    '• App preferences (theme, accent colour) — Android SharedPreferences\n\n'
    'What the app does NOT collect: no analytics, no advertising SDKs, no tracking, no data transmitted to any server, no account or registration required, no access to contacts, call logs, SMS, or location.',
  ),
  _Section(
    '3. Permissions used',
    '• CAMERA — Capturing photos for Snapshots\n'
    '• READ_MEDIA_IMAGES / READ_EXTERNAL_STORAGE — Picking existing photos for Snapshots\n'
    '• POST_NOTIFICATIONS — Displaying scheduled reminders\n'
    '• SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM — Firing reminders at the exact scheduled time\n'
    '• RECEIVE_BOOT_COMPLETED — Re-scheduling reminders after device reboot\n'
    '• VIBRATE, WAKE_LOCK — Playing alarm notifications\n'
    '• USE_FULL_SCREEN_INTENT — Showing alarm notifications on a locked screen\n'
    '• FOREGROUND_SERVICE — Supporting alarm delivery\n'
    '• REQUEST_IGNORE_BATTERY_OPTIMIZATIONS — Ensuring alarm notifications fire reliably\n\n'
    'All permissions are used solely for the features described above. No permission is used for data collection or advertising.',
  ),
  _Section(
    '4. Data storage and security',
    'All data is stored using Android\'s SharedPreferences and the app\'s internal documents directory. This storage is sandboxed (inaccessible to other apps), device-local (never transmitted off the device), and secured as follows:\n\n'
    '• Vault passwords are encrypted on the device before being stored. They are never stored or exported as plain text.\n'
    '• Other app data (tasks, notes, profile, etc.) is stored in plain JSON within the sandboxed storage area.\n\n'
    'A device screen lock is recommended to protect your data from physical access.',
  ),
  _Section(
    '5. Backup files',
    'The Export feature creates a JSON file containing all your data. Vault passwords are included in their encrypted form — never as plain text. The file is generated locally on your device and shared via your device\'s native share sheet to a destination you choose.\n\nYou are responsible for the security of exported backup files. Store them in a location you control and trust.',
  ),
  _Section(
    '6. Third-party services',
    'Only Me does not integrate any third-party analytics, advertising, crash-reporting, or cloud-sync services. Open-source Flutter packages used (flutter_local_notifications, shared_preferences, path_provider, image_picker, file_picker, share_plus, url_launcher, google_fonts) operate locally only and do not send data to external servers.',
  ),
  _Section(
    '7. Children\'s privacy',
    'Only Me does not knowingly collect information from children under the age of 13. The app has no account registration and collects no data that leaves the device.',
  ),
  _Section(
    '8. Data deletion',
    'You can delete all app data at any time by:\n\n'
    '• Deleting individual items within the app\n'
    '• Android Settings → Apps → Only Me → Storage → Clear Data\n'
    '• Uninstalling the app (all data is permanently deleted)\n\n'
    'There is no data stored on any server to request deletion of.',
  ),
  _Section(
    '9. Changes to this policy',
    'If material changes are made to this Privacy Policy, the updated policy will be included in the next app update. The effective date at the top of this document will be revised. Continued use of the app after an update constitutes acceptance of the revised policy.',
  ),
];

// ── Terms & Conditions content ────────────────────────────────────────────────

const _termsSections = [
  _Section(
    '1. Acceptance of terms',
    'By downloading, installing, or using the Only Me application ("app"), you agree to be bound by these Terms and Conditions. If you do not agree to these Terms, do not use the app.',
  ),
  _Section(
    '2. Description of the app',
    'Only Me is a private, local-only personal productivity and tracking application for Android. It includes task management, finance/debt tracking, event planning, gym tracking, a snapshot journal, notes, saved links, a password vault, and expense tracking. All data is stored on your device. The app does not require an account and does not connect to any external servers.',
  ),
  _Section(
    '3. License to use',
    'Only Me is developed and owned by Vip Vasanth, an independent developer. You are granted a personal, non-exclusive, non-transferable, revocable license to use the app on your Android device for personal, non-commercial purposes.\n\nYou may not:\n\n'
    '• Copy, modify, or distribute the app or its source code without explicit written permission\n'
    '• Reverse-engineer, decompile, or disassemble the app except as permitted by applicable law\n'
    '• Use the app for any unlawful purpose\n'
    '• Attempt to extract, scrape, or reproduce the app\'s assets, icons, or fonts for use outside the app',
  ),
  _Section(
    '4. User data and responsibility',
    'All data you enter into the app is stored exclusively on your device. You are solely responsible for:\n\n'
    '• The accuracy of the data you enter\n'
    '• Keeping regular backups using the Export feature\n'
    '• The security of exported backup files\n'
    '• The security of your device\n\n'
    'The developer is not responsible for any loss of data resulting from device failure, accidental deletion, uninstallation, or any other cause.',
  ),
  _Section(
    '5. Vault / password manager',
    'The app includes a password vault feature. Vault passwords are encrypted on the device before being stored — they are never written or exported as plain text. The encryption is applied locally using a key embedded in the app.\n\n'
    'Recommendations: use a device screen lock to protect physical access; keep exported backup files in a secure, private location. Use of the vault feature is at your own risk. The developer accepts no liability for any loss or compromise of credentials stored in the app.',
  ),
  _Section(
    '6. Notifications and alarms',
    'The app can schedule local OS notifications and alarms. The reliability of these notifications depends on your device\'s operating system version and settings, whether you have granted the required permissions, and your device manufacturer\'s battery optimisation policies.\n\nThe developer does not guarantee that every scheduled notification will fire at the exact time requested and is not liable for any consequences of a missed notification or alarm.',
  ),
  _Section(
    '7. Disclaimer of warranties',
    'THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.\n\nTHE DEVELOPER DOES NOT WARRANT THAT THE APP WILL MEET YOUR REQUIREMENTS, WILL BE UNINTERRUPTED OR ERROR-FREE, OR THAT ANY ERRORS WILL BE CORRECTED.',
  ),
  _Section(
    '8. Limitation of liability',
    'TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THE DEVELOPER OF ONLY ME SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF DATA, LOSS OF PROFITS, OR BUSINESS INTERRUPTION, ARISING OUT OF OR IN CONNECTION WITH YOUR USE OF THE APP.',
  ),
  _Section(
    '9. Intellectual property',
    'The Only Me app, including its design, icons, graphics, and code, is the property of Vip Vasanth and is protected by copyright and other applicable intellectual property laws. The "Only Me" name and branding are proprietary to the developer.\n\nOpen-source software libraries used by the app are subject to their respective licenses.',
  ),
  _Section(
    '10. Modifications',
    'The developer reserves the right to modify or discontinue the app (or any feature thereof) at any time, and to update these Terms. Material changes will be communicated through app updates. Continued use after an update constitutes acceptance.',
  ),
  _Section(
    '11. Governing law',
    'These Terms shall be governed by and construed in accordance with the laws of India, without regard to its conflict of law provisions. Any disputes shall be subject to the exclusive jurisdiction of the courts of India.',
  ),
];
