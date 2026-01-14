import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite database for offline caching
class LocalDatabase {
  static Database? _database;
  static const String _dbName = 'crop_diagnosis.db';
  static const int _dbVersion = 1;
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }
  
  static Future<void> _onCreate(Database db, int version) async {
    // Cached diagnoses
    await db.execute('''
      CREATE TABLE diagnoses (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        disease TEXT NOT NULL,
        severity TEXT NOT NULL,
        confidence REAL NOT NULL,
        crop_type TEXT,
        treatment TEXT,
        warnings TEXT,
        prevention TEXT,
        media_path TEXT,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 1
      )
    ''');
    
    // Cached questions
    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        question_text TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 1
      )
    ''');
    
    // Pending uploads (for offline mode)
    await db.execute('''
      CREATE TABLE pending_uploads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        file_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }
  
  // Diagnosis caching methods
  
  static Future<void> cacheDiagnosis(Map<String, dynamic> diagnosis) async {
    final db = await database;
    await db.insert(
      'diagnoses',
      {
        'id': diagnosis['id'],
        'user_id': diagnosis['user_id'] ?? '',
        'disease': diagnosis['disease'],
        'severity': diagnosis['severity'],
        'confidence': diagnosis['confidence'],
        'crop_type': diagnosis['crop_type'],
        'treatment': diagnosis['treatment']?.toString(),
        'warnings': diagnosis['warnings'],
        'prevention': diagnosis['prevention'],
        'media_path': diagnosis['media_path'],
        'created_at': diagnosis['created_at'],
        'synced': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  static Future<List<Map<String, dynamic>>> getCachedDiagnoses() async {
    final db = await database;
    return db.query('diagnoses', orderBy: 'created_at DESC');
  }
  
  static Future<Map<String, dynamic>?> getDiagnosisById(String id) async {
    final db = await database;
    final results = await db.query(
      'diagnoses',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }
  
  // Pending upload methods (for offline sync)
  
  static Future<void> addPendingUpload({
    required String type,
    required String data,
    String? filePath,
  }) async {
    final db = await database;
    await db.insert('pending_uploads', {
      'type': type,
      'data': data,
      'file_path': filePath,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  static Future<List<Map<String, dynamic>>> getPendingUploads() async {
    final db = await database;
    return db.query('pending_uploads', orderBy: 'created_at ASC');
  }
  
  static Future<void> deletePendingUpload(int id) async {
    final db = await database;
    await db.delete('pending_uploads', where: 'id = ?', whereArgs: [id]);
  }
  
  // Clear all cached data
  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('diagnoses');
    await db.delete('questions');
    await db.delete('pending_uploads');
  }
}
