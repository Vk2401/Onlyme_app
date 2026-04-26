# Only Me — User Guide

**Only Me** is a private, local-only personal tracker. Everything is stored on your device — no account, no cloud, no ads.

---

## Getting started

When you first open the app you land on the **Home** screen. The bottom bar has five quick tabs; swipe or tap to navigate. Tap the **+** button in the centre of the bottom bar to quickly add a task, event, note, link, or expense.

Your name and currency symbol are set in **More → Profile → Edit**. Set the currency symbol once and it applies everywhere.

---

## Tasks

Track anything you need to do — habits, chores, one-off tasks.

### Adding a task
1. Tap **+** → **Task**, or open the Tasks screen and tap the **+** button.
2. Give it a title, pick a time label (e.g. "Morning"), category, icon, and colour.
3. **Reminder** (optional) — tap "No reminder" to set a date and time. The OS will notify you at that moment even if the app is closed.
4. **Alarm mode** (optional) — appears below the reminder when a time is set. Toggle it on to make the reminder fire at full alarm volume, bypassing silent mode.
5. Tap **Save**.

### Managing tasks
- **Tabs** — Today / Upcoming / All.
- **Tick the checkbox** to mark done. Completing a task cancels its reminder automatically.
- **Swipe left** on a task row to delete (you'll be asked to confirm).
- **Long-press** to edit.

### Streaks
The streak counter tracks how many consecutive days you've completed a task. Increment it manually in the edit sheet for now.

---

## Finance (Debts)

Track money you owe others or they owe you.

### Adding a debt
1. Tap **+** → **Debt**, or open Finance and tap **+**.
2. Choose direction: "I owe" or "They owe".
3. Enter the person's name, total amount, due date, and an optional note.
4. Tap **Save**.

### Logging payments
- Tap **Pay** on a debt card to record a payment. Quick-amount chips let you pay common fractions quickly.
- When `paid ≥ total`, the debt is automatically marked **Settled**.

### Currency
The currency symbol shown everywhere is set in **More → Profile → Currency**. Supported presets: ₹ $ € £ ¥. You can also type a custom symbol (up to 3 characters).

---

## Events

Plan future events with a budget checklist.

### Adding an event
1. Tap **+** → **Event**, or open Events and tap **+**.
2. Enter a title, the event date (shown as "X days away"), icon, and colour.
3. **Reminder** — optional date+time for an OS notification. Two notifications fire: one the day before, one at the event time.
4. **Alarm mode** — toggle on to make the at-time notification an alarm.
5. Tap **Save**.

### Budget checklist
- Tap the **+** icon on an event card to add a budget item (label + estimated cost).
- When you spend, long-press the item and enter the actual amount.
- The summary card shows estimated total vs. actual spend.
- Swipe a budget item left to delete it.

---

## Gym

Plan and track your weekly workout routine.

### Setting up your plan
1. Open **Gym**.
2. Tap any day in the weekly strip to view and edit it.
3. Tap **Edit** to rename the day label (e.g. "Push", "Rest").
4. Tap **+** on a day to add exercises (name, sets × reps, weight).
5. Swipe an exercise left to delete; tap to edit inline.

### Logging
- Tap a day's checkbox in the strip to mark it done for the week.
- Tap the **Rest** toggle to mark a day as a rest day.

### Weight log
- Scroll down on the Gym screen to the **Weight** section.
- Tap **+** to log today's weight (kg).
- A line chart shows your weight trend.
- Swipe an entry left to delete.

---

## Snapshots

A personal photo journal organised by category (Hair / Body / Skin).

### Adding a snapshot
1. Open **Snapshots**, select a category tab.
2. Tap **+**, optionally pick or capture an image, add a note, and adjust the colour tint using the hue slider.
3. Tap **Save**.

### Viewing
- Tap a snapshot tile to view it full-screen.
- Long-press a tile, or tap the trash icon in the full-screen view, to delete (confirmation required).

---

## Expenses

Track your daily spending.

### Adding an expense
1. Tap **+** → **Expense**, or open Expenses and tap **+**.
2. Enter the amount, pick a category (Food / Transport / Shopping / Entertainment / Health / Bills / Education / Other), and add an optional note.
3. Tap **Save**.

### Viewing
- **Summary card** at the top shows today's total.
- **Category chips** — tap to filter by category.
- Swipe an entry left to delete.

---

## Notes

Keep free-form text notes.

1. Open **Notes** and tap **+**.
2. Enter a title and body.
3. Tap **Save**.

Tap a note to edit. Swipe left to delete.

---

## Saved Links

Bookmark URLs for later.

1. Open **Links** and tap **+**.
2. Enter a title and URL (scheme optional — `example.com` is treated as `https://example.com`).
3. Tap **Save**.

Tap a link to open it in your browser. Swipe left to delete.

---

## Vault

Store passwords and credentials privately.

1. Open **Vault** and tap **+**.
2. Enter a title, username, password, URL, and note (all except password are optional).
3. Tap **Save**.

Tap a vault entry to open the detail view, where you can:
- Toggle password visibility (eye icon).
- Copy username or password to the clipboard.
- Edit or delete the entry.

> **Note:** Vault passwords are encrypted on the device before being stored — they are never saved as plain text. Other fields (title, username, URL, note) are stored unencrypted in the app's sandboxed storage.

---

## Notifications

### Permissions (Android)
Three permissions affect notification reliability:

| Permission | Location | Effect |
|---|---|---|
| Notifications | Shown automatically on first reminder set | Required to display banners |
| Exact alarms | Settings → Special app access → Alarms & reminders | Required for on-the-dot delivery |
| Battery unrestricted | Settings → Apps → Only Me → Battery → Unrestricted | Required on some phones to fire after app is cleared |

Go to **More → Notifications** to see the status of each permission and tap the action button to fix any that are missing.

### Testing
Tap **Send test notification** in More → Notifications — a notification will arrive in ~10 seconds.

### Alarm mode
When a task or event is in **Alarm mode**:
- It plays at full alarm volume even when your phone is on silent.
- Android shows a clock icon in the status bar.
- It will fire even if the app has been cleared from recent apps.

Use alarm mode for important appointments or medication reminders.

### Custom alarm sound
In **More → Alarm Sound**, tap the row to pick any audio file from your device. The file is copied to the app's internal storage so it persists even if the original is moved. Tap **Clear** to revert to the system default.

---

## Backup & Restore

All your data lives on your device. Export it regularly so you don't lose it if you switch phones.

### Export
1. Go to **More → Backup → Export data**.
2. The app bundles all your data (tasks, debts, events, gym plan, snapshots, expenses, notes, links, vault entries, settings) into a single `.json` file.
3. The native share sheet opens — save it to Google Drive, email it to yourself, or use any other method.

Snapshot images and your custom alarm sound are embedded in the backup file as base64, so everything travels in one file.

### Import / Restore
1. Go to **More → Backup → Import data**.
2. Confirm the overwrite warning.
3. Pick the `.json` backup file.
4. All data is restored and active reminders are rescheduled automatically.

> **Warning:** Import replaces all current data. Export first if you want to keep what's on the device.

---

## Appearance

Open **More → Tweaks** (or tap the sliders icon) to change:

- **Accent colour** — Mint, Blue, Purple, Rose, Gold, Slate.
- **Dark / Light mode** toggle.

---

## Profile

Go to **More → Profile** (or tap your name at the top of More) to view your profile. Tap **Edit** to change your name, date of birth, phone number, and currency symbol.

---

## Privacy

Only Me stores all data locally on your device using Android's SharedPreferences and the internal documents directory. No data is sent to any server. No analytics, no tracking, no ads. The "Sync" button is a placeholder for a future optional feature and currently does nothing except record a timestamp.

See the full [Privacy Policy](privacy-policy.md) for details.

---

## Frequently Asked Questions

**Will my reminders fire if I clear the app from recents?**
Yes, if you have granted the "Exact alarms" permission. Alarm-mode reminders are especially reliable as they use Android's `AlarmClock` API which is exempt from battery optimisation. Normal reminders may be delayed on some phones with aggressive battery savers unless you also grant "Battery unrestricted".

**Why did my notification not fire?**
Check **More → Notifications**. All three permission rows should show "Granted". The most common culprit is the "Exact alarms" permission, which must be granted manually in Settings → Special app access → Alarms & reminders.

**Can I use the app without giving any permissions?**
Yes. All features except reminders and image capture work without any permissions.

**Is my vault data encrypted?**
Yes — passwords are encrypted on the device before being stored and are never written as plain text. Other vault fields (title, username, URL, note) are stored unencrypted within the app's sandboxed storage. A device screen lock is recommended to protect against physical access.

**How do I move to a new phone?**
Export your data from **More → Backup → Export data**, transfer the `.json` file to the new phone, install Only Me, then restore via **More → Backup → Import data**.

**What happens if I uninstall the app?**
All data is deleted. Export before uninstalling.
