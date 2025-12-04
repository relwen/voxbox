import 'package:voxbox/models/messe.dart';
import 'package:voxbox/models/messe_section.dart';
import 'package:voxbox/models/chant_de_messe.dart';

class BackendAdapter {
  /// Convertit les données du backend (Reference) vers MesseSection
  static MesseSection referenceToMesseSection(Map<String, dynamic> referenceData) {
    return MesseSection(
      id: int.tryParse(referenceData['id']?.toString() ?? '0') ?? 0,
      messeId: int.tryParse(referenceData['messe_id']?.toString() ?? '0') ?? 0,
      nom: referenceData['name']?.toString() ?? 'Section sans nom',
      description: referenceData['description']?.toString(),
      ordre: int.tryParse(referenceData['order_position']?.toString() ?? '0') ?? 0,
      active: true, // Par défaut actif
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      chants: referenceData['partitions'] != null
          ? (referenceData['partitions'] as List)
              .map((partition) => partitionToChantDeMesse(partition))
              .toList()
          : null,
    );
  }

  /// Convertit les données du backend (Partition) vers ChantDeMesse
  static ChantDeMesse partitionToChantDeMesse(Map<String, dynamic> partitionData) {
    print('🔄 Conversion partition: ${partitionData['id']} - ${partitionData['title']}');
    
    // Extraire les fichiers du champ unifié 'files' ou utiliser les anciens champs
    List<String> audioFiles = [];
    List<String> pdfFiles = [];
    List<String> imageFiles = [];
    
    // Nouveau système : champ 'files' unifié
    if (partitionData['files'] != null && partitionData['files'] is List) {
      final files = partitionData['files'] as List;
      print('📁 ${files.length} fichier(s) dans le champ unifié');
      
      for (var file in files) {
        if (file is Map) {
          // Format avec métadonnées : {'path': '...', 'name': '...', 'type': '...'}
          final path = file['path']?.toString() ?? '';
          final type = file['type']?.toString() ?? '';
          
          if (type == 'audio' || _isAudioFile(path)) {
            audioFiles.add(path);
          } else if (type == 'pdf' || path.toLowerCase().endsWith('.pdf')) {
            pdfFiles.add(path);
          } else if (type == 'image' || _isImageFile(path)) {
            imageFiles.add(path);
          }
        } else if (file is String) {
          // Format simple : juste le chemin
          final path = file;
          if (_isAudioFile(path)) {
            audioFiles.add(path);
          } else if (path.toLowerCase().endsWith('.pdf')) {
            pdfFiles.add(path);
          } else if (_isImageFile(path)) {
            imageFiles.add(path);
          }
        }
      }
    }
    
    // Ancien système : champs séparés (pour rétrocompatibilité)
    if (partitionData['audio_files'] != null && partitionData['audio_files'] is List) {
      audioFiles.addAll((partitionData['audio_files'] as List).map((e) => e.toString()));
    }
    if (partitionData['pdf_files'] != null && partitionData['pdf_files'] is List) {
      pdfFiles.addAll((partitionData['pdf_files'] as List).map((e) => e.toString()));
    }
    if (partitionData['image_files'] != null && partitionData['image_files'] is List) {
      imageFiles.addAll((partitionData['image_files'] as List).map((e) => e.toString()));
    }
    
    // Fichiers uniques (ancien système)
    if (partitionData['audio_path'] != null && audioFiles.isEmpty) {
      audioFiles.add(partitionData['audio_path'].toString());
    }
    if (partitionData['pdf_path'] != null && pdfFiles.isEmpty) {
      pdfFiles.add(partitionData['pdf_path'].toString());
    }
    if (partitionData['image_path'] != null && imageFiles.isEmpty) {
      imageFiles.add(partitionData['image_path'].toString());
    }
    
    // Organiser les fichiers par pupitre si disponible
    Map<String, List<String>> pupitreFiles = {};
    if (partitionData['pupitre_id'] != null) {
      final pupitreId = partitionData['pupitre_id'].toString();
      final pupitreNom = partitionData['pupitre']?['nom']?.toString()?.toLowerCase() ?? '';
      
      // Mapper les fichiers audio par pupitre
      if (audioFiles.isNotEmpty) {
        if (pupitreNom.contains('soprano') || pupitreNom.contains('soprane')) {
          pupitreFiles['soprano'] = audioFiles;
        } else if (pupitreNom.contains('alto') || pupitreNom.contains('mezzo')) {
          pupitreFiles['alto'] = audioFiles;
        } else if (pupitreNom.contains('ténor') || pupitreNom.contains('tenor')) {
          pupitreFiles['tenor'] = audioFiles;
        } else if (pupitreNom.contains('basse') || pupitreNom.contains('bariton')) {
          pupitreFiles['basse'] = audioFiles;
        } else if (pupitreNom.contains('tutti')) {
          pupitreFiles['tutti'] = audioFiles;
        }
      }
    }
    
    print('✅ Fichiers extraits - Audio: ${audioFiles.length}, PDF: ${pdfFiles.length}, Images: ${imageFiles.length}');
    
    return ChantDeMesse(
      id: int.tryParse(partitionData['id']?.toString() ?? '0') ?? 0,
      sectionId: int.tryParse(partitionData['reference_id']?.toString() ?? partitionData['rubrique_section_id']?.toString() ?? '0') ?? 0,
      titre: partitionData['title']?.toString() ?? 'Chant sans titre',
      description: partitionData['description']?.toString(),
      audioPath: audioFiles.isNotEmpty ? audioFiles.first : partitionData['audio_path']?.toString(),
      pdfPath: pdfFiles.isNotEmpty ? pdfFiles.first : partitionData['pdf_path']?.toString(),
      imagePath: imageFiles.isNotEmpty ? imageFiles.first : partitionData['image_path']?.toString(),
      audioFiles: audioFiles.isNotEmpty ? audioFiles : null,
      pdfFiles: pdfFiles.isNotEmpty ? pdfFiles : null,
      imageFiles: imageFiles.isNotEmpty ? imageFiles : null,
      sopranoFiles: pupitreFiles['soprano'],
      altoFiles: pupitreFiles['alto'],
      tenorFiles: pupitreFiles['tenor'],
      basseFiles: pupitreFiles['basse'],
      tuttiFiles: pupitreFiles['tutti'],
      ordre: int.tryParse(partitionData['ordre']?.toString() ?? '0') ?? 0,
      active: partitionData['active'] == true || partitionData['active'] == 'true' || partitionData['active'] == null,
      createdAt: partitionData['created_at'] != null 
          ? DateTime.tryParse(partitionData['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: partitionData['updated_at'] != null 
          ? DateTime.tryParse(partitionData['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
  
  static bool _isAudioFile(String path) {
    final audioExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.ogg'];
    return audioExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }
  
  static bool _isImageFile(String path) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp'];
    return imageExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  /// Convertit les données du backend vers Messe avec sections
  static Messe backendDataToMesse(Map<String, dynamic> messeData) {
    List<MesseSection>? sections;
    
    if (messeData['references'] != null) {
      sections = (messeData['references'] as List)
          .map((reference) => referenceToMesseSection(reference))
          .toList();
    }

    return Messe(
      id: int.tryParse(messeData['id']?.toString() ?? '0') ?? 0,
      nom: messeData['nom']?.toString() ?? 'Messe sans nom',
      description: messeData['description']?.toString(),
      couleur: messeData['couleur']?.toString() ?? '#2196F3',
      icone: messeData['icone']?.toString() ?? 'church',
      active: messeData['active'] == true || messeData['active'] == 'true',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sections: sections,
    );
  }

  /// Convertit une liste de données backend vers une liste de Messe
  static List<Messe> backendDataListToMesses(List<dynamic> messesData) {
    return messesData
        .map((messeData) => backendDataToMesse(messeData))
        .toList();
  }

  /// Convertit une liste de références backend vers une liste de MesseSection
  static List<MesseSection> referencesToMesseSections(List<dynamic> referencesData) {
    return referencesData
        .map((referenceData) => referenceToMesseSection(referenceData))
        .toList();
  }

  /// Convertit une liste de partitions backend vers une liste de ChantDeMesse
  static List<ChantDeMesse> partitionsToChantsDeMesse(List<dynamic> partitionsData) {
    return partitionsData
        .map((partitionData) => partitionToChantDeMesse(partitionData))
        .toList();
  }
}
