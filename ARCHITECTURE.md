# Architecture — current implementation and limitations

Flutter Material UI uses Riverpod `ChangeNotifierProvider` for app-wide reactive state. `AppState` loads local data from `DatabaseHelper`, which owns the `sqflite` connection and enables foreign keys. SQLite stores `habits` and `activities`, related by `activities.habit_id REFERENCES habits(id) ON DELETE CASCADE`. SharedPreferences persists dark mode. Pure Dart helper logic lives in `lib/smart_helper.dart`. The JSON export/import implementation uses an atomic database transaction and validates foreign keys, record shapes and limits before replacing local records.

## Important limitations / graduate gaps

The existing application uses a database helper rather than a fully injected repository implementation; full dependency injection and clean architecture separation remain to be verified/improved. Background processing, local notifications, integration tests, and actual coverage evidence are not included. No claim is made that all graduate requirements are fulfilled.
