import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final instance = DatabaseHelper._();
  Database? _db;
  Future<Database> get database async => _db ??= await openDatabase(
    join(await getDatabasesPath(), 'habit_mastery_v2.db'),
    version: 1,
    onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
    onCreate: (db, version) async {
      await db.execute('CREATE TABLE habits(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, category TEXT NOT NULL, target INTEGER NOT NULL CHECK(target BETWEEN 1 AND 100), created_at TEXT NOT NULL)');
      await db.execute('CREATE TABLE activities(id INTEGER PRIMARY KEY AUTOINCREMENT, habit_id INTEGER NOT NULL REFERENCES habits(id) ON DELETE CASCADE, note TEXT NOT NULL, progress INTEGER NOT NULL CHECK(progress BETWEEN 0 AND 100), completed INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL)');
    },
  );
  Future<List<Map<String, Object?>>> habits() async => (await database).query('habits', orderBy: 'created_at DESC');
  Future<List<Map<String, Object?>>> activities([int? habitId]) async => (await database).query('activities', where: habitId == null ? null : 'habit_id = ?', whereArgs: habitId == null ? null : [habitId], orderBy: 'created_at DESC');
  Future<int> saveHabit({int? id, required String title, required String category, required int target}) async {
    if (title.trim().isEmpty || target < 1 || target > 100) throw ArgumentError('Enter a title and target from 1 to 100');
    final db = await database;
    final data = {'title': title.trim(), 'category': category, 'target': target, 'created_at': DateTime.now().toIso8601String()};
    if (id == null) return db.insert('habits', data);
    await db.update('habits', data..remove('created_at'), where: 'id = ?', whereArgs: [id]);
    return id;
  }
  Future<void> deleteHabit(int id) async { await (await database).delete('habits', where: 'id = ?', whereArgs: [id]); }
  Future<int> saveActivity({int? id, required int habitId, required String note, required int progress, required bool completed}) async {
    if (progress < 0 || progress > 100) throw ArgumentError('Progress must be between 0 and 100');
    final db = await database;
    final data = {'habit_id': habitId, 'note': note.trim(), 'progress': progress, 'completed': completed ? 1 : 0, 'created_at': DateTime.now().toIso8601String()};
    if (id == null) return db.insert('activities', data);
    await db.update('activities', data..remove('created_at'), where: 'id = ?', whereArgs: [id]);
    return id;
  }
  Future<void> deleteActivity(int id) async { await (await database).delete('activities', where: 'id = ?', whereArgs: [id]); }
  /// Export a consistent local snapshot; imports use a transaction.
  Future<Map<String, Object?>> exportSnapshot() async => {
    'schemaVersion': 1,
    'exportedAt': DateTime.now().toUtc().toIso8601String(),
    'habits': await habits(),
    'activities': await activities(),
  };

  Future<void> importSnapshot(Map<String, dynamic> snapshot) async {
    if (snapshot['schemaVersion'] != 1 || snapshot['habits'] is! List || snapshot['activities'] is! List) {
      throw const FormatException('Unsupported backup format');
    }
    final rawHabits = snapshot['habits'] as List;
    final rawActivities = snapshot['activities'] as List;
    if (rawHabits.length > 10000 || rawActivities.length > 100000) {
      throw const FormatException('Backup exceeds supported size');
    }
    final parsedHabits = <Map<String, Object?>>[];
    final parsedActivities = <Map<String, Object?>>[];
    final ids = <int>{};
    for (final raw in rawHabits) {
      if (raw is! Map) throw const FormatException('Invalid habit');
      final id=raw['id'], title=raw['title'], category=raw['category'], target=raw['target'], created=raw['created_at'];
      if (id is! int || id <= 0 || !ids.add(id) || title is! String || title.trim().isEmpty || title.length > 60 || category is! String || category.length > 50 || target is! int || target < 1 || target > 100 || created is! String || DateTime.tryParse(created)==null) throw const FormatException('Invalid habit record');
      parsedHabits.add({'id':id,'title':title.trim(),'category':category,'target':target,'created_at':created});
    }
    final activityIds=<int>{};
    for (final raw in rawActivities) {
      if (raw is! Map) throw const FormatException('Invalid activity');
      final id=raw['id'], parent=raw['habit_id'], note=raw['note'], progress=raw['progress'], completed=raw['completed'], created=raw['created_at'];
      if (id is! int || id <= 0 || !activityIds.add(id) || parent is! int || !ids.contains(parent) || note is! String || note.length > 1000 || progress is! int || progress < 0 || progress > 100 || (completed != 0 && completed != 1) || created is! String || DateTime.tryParse(created)==null) throw const FormatException('Invalid activity record');
      parsedActivities.add({'id':id,'habit_id':parent,'note':note,'progress':progress,'completed':completed,'created_at':created});
    }
    final db=await database;
    await db.transaction((txn) async {
      await txn.delete('activities');
      await txn.delete('habits');
      for (final h in parsedHabits) { await txn.insert('habits',h); }
      for (final a in parsedActivities) { await txn.insert('activities',a); }
    });
  }
  Future<void> close() async { final db = _db; _db = null; await db?.close(); }
}
