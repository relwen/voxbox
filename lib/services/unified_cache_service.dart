import 'dart:convert';
import 'package:voxbox/models/chant_de_messe.dart';
import 'package:voxbox/models/messe.dart';
import 'package:voxbox/models/messe_section.dart';
import 'package:voxbox/models/chant_section.dart';
import 'package:voxbox/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnifiedCacheService {
  static final DatabaseService _db = DatabaseService();
  static const String _lastSyncKey = 'unified_last_sync';

  // ===== GESTION DES CHANTS =====
  
  static Future<void> saveOrUpdateChants(List<ChantDeMesse> newChants) async {
    final List<Map<String, dynamic>> items = [];
    for (var chant in newChants) {
      items.add({
        'id': chant.id,
        'section_id': chant.sectionId,
        'data': json.encode(chant.toJson()),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    await _db.saveItems('chants', items);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  static Future<void> saveChants(List<ChantDeMesse> chants) async {
    await _db.clearTable('chants');
    await saveOrUpdateChants(chants);
  }

  static Future<List<ChantDeMesse>> getChants() async {
    final List<Map<String, dynamic>> rows = await _db.getItems('chants');
    final List<ChantDeMesse> chants = [];
    
    for (var row in rows) {
      final chant = ChantDeMesse.fromJson(json.decode(row['data']));
      chants.add(await _mergeLocalFiles(chant));
    }
    return chants;
  }

  static Future<ChantDeMesse?> getChant(int chantId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> rows = await db.query(
      'chants',
      where: 'id = ?',
      whereArgs: [chantId],
    );
    
    if (rows.isEmpty) return null;
    
    final chant = ChantDeMesse.fromJson(json.decode(rows.first['data']));
    return await _mergeLocalFiles(chant);
  }

  static Future<List<ChantDeMesse>> getChantsBySection(int sectionId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> rows = await db.query(
      'chants',
      where: 'section_id = ?',
      whereArgs: [sectionId],
    );
    
    final List<ChantDeMesse> chants = [];
    for (var row in rows) {
      final chant = ChantDeMesse.fromJson(json.decode(row['data']));
      chants.add(await _mergeLocalFiles(chant));
    }
    return chants;
  }

  static Future<void> updateChant(ChantDeMesse updatedChant) async {
    await saveOrUpdateChants([updatedChant]);
  }

  // ===== GESTION DES FICHIERS LOCAUX =====

  static Future<void> addLocalFile({
    required int chantId,
    required String filePath,
    required String fileType,
    String? pupitre,
    int? fileSize,
  }) async {
    final db = await _db.database;
    await db.insert('local_files', {
      'chant_id': chantId,
      'file_path': filePath,
      'file_type': fileType,
      'pupitre': pupitre,
      'file_size': fileSize,
      'is_pending': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Mettre à jour le chant dans la liste pour forcer le merge
    final chant = await getChant(chantId);
    if (chant != null) {
      await updateChant(chant);
    }
  }

  static Future<void> addPendingFile({
    required int chantId,
    required String filePath,
    required String fileType,
    String? pupitre,
  }) async {
    final db = await _db.database;
    await db.insert('local_files', {
      'chant_id': chantId,
      'file_path': filePath,
      'file_type': fileType,
      'pupitre': pupitre,
      'is_pending': 1,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    final chant = await getChant(chantId);
    if (chant != null) {
      await updateChant(chant);
    }
  }

  static Future<List<Map<String, dynamic>>> getLocalFiles(int chantId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> rows = await db.query(
      'local_files',
      where: 'chant_id = ? AND is_pending = 0',
      whereArgs: [chantId],
    );
    
    return rows.map((row) => {
      'filePath': row['file_path'],
      'fileType': row['file_type'],
      'pupitre': row['pupitre'],
      'fileSize': row['file_size'],
      'createdAt': row['created_at'],
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getPendingFiles(int chantId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> rows = await db.query(
      'local_files',
      where: 'chant_id = ? AND is_pending = 1',
      whereArgs: [chantId],
    );
    
    return rows.map((row) => {
      'filePath': row['file_path'],
      'fileType': row['file_type'],
      'pupitre': row['pupitre'],
      'synced': row['synced'] == 1,
      'timestamp': row['created_at'],
    }).toList();
  }

  static Future<void> markFilesAsSynced(int chantId, List<String> filePaths) async {
    final db = await _db.database;
    for (var path in filePaths) {
      await db.update(
        'local_files',
        {'synced': 1},
        where: 'chant_id = ? AND file_path = ?',
        whereArgs: [chantId, path],
      );
    }
  }

  static Future<void> removeSyncedFiles(int chantId) async {
    final db = await _db.database;
    await db.delete(
      'local_files',
      where: 'chant_id = ? AND synced = 1',
      whereArgs: [chantId],
    );
  }

  static Future<bool> hasPendingFiles(int chantId) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> rows = await db.query(
      'local_files',
      where: 'chant_id = ? AND is_pending = 1 AND synced = 0',
      whereArgs: [chantId],
    );
    return rows.isNotEmpty;
  }

  // ===== FUSION DES FICHIERS =====

  static Future<ChantDeMesse> _mergeLocalFiles(ChantDeMesse chant) async {
    final localFiles = await getLocalFiles(chant.id);
    final pendingFiles = await getPendingFiles(chant.id);

    List<String> audioFiles = List<String>.from(chant.audioFiles ?? []);
    List<String> pdfFiles = List<String>.from(chant.pdfFiles ?? []);
    List<String> imageFiles = List<String>.from(chant.imageFiles ?? []);
    List<String> sopranoFiles = List<String>.from(chant.sopranoFiles ?? []);
    List<String> altoFiles = List<String>.from(chant.altoFiles ?? []);
    List<String> tenorFiles = List<String>.from(chant.tenorFiles ?? []);
    List<String> basseFiles = List<String>.from(chant.basseFiles ?? []);
    List<String> tuttiFiles = List<String>.from(chant.tuttiFiles ?? []);

    for (var file in localFiles) {
      _addFileToList(file, audioFiles, pdfFiles, imageFiles, sopranoFiles, altoFiles, tenorFiles, basseFiles, tuttiFiles);
    }
    for (var file in pendingFiles) {
      _addFileToList(file, audioFiles, pdfFiles, imageFiles, sopranoFiles, altoFiles, tenorFiles, basseFiles, tuttiFiles);
    }

    return chant.copyWith(
      audioFiles: audioFiles.isNotEmpty ? audioFiles : null,
      pdfFiles: pdfFiles.isNotEmpty ? pdfFiles : null,
      imageFiles: imageFiles.isNotEmpty ? imageFiles : null,
      sopranoFiles: sopranoFiles.isNotEmpty ? sopranoFiles : null,
      altoFiles: altoFiles.isNotEmpty ? altoFiles : null,
      tenorFiles: tenorFiles.isNotEmpty ? tenorFiles : null,
      basseFiles: basseFiles.isNotEmpty ? basseFiles : null,
      tuttiFiles: tuttiFiles.isNotEmpty ? tuttiFiles : null,
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
    String filePath = file['filePath'];
    String fileType = file['fileType'];
    String? pupitre = file['pupitre'];

    if (pupitre != null) {
      switch (pupitre.toLowerCase()) {
        case 'soprano': sopranoFiles.add(filePath); break;
        case 'alto': altoFiles.add(filePath); break;
        case 'tenor': tenorFiles.add(filePath); break;
        case 'basse': basseFiles.add(filePath); break;
        case 'tutti': tuttiFiles.add(filePath); break;
      }
    } else {
      switch (fileType) {
        case 'audio': audioFiles.add(filePath); break;
        case 'pdf': pdfFiles.add(filePath); break;
        case 'image': imageFiles.add(filePath); break;
      }
    }
  }

  // ===== GESTION DES MESSES ET SECTIONS =====

  static Future<void> saveOrUpdateMesses(List<Messe> newMesses) async {
    final List<Map<String, dynamic>> items = [];
    for (var messe in newMesses) {
      items.add({
        'id': messe.id,
        'data': json.encode(messe.toJson()),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
    await _db.saveItems('messes', items);
  }

  static Future<void> saveMesses(List<Messe> messes) async {
    await _db.clearTable('messes');
    await saveOrUpdateMesses(messes);
  }

  static Future<List<Messe>> getMesses() async {
    final List<Map<String, dynamic>> rows = await _db.getItems('messes');
    return rows.map((row) => Messe.fromJson(json.decode(row['data']))).toList();
  }

  static Future<void> saveOrUpdateSections(List<MesseSection> newSections) async {
    final List<Map<String, dynamic>> items = [];
    List<ChantDeMesse> allChants = [];
    
    for (var section in newSections) {
      items.add({
        'id': section.id,
        'data': json.encode(section.toJson()),
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (section.chants != null) {
        allChants.addAll(section.chants!.map((c) => c.copyWith(sectionId: section.id)));
      }
    }
    await _db.saveItems('messe_sections', items);
    if (allChants.isNotEmpty) await saveOrUpdateChants(allChants);
  }

  static Future<void> saveSections(List<MesseSection> sections) async {
    await _db.clearTable('messe_sections');
    await saveOrUpdateSections(sections);
  }

  static Future<List<MesseSection>> getSections() async {
    final List<Map<String, dynamic>> rows = await _db.getItems('messe_sections');
    return rows.map((row) => MesseSection.fromJson(json.decode(row['data']))).toList();
  }

  static Future<void> saveOrUpdateChantSections(List<ChantSection> newSections) async {
    final List<Map<String, dynamic>> items = [];
    List<ChantDeMesse> allChants = [];
    
    for (var section in newSections) {
      items.add({
        'id': section.id,
        'data': json.encode(section.toJson()),
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (section.chants != null) {
        allChants.addAll(section.chants!.map((c) => c.copyWith(sectionId: section.id)));
      }
    }
    await _db.saveItems('chant_sections', items);
    if (allChants.isNotEmpty) await saveOrUpdateChants(allChants);
  }

  static Future<void> saveChantSections(List<ChantSection> sections) async {
    await _db.clearTable('chant_sections');
    await saveOrUpdateChantSections(sections);
  }

  static Future<List<ChantSection>> getChantSections() async {
    final List<Map<String, dynamic>> rows = await _db.getItems('chant_sections');
    return rows.map((row) => ChantSection.fromJson(json.decode(row['data']))).toList();
  }

  static Future<void> clearCache() async {
    await _db.clearTable('chants');
    await _db.clearTable('messes');
    await _db.clearTable('messe_sections');
    await _db.clearTable('chant_sections');
    await _db.clearTable('local_files');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSyncKey);
  }

  static Future<DateTime?> getLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);
    return lastSyncString != null ? DateTime.parse(lastSyncString) : null;
  }

  static Future<int> getCacheSize() async {
    // SQLite size is more complex, returning a dummy for now or calculating row count
    final db = await _db.database;
    final res = await db.rawQuery('SELECT SUM(LENGTH(data)) as size FROM chants');
    return (res.first['size'] as int?) ?? 0;
  }
}
