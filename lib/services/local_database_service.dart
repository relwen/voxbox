import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voxbox/models/chant_de_messe.dart';

class LocalDatabaseService {
  static Database? _database;
  static const String _databaseName = 'voxbox_local.db';
  static const int _databaseVersion = 1;

  // Tables
  static const String _chantsTable = 'chants';
  static const String _messesTable = 'messes';
  static const String _sectionsTable = 'sections';
  static const String _filesTable = 'files';
  static const String _pendingFilesTable = 'pending_files';

  /// Initialiser la base de données
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Table des chants
    await db.execute('''
      CREATE TABLE $_chantsTable (
        id INTEGER PRIMARY KEY,
        section_id INTEGER,
        titre TEXT NOT NULL,
        description TEXT,
        audio_path TEXT,
        pdf_path TEXT,
        image_path TEXT,
        audio_files TEXT,
        pdf_files TEXT,
        image_files TEXT,
        soprano_files TEXT,
        alto_files TEXT,
        tenor_files TEXT,
        basse_files TEXT,
        tutti_files TEXT,
        ordre INTEGER,
        active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        last_sync TEXT,
        is_local INTEGER DEFAULT 0
      )
    ''');

    // Table des messes
    await db.execute('''
      CREATE TABLE $_messesTable (
        id INTEGER PRIMARY KEY,
        nom TEXT NOT NULL,
        description TEXT,
        date TEXT,
        active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        last_sync TEXT
      )
    ''');

    // Table des sections
    await db.execute('''
      CREATE TABLE $_sectionsTable (
        id INTEGER PRIMARY KEY,
        messe_id INTEGER,
        nom TEXT NOT NULL,
        description TEXT,
        ordre INTEGER,
        active INTEGER DEFAULT 1,
        created_at TEXT,
        updated_at TEXT,
        last_sync TEXT,
        FOREIGN KEY (messe_id) REFERENCES $_messesTable (id)
      )
    ''');

    // Table des fichiers locaux
    await db.execute('''
      CREATE TABLE $_filesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chant_id INTEGER,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        pupitre TEXT,
        file_size INTEGER,
        created_at TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (chant_id) REFERENCES $_chantsTable (id)
      )
    ''');

    // Table des fichiers en attente
    await db.execute('''
      CREATE TABLE $_pendingFilesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chant_id INTEGER,
        file_path TEXT NOT NULL,
        file_type TEXT NOT NULL,
        pupitre TEXT,
        timestamp TEXT,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (chant_id) REFERENCES $_chantsTable (id)
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('CREATE INDEX idx_chants_section ON $_chantsTable (section_id)');
    await db.execute('CREATE INDEX idx_sections_messe ON $_sectionsTable (messe_id)');
    await db.execute('CREATE INDEX idx_files_chant ON $_filesTable (chant_id)');
    await db.execute('CREATE INDEX idx_pending_files_chant ON $_pendingFilesTable (chant_id)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Gérer les migrations futures
  }

  // ===== GESTION DES CHANTS =====

  /// Insérer ou mettre à jour un chant
  static Future<void> upsertChant(ChantDeMesse chant, {bool isLocal = false}) async {
    final db = await database;
    
    final chantData = {
      'id': chant.id,
      'section_id': chant.sectionId,
      'titre': chant.titre,
      'description': chant.description,
      'audio_path': chant.audioPath,
      'pdf_path': chant.pdfPath,
      'image_path': chant.imagePath,
      'audio_files': chant.audioFiles != null ? chant.audioFiles!.join('|') : null,
      'pdf_files': chant.pdfFiles != null ? chant.pdfFiles!.join('|') : null,
      'image_files': chant.imageFiles != null ? chant.imageFiles!.join('|') : null,
      'soprano_files': chant.sopranoFiles != null ? chant.sopranoFiles!.join('|') : null,
      'alto_files': chant.altoFiles != null ? chant.altoFiles!.join('|') : null,
      'tenor_files': chant.tenorFiles != null ? chant.tenorFiles!.join('|') : null,
      'basse_files': chant.basseFiles != null ? chant.basseFiles!.join('|') : null,
      'tutti_files': chant.tuttiFiles != null ? chant.tuttiFiles!.join('|') : null,
      'ordre': chant.ordre,
      'active': chant.active ? 1 : 0,
      'created_at': chant.createdAt.toIso8601String(),
      'updated_at': chant.updatedAt.toIso8601String(),
      'last_sync': DateTime.now().toIso8601String(),
      'is_local': isLocal ? 1 : 0,
    };

    await db.insert(
      _chantsTable,
      chantData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupérer un chant avec ses fichiers locaux
  static Future<ChantDeMesse?> getChant(int chantId) async {
    final db = await database;
    
    final result = await db.query(
      _chantsTable,
      where: 'id = ?',
      whereArgs: [chantId],
    );

    if (result.isEmpty) return null;

    final chantData = result.first;
    final chant = _mapRowToChant(chantData);

    // Ajouter les fichiers locaux
    final localFiles = await getLocalFiles(chantId);
    final pendingFiles = await getPendingFiles(chantId);

    // Fusionner les fichiers
    final mergedChant = _mergeLocalFiles(chant, localFiles, pendingFiles);

    return mergedChant;
  }

  /// Récupérer tous les chants d'une section
  static Future<List<ChantDeMesse>> getChantsBySection(int sectionId) async {
    final db = await database;
    
    final results = await db.query(
      _chantsTable,
      where: 'section_id = ?',
      whereArgs: [sectionId],
      orderBy: 'ordre ASC',
    );

    final chants = results.map((row) => _mapRowToChant(row)).toList();

    // Ajouter les fichiers locaux pour chaque chant
    for (int i = 0; i < chants.length; i++) {
      final localFiles = await getLocalFiles(chants[i].id);
      final pendingFiles = await getPendingFiles(chants[i].id);
      final mergedChant = _mergeLocalFiles(chants[i], localFiles, pendingFiles);
      chants[i] = mergedChant;
    }

    return chants;
  }

  // ===== GESTION DES FICHIERS =====

  /// Ajouter un fichier local
  static Future<void> addLocalFile({
    required int chantId,
    required String filePath,
    required String fileType,
    String? pupitre,
    int? fileSize,
  }) async {
    final db = await database;
    
    await db.insert(_filesTable, {
      'chant_id': chantId,
      'file_path': filePath,
      'file_type': fileType,
      'pupitre': pupitre,
      'file_size': fileSize,
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  /// Ajouter un fichier en attente
  static Future<void> addPendingFile({
    required int chantId,
    required String filePath,
    required String fileType,
    String? pupitre,
  }) async {
    final db = await database;
    
    await db.insert(_pendingFilesTable, {
      'chant_id': chantId,
      'file_path': filePath,
      'file_type': fileType,
      'pupitre': pupitre,
      'timestamp': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  /// Récupérer les fichiers locaux d'un chant
  static Future<List<Map<String, dynamic>>> getLocalFiles(int chantId) async {
    final db = await database;
    
    return await db.query(
      _filesTable,
      where: 'chant_id = ?',
      whereArgs: [chantId],
    );
  }

  /// Récupérer les fichiers en attente d'un chant
  static Future<List<Map<String, dynamic>>> getPendingFiles(int chantId) async {
    final db = await database;
    
    return await db.query(
      _pendingFilesTable,
      where: 'chant_id = ? AND synced = 0',
      whereArgs: [chantId],
    );
  }

  /// Marquer les fichiers comme synchronisés
  static Future<void> markFilesAsSynced(int chantId, List<String> filePaths) async {
    final db = await database;
    
    for (String filePath in filePaths) {
      await db.update(
        _pendingFilesTable,
        {'synced': 1},
        where: 'chant_id = ? AND file_path = ?',
        whereArgs: [chantId, filePath],
      );
    }
  }

  /// Supprimer les fichiers synchronisés
  static Future<void> removeSyncedFiles(int chantId) async {
    final db = await database;
    
    await db.delete(
      _pendingFilesTable,
      where: 'chant_id = ? AND synced = 1',
      whereArgs: [chantId],
    );
  }

  /// Vérifier s'il y a des fichiers en attente
  static Future<bool> hasPendingFiles(int chantId) async {
    final db = await database;
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_pendingFilesTable WHERE chant_id = ? AND synced = 0',
      [chantId],
    );
    
    return result.first['count'] as int > 0;
  }

  // ===== UTILITAIRES =====

  static ChantDeMesse _mapRowToChant(Map<String, dynamic> row) {
    return ChantDeMesse(
      id: row['id'],
      sectionId: row['section_id'],
      titre: row['titre'],
      description: row['description'],
      audioPath: row['audio_path'],
      pdfPath: row['pdf_path'],
      imagePath: row['image_path'],
      audioFiles: row['audio_files']?.toString().split('|'),
      pdfFiles: row['pdf_files']?.toString().split('|'),
      imageFiles: row['image_files']?.toString().split('|'),
      sopranoFiles: row['soprano_files']?.toString().split('|'),
      altoFiles: row['alto_files']?.toString().split('|'),
      tenorFiles: row['tenor_files']?.toString().split('|'),
      basseFiles: row['basse_files']?.toString().split('|'),
      tuttiFiles: row['tutti_files']?.toString().split('|'),
      ordre: row['ordre'],
      active: row['active'] == 1,
      createdAt: row['created_at'] != null ? DateTime.parse(row['created_at']) : DateTime.now(),
      updatedAt: row['updated_at'] != null ? DateTime.parse(row['updated_at']) : DateTime.now(),
    );
  }

  static ChantDeMesse _mergeLocalFiles(
    ChantDeMesse chant,
    List<Map<String, dynamic>> localFiles,
    List<Map<String, dynamic>> pendingFiles,
  ) {
    // Créer des listes pour chaque type de fichier
    List<String> audioFiles = List<String>.from(chant.audioFiles ?? []);
    List<String> pdfFiles = List<String>.from(chant.pdfFiles ?? []);
    List<String> imageFiles = List<String>.from(chant.imageFiles ?? []);
    List<String> sopranoFiles = List<String>.from(chant.sopranoFiles ?? []);
    List<String> altoFiles = List<String>.from(chant.altoFiles ?? []);
    List<String> tenorFiles = List<String>.from(chant.tenorFiles ?? []);
    List<String> basseFiles = List<String>.from(chant.basseFiles ?? []);
    List<String> tuttiFiles = List<String>.from(chant.tuttiFiles ?? []);

    // Ajouter les fichiers locaux
    for (var file in localFiles) {
      _addFileToList(file, audioFiles, pdfFiles, imageFiles, sopranoFiles, altoFiles, tenorFiles, basseFiles, tuttiFiles);
    }

    // Ajouter les fichiers en attente
    for (var file in pendingFiles) {
      _addFileToList(file, audioFiles, pdfFiles, imageFiles, sopranoFiles, altoFiles, tenorFiles, basseFiles, tuttiFiles);
    }

    // Créer un nouveau chant avec les fichiers fusionnés
    return ChantDeMesse(
      id: chant.id,
      sectionId: chant.sectionId,
      titre: chant.titre,
      description: chant.description,
      audioPath: chant.audioPath,
      pdfPath: chant.pdfPath,
      imagePath: chant.imagePath,
      audioFiles: audioFiles.isNotEmpty ? audioFiles : null,
      pdfFiles: pdfFiles.isNotEmpty ? pdfFiles : null,
      imageFiles: imageFiles.isNotEmpty ? imageFiles : null,
      sopranoFiles: sopranoFiles.isNotEmpty ? sopranoFiles : null,
      altoFiles: altoFiles.isNotEmpty ? altoFiles : null,
      tenorFiles: tenorFiles.isNotEmpty ? tenorFiles : null,
      basseFiles: basseFiles.isNotEmpty ? basseFiles : null,
      tuttiFiles: tuttiFiles.isNotEmpty ? tuttiFiles : null,
      ordre: chant.ordre,
      active: chant.active,
      createdAt: chant.createdAt,
      updatedAt: chant.updatedAt,
    );
  }

  static void _addFileToList(
    Map<String, dynamic> file,
    List<String> audioFiles,
    List<String> pdfFiles,
    List<String> imageFiles,
    List<String> sopranoFiles,
    List<String> altoFiles,
    List<String> tenorFiles,
    List<String> basseFiles,
    List<String> tuttiFiles,
  ) {
    String filePath = file['file_path'];
    String fileType = file['file_type'];
    String? pupitre = file['pupitre'];

    if (pupitre != null) {
      // Fichiers par pupitre
      switch (pupitre.toLowerCase()) {
        case 'soprano':
          sopranoFiles.add(filePath);
          break;
        case 'alto':
          altoFiles.add(filePath);
          break;
        case 'tenor':
          tenorFiles.add(filePath);
          break;
        case 'basse':
          basseFiles.add(filePath);
          break;
        case 'tutti':
          tuttiFiles.add(filePath);
          break;
      }
    } else {
      // Fichiers généraux
      switch (fileType) {
        case 'audio':
          audioFiles.add(filePath);
          break;
        case 'pdf':
          pdfFiles.add(filePath);
          break;
        case 'image':
          imageFiles.add(filePath);
          break;
      }
    }
  }

  /// Nettoyer la base de données
  static Future<void> clearDatabase() async {
    final db = await database;
    await db.delete(_chantsTable);
    await db.delete(_messesTable);
    await db.delete(_sectionsTable);
    await db.delete(_filesTable);
    await db.delete(_pendingFilesTable);
  }

  /// Fermer la base de données
  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
