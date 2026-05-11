import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'voxbox_cache.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table pour les chants
    await db.execute('''
      CREATE TABLE chants (
        id INTEGER PRIMARY KEY,
        section_id INTEGER,
        data TEXT,
        updated_at TEXT
      )
    ''');

    // Table pour les messes
    await db.execute('''
      CREATE TABLE messes (
        id INTEGER PRIMARY KEY,
        data TEXT,
        updated_at TEXT
      )
    ''');

    // Table pour les sections de messe
    await db.execute('''
      CREATE TABLE messe_sections (
        id INTEGER PRIMARY KEY,
        data TEXT,
        updated_at TEXT
      )
    ''');

    // Table pour les sections de chants
    await db.execute('''
      CREATE TABLE chant_sections (
        id INTEGER PRIMARY KEY,
        data TEXT,
        updated_at TEXT
      )
    ''');

    // Table pour les fichiers locaux et en attente
    await db.execute('''
      CREATE TABLE local_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chant_id INTEGER,
        file_path TEXT,
        file_type TEXT,
        pupitre TEXT,
        file_size INTEGER,
        is_pending INTEGER DEFAULT 0,
        synced INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');
    
    // Index pour accélérer les recherches
    await db.execute('CREATE INDEX idx_chants_section ON chants(section_id)');
    await db.execute('CREATE INDEX idx_local_files_chant ON local_files(chant_id)');
  }

  // ===== Méthodes génériques de persistance =====

  Future<void> saveItems(String table, List<Map<String, dynamic>> items) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var item in items) {
        await txn.insert(
          table,
          item,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getItems(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<void> deleteItem(String table, int id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTable(String table) async {
    final db = await database;
    await db.delete(table);
  }
}
