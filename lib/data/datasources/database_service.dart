import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../models/feedback_entry.dart';

/// Dedicated database service layer. Every SQL operation in the app goes
/// through here — no widget or BLoC touches sqflite directly. This keeps the
/// persistence concern isolated and swappable (e.g. moving to drift later).
class DatabaseService {
  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, AppConstants.dbName);
    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.feedbackTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_name TEXT NOT NULL,
        owner_email TEXT NOT NULL,
        user_name TEXT NOT NULL,
        user_email TEXT NOT NULL,
        user_contact TEXT NOT NULL,
        issue_title TEXT NOT NULL,
        description TEXT NOT NULL,
        device_info TEXT NOT NULL,
        media_paths TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertFeedback(FeedbackEntry entry) async {
    final db = await database;
    final map = entry.toMap()..remove('id');
    return db.insert(AppConstants.feedbackTable, map);
  }

  Future<List<FeedbackEntry>> getAllFeedback() async {
    final db = await database;
    final rows = await db.query(
      AppConstants.feedbackTable,
      orderBy: 'created_at DESC',
    );
    return rows.map(FeedbackEntry.fromMap).toList();
  }

  Future<int> count() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${AppConstants.feedbackTable}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete(AppConstants.feedbackTable);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
