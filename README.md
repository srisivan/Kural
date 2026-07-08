# Thirukkural Daily App — Scaffold

A working Flutter scaffold that serves one kural a day at 7:30 AM, tracks
progress through a user-chosen chapter, and lets the user share the kural
as a screenshot.

## What's here

```
lib/
  models/
    kural.dart              # Kural data model
    chapter.dart             # Chapter model + flattens nested chapters.json
  services/
    data_service.dart        # Loads/parses the two bundled JSON assets
    progress_service.dart    # Hive-backed progress tracking
    notification_service.dart# Schedules the daily 7:30 AM notification
  providers/
    kural_providers.dart     # Riverpod: loads data + "today's kural" logic
  screens/
    home_screen.dart         # Main white screen + share button
    chapter_picker_screen.dart # Searchable chapter list
  widgets/
    kural_card.dart           # The actual kural display (used for screenshot too)
  main.dart                   # Bootstraps Hive + notifications, launches app
assets/data/
  kurals.json     # SAMPLE — replace with your full 1330-kural file
  chapters.json   # SAMPLE — replace with your full 133-chapter file
```

## Setup

1. **Replace the sample JSON files** in `assets/data/` with your full
   `kurals.json` (all 1330 entries) and `chapters.json` (full nested
   structure) — same shape as the samples, just complete.

2. Install dependencies:
   ```
   flutter pub get
   ```

3. **Android setup for notifications:**
   - Minimum SDK 21+ in `android/app/build.gradle`.
   - No extra manifest changes needed for `flutter_local_notifications`
     v17+, but if you want the notification to survive device reboots,
     add a `RECEIVE_BOOT_COMPLETED` permission and re-schedule on boot
     (not included in this scaffold — flag if you want it added).

4. **iOS setup for notifications:**
   - Enable "Push Notifications" and "Background Modes" (optional) in
     Xcode capabilities if you later want richer background behavior.
   - The scaffold already requests alert/badge/sound permission on init.

5. Run:
   ```
   flutter run
   ```

## How the daily logic works

- `TodaysKuralNotifier` (in `kural_providers.dart`) checks Hive on every
  app open:
  - If already served today → re-shows the same kural (so reopening the
    app mid-day doesn't skip ahead).
  - Otherwise → advances to `lastKural + 1` within the selected chapter,
    looping back to the chapter's `start` if the chapter is finished.
  - The interpretation (`mv` / `sp` / `mk`) is chosen with a date-seeded
    random pick, so it's stable for the whole day but different from
    yesterday.

- The **7:30 AM notification** is just a nudge (`zonedSchedule` with
  `matchDateTimeComponents: DateTimeComponents.time` — repeats daily).
  The actual "advance to next kural" happens the moment the user opens
  the app that day, not inside a background task. This avoids needing
  Android's WorkManager / iOS background fetch entitlements, which are
  heavier to set up and less reliable across OEMs.

## Things to double check / decide

- **Chapter-end behavior**: currently loops back to the chapter's start
  once finished. If you'd rather prompt the user to pick a new chapter
  when one finishes, that's a small change in `TodaysKuralNotifier.build()`.
- **Timezone accuracy**: the notification uses the device's local
  timezone via the `timezone` package's `tz.local`. If you want to pin
  it to a specific zone (e.g. always IST regardless of device locale),
  set `tz.setLocalLocation(tz.getLocation('Asia/Kolkata'))` in
  `NotificationService.init()`.
- **Fonts**: uses `google_fonts` (Noto Sans Tamil) which downloads at
  runtime by default — for full offline reliability, bundle the font
  file locally instead (happy to wire that up if you want).
- **Chapter picker UX**: currently a flat searchable list. If you'd
  prefer the three-level drill-down (Section → Chapter Group →
  Chapter) instead, that's a moderate addition on top of the existing
  `Chapter` model, which already carries `sectionName` / `chapterGroupName`.

## Not yet built (nice-to-haves, say the word if wanted)

- Re-scheduling the notification after a device reboot (Android).
- Home screen widget showing today's kural without opening the app.
- History/archive screen of past shown kurals.
- Dark mode toggle (spec asked for plain white, so left out deliberately).
