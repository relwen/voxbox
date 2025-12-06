import 'package:voxbox/models/messe.dart';
import 'package:voxbox/models/messe_section.dart';
import 'package:voxbox/models/chant_de_messe.dart';
import 'package:voxbox/models/vocalise.dart';
import 'package:voxbox/functions/appconstants.dart';

class BackendAdapter {
  /// Convertit les données du backend (Reference) vers MesseSection
  /// messeId: ID réel de la RubriqueSection (messe) - doit être passé depuis le contexte
  static MesseSection referenceToMesseSection(Map<String, dynamic> referenceData, {int? messeId}) {
    final sectionId = int.tryParse(referenceData['id']?.toString() ?? '0') ?? 0;
    final sectionName = referenceData['name']?.toString() ?? 'Section sans nom';
    
    // Convertir les partitions en chants si disponibles
    List<ChantDeMesse>? chants;
    if (referenceData['partitions'] != null && referenceData['partitions'] is List) {
      final partitionsList = referenceData['partitions'] as List;
      print('📋 Section "$sectionName" (ID: $sectionId) - ${partitionsList.length} partition(s) trouvée(s) dans les références');
      
      if (partitionsList.isNotEmpty) {
        chants = partitionsList
            .map((partition) {
              try {
                return partitionToChantDeMesse(partition);
              } catch (e) {
                print('❌ Erreur lors de la conversion de la partition: $e');
                return null;
              }
            })
            .where((chant) => chant != null)
            .cast<ChantDeMesse>()
            .toList();
        
        print('✅ ${chants.length} chant(s) converti(s) pour la section "$sectionName"');
      } else {
        print('⚠️ Aucune partition dans la liste pour la section "$sectionName"');
      }
    } else {
      print('⚠️ Pas de partitions dans les données de référence pour la section "$sectionName"');
    }
    
    return MesseSection(
      id: sectionId,
      // Utiliser messeId passé en paramètre si disponible, sinon utiliser messe_id de la référence
      messeId: messeId ?? int.tryParse(referenceData['messe_id']?.toString() ?? '0') ?? 0,
      nom: sectionName,
      description: referenceData['description']?.toString(),
      ordre: int.tryParse(referenceData['order_position']?.toString() ?? '0') ?? 0,
      active: true, // Par défaut actif
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      chants: chants,
    );
  }

  /// Convertit les données du backend (Partition) vers ChantDeMesse
  static ChantDeMesse partitionToChantDeMesse(Map<String, dynamic> partitionData) {
    print('🔄 Conversion partition: ${partitionData['id']} - ${partitionData['title']}');
    
    // Extraire les fichiers du champ unifié 'files' ou utiliser les anciens champs
    List<String> audioFiles = [];
    List<String> pdfFiles = [];
    List<String> imageFiles = [];
    
    // PRIORITÉ 1: Utiliser files_with_metadata qui contient les URLs complètes
    if (partitionData['files_with_metadata'] != null && partitionData['files_with_metadata'] is List) {
      final filesWithMetadata = partitionData['files_with_metadata'] as List;
      print('📁 ${filesWithMetadata.length} fichier(s) avec métadonnées');
      
      for (var file in filesWithMetadata) {
        if (file is Map) {
          // Format avec métadonnées : {'path': '...', 'url': '...', 'name': '...', 'type': '...'}
          final url = file['url']?.toString() ?? '';
          final path = file['path']?.toString() ?? '';
          final type = file['type']?.toString() ?? '';
          
          // Utiliser l'URL si disponible, sinon le chemin
          final filePath = url.isNotEmpty ? url : path;
          
          print('   📄 Fichier: path=$path, url=$url, type=$type');
          
          // Détecter le type de fichier
          bool isAudio = type == 'audio' || _isAudioFile(path) || _isAudioFile(url);
          bool isPdf = type == 'pdf' || path.toLowerCase().endsWith('.pdf') || url.toLowerCase().endsWith('.pdf');
          bool isImage = type == 'image' || _isImageFile(path) || _isImageFile(url);
          
          if (isAudio) {
            audioFiles.add(filePath);
            print('      ✅ Ajouté comme audio: $filePath');
          } else if (isPdf) {
            pdfFiles.add(filePath);
            print('      ✅ Ajouté comme PDF: $filePath');
          } else if (isImage) {
            imageFiles.add(filePath);
            print('      ✅ Ajouté comme image: $filePath');
          } else {
            print('      ⚠️ Type non reconnu pour: $filePath');
          }
        }
      }
    }
    
    // PRIORITÉ 2: Utiliser le champ 'files' unifié si files_with_metadata n'est pas disponible
    if (audioFiles.isEmpty && pdfFiles.isEmpty && imageFiles.isEmpty) {
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
    Map<String, List<String>> pupitreFiles = {
      'soprano': [],
      'alto': [],
      'tenor': [],
      'basse': [],
      'tutti': [],
    };
    
    if (partitionData['pupitre'] != null && partitionData['pupitre'] is Map) {
      final pupitreData = partitionData['pupitre'] as Map;
      final pupitreNom = (pupitreData['nom'] as String?)?.toLowerCase() ?? '';
      
      print('🎭 Pupitre détecté: $pupitreNom (original: ${pupitreData['nom']})');
      
      // Mapper les fichiers audio par pupitre
      if (audioFiles.isNotEmpty) {
        String? pupitreKey;
        if (pupitreNom.contains('soprano') || pupitreNom.contains('soprane')) {
          pupitreKey = 'soprano';
        } else if (pupitreNom.contains('alto') || pupitreNom.contains('mezzo')) {
          pupitreKey = 'alto';
        } else if (pupitreNom.contains('ténor') || pupitreNom.contains('tenor')) {
          pupitreKey = 'tenor';
        } else if (pupitreNom.contains('basse') || pupitreNom.contains('bariton') || pupitreNom == 'basses') {
          pupitreKey = 'basse';
        } else if (pupitreNom.contains('tutti')) {
          pupitreKey = 'tutti';
        }
        
        if (pupitreKey != null && pupitreFiles.containsKey(pupitreKey)) {
          pupitreFiles[pupitreKey] = List.from(audioFiles);
          print('✅ ${audioFiles.length} fichier(s) audio assigné(s) au pupitre $pupitreKey');
          for (var file in audioFiles) {
            print('   📄 $file');
          }
        } else {
          print('⚠️ Aucun pupitre correspondant trouvé pour: $pupitreNom');
        }
      } else {
        print('⚠️ Aucun fichier audio à assigner au pupitre $pupitreNom');
      }
    } else {
      print('⚠️ Pas de pupitre dans les données de partition');
    }
    
    print('✅ Fichiers extraits - Audio: ${audioFiles.length}, PDF: ${pdfFiles.length}, Images: ${imageFiles.length}');
    print('🎭 Fichiers par pupitre - Soprano: ${pupitreFiles['soprano']!.length}, Alto: ${pupitreFiles['alto']!.length}, Ténor: ${pupitreFiles['tenor']!.length}, Basse: ${pupitreFiles['basse']!.length}, Tutti: ${pupitreFiles['tutti']!.length}');
    
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
      sopranoFiles: pupitreFiles['soprano']!.isNotEmpty ? pupitreFiles['soprano'] : null,
      altoFiles: pupitreFiles['alto']!.isNotEmpty ? pupitreFiles['alto'] : null,
      tenorFiles: pupitreFiles['tenor']!.isNotEmpty ? pupitreFiles['tenor'] : null,
      basseFiles: pupitreFiles['basse']!.isNotEmpty ? pupitreFiles['basse'] : null,
      tuttiFiles: pupitreFiles['tutti']!.isNotEmpty ? pupitreFiles['tutti'] : null,
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
    final audioExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.opus', '.flac', '.mp4'];
    return audioExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }
  
  static bool _isImageFile(String path) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp'];
    return imageExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  }

  /// Convertit les données du backend vers Messe avec sections
  static Messe backendDataToMesse(Map<String, dynamic> messeData) {
    List<MesseSection>? sections;
    
    // Récupérer l'ID réel de la RubriqueSection (messe)
    final messeId = int.tryParse(messeData['id']?.toString() ?? '0') ?? 0;
    
    if (messeData['references'] != null) {
      sections = (messeData['references'] as List)
          .map((reference) => referenceToMesseSection(reference, messeId: messeId))
          .toList();
    }

    return Messe(
      id: messeId,
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
  /// messeId: ID réel de la RubriqueSection (messe) - doit être passé depuis le contexte
  static List<MesseSection> referencesToMesseSections(List<dynamic> referencesData, {int? messeId}) {
    return referencesData
        .map((referenceData) => referenceToMesseSection(referenceData, messeId: messeId))
        .toList();
  }

  /// Convertit une liste de partitions backend vers une liste de ChantDeMesse
  /// Convertit une liste de partitions en chants de messe
  /// sectionId: ID de la section (référence générée) - utilisé pour associer correctement les chants à leur section
  static List<ChantDeMesse> partitionsToChantsDeMesse(List<dynamic> partitionsData, {int? sectionId}) {
    return partitionsData
        .map((partitionData) {
          final chant = partitionToChantDeMesse(partitionData);
          // Si un sectionId est fourni, l'utiliser pour s'assurer que le chant est associé à la bonne section
          if (sectionId != null && chant.sectionId != sectionId) {
            print('🔄 Correction sectionId pour chant ${chant.id}: ${chant.sectionId} -> $sectionId');
            return chant.copyWith(sectionId: sectionId);
          }
          return chant;
        })
        .toList();
  }

  /// Convertit les données du backend vers Vocalise avec support des sous-dossiers
  static Vocalise backendDataToVocalise(Map<String, dynamic> vocaliseData) {
    print('🔄 Conversion vocalise: ${vocaliseData['id']} - ${vocaliseData['title']}');

    // Extraire les fichiers du champ unifié 'files' ou utiliser les anciens champs
    List<String> audioFiles = [];
    List<String> pdfFiles = [];
    List<String> imageFiles = [];

    // Support des fichiers organisés par pupitre
    Map<String, List<String>> pupitreAudioFiles = {
      'soprano': [],
      'alto': [],
      'tenor': [],
      'basse': [],
      'tutti': [],
    };

    // Nouveau système : champ 'files' unifié
    if (vocaliseData['files'] != null && vocaliseData['files'] is List) {
      final files = vocaliseData['files'] as List;
      print('📁 ${files.length} fichier(s) dans le champ unifié');

      for (var file in files) {
        if (file is Map) {
          // Format avec métadonnées : {'path': '...', 'name': '...', 'type': '...', 'pupitre': '...'}
          final path = file['path']?.toString() ?? '';
          final type = file['type']?.toString() ?? '';
          final pupitre = (file['pupitre'] as String?)?.toLowerCase() ?? '';

          if (type == 'audio' || _isAudioFile(path)) {
            audioFiles.add(path);
            // Organiser par pupitre si spécifié
            if (pupitre.isNotEmpty && pupitreAudioFiles.containsKey(pupitre)) {
              pupitreAudioFiles[pupitre]!.add(path);
            }
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
    if (vocaliseData['audio_files'] != null && vocaliseData['audio_files'] is List) {
      audioFiles.addAll((vocaliseData['audio_files'] as List).map((e) => e.toString()));
    }
    if (vocaliseData['pdf_files'] != null && vocaliseData['pdf_files'] is List) {
      pdfFiles.addAll((vocaliseData['pdf_files'] as List).map((e) => e.toString()));
    }
    if (vocaliseData['image_files'] != null && vocaliseData['image_files'] is List) {
      imageFiles.addAll((vocaliseData['image_files'] as List).map((e) => e.toString()));
    }

    // Fichiers par pupitre (depuis le backend)
    if (vocaliseData['soprano_files'] != null && vocaliseData['soprano_files'] is List) {
      pupitreAudioFiles['soprano']!.addAll((vocaliseData['soprano_files'] as List).map((e) => e.toString()));
    }
    if (vocaliseData['alto_files'] != null && vocaliseData['alto_files'] is List) {
      pupitreAudioFiles['alto']!.addAll((vocaliseData['alto_files'] as List).map((e) => e.toString()));
    }
    if (vocaliseData['tenor_files'] != null && vocaliseData['tenor_files'] is List) {
      pupitreAudioFiles['tenor']!.addAll((vocaliseData['tenor_files'] as List).map((e) => e.toString()));
    }
    if (vocaliseData['basse_files'] != null && vocaliseData['basse_files'] is List) {
      pupitreAudioFiles['basse']!.addAll((vocaliseData['basse_files'] as List).map((e) => e.toString()));
    }
    if (vocaliseData['tutti_files'] != null && vocaliseData['tutti_files'] is List) {
      pupitreAudioFiles['tutti']!.addAll((vocaliseData['tutti_files'] as List).map((e) => e.toString()));
    }

    // Fichiers uniques (ancien système)
    if (vocaliseData['audio_path'] != null && audioFiles.isEmpty) {
      audioFiles.add(vocaliseData['audio_path'].toString());
    }

    print('✅ Fichiers extraits - Audio: ${audioFiles.length}, PDF: ${pdfFiles.length}, Images: ${imageFiles.length}');
    print('   Pupitres - Soprano: ${pupitreAudioFiles['soprano']!.length}, Alto: ${pupitreAudioFiles['alto']!.length}, Ténor: ${pupitreAudioFiles['tenor']!.length}, Basse: ${pupitreAudioFiles['basse']!.length}, Tutti: ${pupitreAudioFiles['tutti']!.length}');

    // Déterminer audioPath et audioUrl
    final audioPathValue = audioFiles.isNotEmpty ? audioFiles.first : vocaliseData['audio_path']?.toString();
    final audioUrlValue = vocaliseData['audio_url']?.toString() ?? 
                         (audioPathValue != null ? '${AppConstance.baseURL}/storage/$audioPathValue' : null);

    return Vocalise(
      id: int.tryParse(vocaliseData['id']?.toString() ?? '0') ?? 0,
      title: vocaliseData['title']?.toString() ?? 'Vocalise sans titre',
      description: vocaliseData['description']?.toString(),
      voicePart: vocaliseData['voice_part']?.toString() ?? '',
      audioPath: audioPathValue,
      audioUrl: audioUrlValue,
      choraleId: int.tryParse(vocaliseData['chorale_id']?.toString() ?? '0') ?? 0,
      choraleName: vocaliseData['chorale']?['name']?.toString(),
      createdAt: vocaliseData['created_at'] != null
          ? DateTime.tryParse(vocaliseData['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: vocaliseData['updated_at'] != null
          ? DateTime.tryParse(vocaliseData['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isDownloaded: vocaliseData['is_downloaded'] ?? false,
      localAudioPath: vocaliseData['local_audio_path']?.toString(),
      audioFiles: audioFiles.isNotEmpty ? audioFiles : null,
      pdfFiles: pdfFiles.isNotEmpty ? pdfFiles : null,
      imageFiles: imageFiles.isNotEmpty ? imageFiles : null,
      sopranoFiles: pupitreAudioFiles['soprano']!.isNotEmpty ? pupitreAudioFiles['soprano'] : null,
      altoFiles: pupitreAudioFiles['alto']!.isNotEmpty ? pupitreAudioFiles['alto'] : null,
      tenorFiles: pupitreAudioFiles['tenor']!.isNotEmpty ? pupitreAudioFiles['tenor'] : null,
      basseFiles: pupitreAudioFiles['basse']!.isNotEmpty ? pupitreAudioFiles['basse'] : null,
      tuttiFiles: pupitreAudioFiles['tutti']!.isNotEmpty ? pupitreAudioFiles['tutti'] : null,
    );
  }

  /// Convertit une liste de données backend vers une liste de Vocalise
  static List<Vocalise> backendDataListToVocalises(List<dynamic> vocalisesData) {
    return vocalisesData
        .map((vocaliseData) => backendDataToVocalise(vocaliseData))
        .toList();
  }
}
