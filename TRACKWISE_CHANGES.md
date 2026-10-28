# TrackWise redesign

- Updated the app's user-facing name on Flutter, Android, iOS and web.
- Indigo/teal/amber/purple palette, rounded cards and touch-friendly controls.
- Dashboard summary with current streak, longest streak, weekly completion indicators, habit count, activity count and today's completions.
- Per-habit streaks and one-tap daily completion via the habit action menu.
- Streaks use distinct local calendar dates of completed activity records; a current streak can end yesterday without resetting until the next day.
- Added streak unit tests.

## Compatibility
The existing Dart package identifier, Android application ID and SQLite database filename remain unchanged intentionally, so an update over an existing installation can preserve app data. Changing the Android application ID would create a separate app installation.

## Run
```
flutter pub get
flutter analyze
flutter test
flutter run -d emulator-5554
flutter build apk --release
```

## Important
The JSON backup filename remains `habit_mastery_backup.json` for compatibility with existing exports. Back up your data before replacing the installed app.

This project was edited in a container without the Flutter SDK, so the Android build and runtime still need verification on your Windows machine.
