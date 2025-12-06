import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxbox/models/chant_de_messe.dart';
import 'package:voxbox/models/messe.dart';
import 'package:voxbox/models/messe_section.dart';

class UnifiedCacheService {
  // Clés de stockage
  static const String _chantsKey = 'unified_chants';
  static const String _messesKey = 'unified_messes';
  static const String _sectionsKey = 'unified_sections';
  static const String _localFilesKey = 'unified_local_files';
  static const String _pendingFilesKey = 'unified_pending_files';
  static const String _lastSyncKey = 'unified_last_sync';

  // ===== GESTION DES CHANTS =====

  /// Sauvegarder tous les chants avec leurs fichiers locaux
  static Future<void> saveChants(List<ChantDeMesse> chants) async {
    final prefs = await SharedPreferences.getInstance();
    final chantsJson = json.encode(chants.map((chant) => chant.toJson()).toList());
    await prefs.setString(_chantsKey, chantsJson);
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Récupérer tous les chants avec leurs fichiers locaux
  static Future<List<ChantDeMesse>> getChants() async {
    final prefs = await SharedPreferences.getInstance();
    final chantsJson = prefs.getString(_chantsKey);
    
    if (chantsJson == null) return [];

    try {
      final List<dynamic> chantsList = json.decode(chantsJson);
      final chants = chantsList.map((json) => ChantDeMesse.fromJson(json)).toList();
      
      // Fusionner avec les fichiers locaux
      for (int i = 0; i < chants.length; i++) {
        chants[i] = await _mergeLocalFiles(chants[i]);
      }
      
      return chants;
    } catch (e) {
      print('Erreur lors de la récupération des chants: $e');
      return [];
    }
  }

  /// Récupérer un chant spécifique avec ses fichiers locaux
  static Future<ChantDeMesse?> getChant(int chantId) async {
    final chants = await getChants();
    try {
      return chants.firstWhere((chant) => chant.id == chantId);
    } catch (e) {
      return null;
    }
  }

  /// Récupérer les chants d'une section
  /// sectionId: ID de la section (référence générée) - utilisé pour filtrer les chants
  static Future<List<ChantDeMesse>> getChantsBySection(int sectionId) async {
    final chants = await getChants();
    final filteredChants = chants.where((chant) => chant.sectionId == sectionId).toList();
    print('🔍 Filtrage chants pour section $sectionId: ${chants.length} total -> ${filteredChants.length} pour cette section');
    if (filteredChants.length != chants.length) {
      // Afficher les sectionId des chants qui ne correspondent pas pour debug
      final otherSections = chants.where((chant) => chant.sectionId != sectionId).map((c) => c.sectionId).toSet();
      if (otherSections.isNotEmpty) {
        print('⚠️ Chants trouvés avec d\'autres sectionId: ${otherSections.join(", ")}');
      }
    }
    return filteredChants;
  }

  /// Mettre à jour un chant spécifique
  static Future<void> updateChant(ChantDeMesse updatedChant) async {
    final chants = await getChants();
    final index = chants.indexWhere((chant) => chant.id == updatedChant.id);
    
    if (index != -1) {
      chants[index] = await _mergeLocalFiles(updatedChant);
      await saveChants(chants);
    } else {
      // Si le chant n'existe pas, l'ajouter
      final mergedChant = await _mergeLocalFiles(updatedChant);
      chants.add(mergedChant);
      await saveChants(chants);
    }
  }

  // ===== GESTION DES FICHIERS LOCAUX =====

  /// Ajouter un fichier local à un chant
  static Future<void> addLocalFile({
    required int chantId,
    required String filePath,
    required String fileType,
    String? pupitre,
    int? fileSize,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final localFilesJson = prefs.getString(_localFilesKey) ?? '{}';
    final Map<String, dynamic> localFiles = json.decode(localFilesJson);

    final fileKey = '$chantId';
    if (!localFiles.containsKey(fileKey)) {
      localFiles[fileKey] = [];
    }

    localFiles[fileKey].add({
      'filePath': filePath,
      'fileType': fileType,
      'pupitre': pupitre,
      'fileSize': fileSize,
      'createdAt': DateTime.now().toIso8601String(),
      'synced': false,
    });

    await prefs.setString(_localFilesKey, json.encode(localFiles));
    
    // Mettre à jour le chant dans la liste
    final chant = await getChant(chantId);
    if (chant != null) {
      await updateChant(chant);
    } else {
      // Si le chant n'existe pas encore, créer un chant de base
      final newChant = ChantDeMesse(
        id: chantId,
        sectionId: 0, // Sera mis à jour plus tard
        titre: 'Chant $chantId',
        description: 'Chant créé localement',
        audioPath: null,
        pdfPath: null,
        imagePath: null,
        audioFiles: null,
        pdfFiles: null,
        imageFiles: null,
        sopranoFiles: null,
        altoFiles: null,
        tenorFiles: null,
        basseFiles: null,
        tuttiFiles: null,
        ordre: 0,
        active: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await updateChant(newChant);
    }
  }

  /// Ajouter un fichier en attente
  static Future<void> addPendingFile({
    required int chantId,
    required String filePath,
    required String fileType,
    String? pupitre,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingFilesJson = prefs.getString(_pendingFilesKey) ?? '{}';
    final Map<String, dynamic> pendingFiles = json.decode(pendingFilesJson);

    final fileKey = '$chantId';
    if (!pendingFiles.containsKey(fileKey)) {
      pendingFiles[fileKey] = [];
    }

    pendingFiles[fileKey].add({
      'filePath': filePath,
      'fileType': fileType,
      'pupitre': pupitre,
      'timestamp': DateTime.now().toIso8601String(),
      'synced': false,
    });

    await prefs.setString(_pendingFilesKey, json.encode(pendingFiles));
    
    // Mettre à jour le chant dans la liste
    final chant = await getChant(chantId);
    if (chant != null) {
      await updateChant(chant);
    }
  }

  /// Récupérer les fichiers locaux d'un chant
  static Future<List<Map<String, dynamic>>> getLocalFiles(int chantId) async {
    final prefs = await SharedPreferences.getInstance();
    final localFilesJson = prefs.getString(_localFilesKey) ?? '{}';
    final Map<String, dynamic> localFiles = json.decode(localFilesJson);
    
    final fileKey = '$chantId';
    if (localFiles.containsKey(fileKey)) {
      return List<Map<String, dynamic>>.from(localFiles[fileKey]);
    }
    
    return [];
  }

  /// Récupérer les fichiers en attente d'un chant
  static Future<List<Map<String, dynamic>>> getPendingFiles(int chantId) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingFilesJson = prefs.getString(_pendingFilesKey) ?? '{}';
    final Map<String, dynamic> pendingFiles = json.decode(pendingFilesJson);
    
    final fileKey = '$chantId';
    if (pendingFiles.containsKey(fileKey)) {
      return List<Map<String, dynamic>>.from(pendingFiles[fileKey]);
    }
    
    return [];
  }

  /// Marquer les fichiers comme synchronisés
  static Future<void> markFilesAsSynced(int chantId, List<String> filePaths) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingFilesJson = prefs.getString(_pendingFilesKey) ?? '{}';
    final Map<String, dynamic> pendingFiles = json.decode(pendingFilesJson);

    final fileKey = '$chantId';
    if (pendingFiles.containsKey(fileKey)) {
      final files = List<Map<String, dynamic>>.from(pendingFiles[fileKey]);
      
      for (int i = 0; i < files.length; i++) {
        if (filePaths.contains(files[i]['filePath'])) {
          files[i]['synced'] = true;
        }
      }
      
      pendingFiles[fileKey] = files;
      await prefs.setString(_pendingFilesKey, json.encode(pendingFiles));
    }
  }

  /// Supprimer les fichiers synchronisés
  static Future<void> removeSyncedFiles(int chantId) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingFilesJson = prefs.getString(_pendingFilesKey) ?? '{}';
    final Map<String, dynamic> pendingFiles = json.decode(pendingFilesJson);

    final fileKey = '$chantId';
    if (pendingFiles.containsKey(fileKey)) {
      final files = List<Map<String, dynamic>>.from(pendingFiles[fileKey]);
      final unsyncedFiles = files.where((file) => file['synced'] != true).toList();
      
      pendingFiles[fileKey] = unsyncedFiles;
      await prefs.setString(_pendingFilesKey, json.encode(pendingFiles));
    }
  }

  /// Vérifier s'il y a des fichiers en attente
  static Future<bool> hasPendingFiles(int chantId) async {
    final pendingFiles = await getPendingFiles(chantId);
    return pendingFiles.any((file) => file['synced'] != true);
  }

  // ===== FUSION DES FICHIERS =====

  static Future<ChantDeMesse> _mergeLocalFiles(ChantDeMesse chant) async {
    final localFiles = await getLocalFiles(chant.id);
    final pendingFiles = await getPendingFiles(chant.id);

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
    String filePath = file['filePath'];
    String fileType = file['fileType'];
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

  // ===== GESTION DES MESSES ET SECTIONS =====

  /// Sauvegarder les messes
  static Future<void> saveMesses(List<Messe> messes) async {
    final prefs = await SharedPreferences.getInstance();
    final messesJson = json.encode(messes.map((messe) => messe.toJson()).toList());
    await prefs.setString(_messesKey, messesJson);
  }

  /// Récupérer les messes
  static Future<List<Messe>> getMesses() async {
    final prefs = await SharedPreferences.getInstance();
    final messesJson = prefs.getString(_messesKey);
    
    if (messesJson == null) return [];

    try {
      final List<dynamic> messesList = json.decode(messesJson);
      return messesList.map((json) => Messe.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des messes: $e');
      return [];
    }
  }

  /// Sauvegarder les sections
  static Future<void> saveSections(List<MesseSection> sections) async {
    final prefs = await SharedPreferences.getInstance();
    final sectionsJson = json.encode(sections.map((section) => section.toJson()).toList());
    await prefs.setString(_sectionsKey, sectionsJson);
  }

  /// Récupérer les sections
  static Future<List<MesseSection>> getSections() async {
    final prefs = await SharedPreferences.getInstance();
    final sectionsJson = prefs.getString(_sectionsKey);
    
    if (sectionsJson == null) return [];

    try {
      final List<dynamic> sectionsList = json.decode(sectionsJson);
      return sectionsList.map((json) => MesseSection.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors de la récupération des sections: $e');
      return [];
    }
  }

  // ===== UTILITAIRES =====

  /// Nettoyer le cache
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chantsKey);
    await prefs.remove(_messesKey);
    await prefs.remove(_sectionsKey);
    await prefs.remove(_localFilesKey);
    await prefs.remove(_pendingFilesKey);
    await prefs.remove(_lastSyncKey);
  }

  /// Obtenir la date de dernière synchronisation
  static Future<DateTime?> getLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncString = prefs.getString(_lastSyncKey);
    
    if (lastSyncString != null) {
      try {
        return DateTime.parse(lastSyncString);
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }

  /// Obtenir la taille du cache
  static Future<int> getCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    int size = 0;
    
    final keys = [_chantsKey, _messesKey, _sectionsKey, _localFilesKey, _pendingFilesKey];
    for (String key in keys) {
      final value = prefs.getString(key);
      if (value != null) {
        size += value.length;
      }
    }
    
    return size;
  }
}
