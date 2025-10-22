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
    return ChantDeMesse(
      id: int.tryParse(partitionData['id']?.toString() ?? '0') ?? 0,
      sectionId: int.tryParse(partitionData['reference_id']?.toString() ?? '0') ?? 0,
      titre: partitionData['title']?.toString() ?? 'Chant sans titre',
      description: partitionData['description']?.toString(),
      audioPath: partitionData['audio_path']?.toString(),
      pdfPath: partitionData['pdf_path']?.toString(),
      imagePath: partitionData['image_path']?.toString(),
      audioFiles: partitionData['audio_files'] != null 
          ? List<String>.from(partitionData['audio_files'])
          : null,
      pdfFiles: partitionData['pdf_files'] != null 
          ? List<String>.from(partitionData['pdf_files'])
          : null,
      imageFiles: partitionData['image_files'] != null 
          ? List<String>.from(partitionData['image_files'])
          : null,
      sopranoFiles: null, // Pas de pupitres dans le backend actuel
      altoFiles: null,
      tenorFiles: null,
      basseFiles: null,
      tuttiFiles: null,
      ordre: 0, // Pas d'ordre dans le backend actuel
      active: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
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
