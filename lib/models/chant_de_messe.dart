import 'package:voxbox/functions/appconstants.dart';

class ChantDeMesse {
  final int id;
  final int sectionId;
  final String titre;
  final String? description;
  final String? audioPath;
  final String? pdfPath;
  final String? imagePath;
  final List<String>? audioFiles;
  final List<String>? pdfFiles;
  final List<String>? imageFiles;
  final List<String>? sopranoFiles;
  final List<String>? altoFiles;
  final List<String>? tenorFiles;
  final List<String>? basseFiles;
  final List<String>? tuttiFiles;
  final int ordre;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Helper pour générer une URL complète
  static String _buildUrl(String file) {
    // Si c'est déjà une URL complète, la retourner telle quelle
    if (file.startsWith('http://') || file.startsWith('https://')) {
      return file;
    }
    // Sinon, construire l'URL avec la base
    return '${AppConstance.baseURL}/storage/$file';
  }
  
  // URLs complètes
  String? get audioUrl => audioPath != null ? _buildUrl(audioPath!) : null;
  String? get pdfUrl => pdfPath != null ? _buildUrl(pdfPath!) : null;
  String? get imageUrl => imagePath != null ? _buildUrl(imagePath!) : null;
  
  // URLs des fichiers multiples
  List<String> get audioUrls => audioFiles?.map((file) => _buildUrl(file)).toList() ?? [];
  List<String> get pdfUrls => pdfFiles?.map((file) => _buildUrl(file)).toList() ?? [];
  List<String> get imageUrls => imageFiles?.map((file) => _buildUrl(file)).toList() ?? [];
  
  // URLs des pupitres
  List<String> get sopranoUrls => sopranoFiles?.map((file) => _buildUrl(file)).toList() ?? [];
  List<String> get altoUrls => altoFiles?.map((file) => _buildUrl(file)).toList() ?? [];
  List<String> get tenorUrls => tenorFiles?.map((file) => _buildUrl(file)).toList() ?? [];
  List<String> get basseUrls => basseFiles?.map((file) => _buildUrl(file)).toList() ?? [];
  List<String> get tuttiUrls => tuttiFiles?.map((file) => _buildUrl(file)).toList() ?? [];

  ChantDeMesse({
    required this.id,
    required this.sectionId,
    required this.titre,
    this.description,
    this.audioPath,
    this.pdfPath,
    this.imagePath,
    this.audioFiles,
    this.pdfFiles,
    this.imageFiles,
    this.sopranoFiles,
    this.altoFiles,
    this.tenorFiles,
    this.basseFiles,
    this.tuttiFiles,
    required this.ordre,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChantDeMesse.fromJson(Map<String, dynamic> json) {
    return ChantDeMesse(
      id: json['id'] ?? 0,
      sectionId: json['section_id'] ?? 0,
      titre: json['titre'] ?? 'Chant sans titre',
      description: json['description'],
      audioPath: json['audio_path'],
      pdfPath: json['pdf_path'],
      imagePath: json['image_path'],
      audioFiles: json['audio_files'] != null ? List<String>.from(json['audio_files']) : null,
      pdfFiles: json['pdf_files'] != null ? List<String>.from(json['pdf_files']) : null,
      imageFiles: json['image_files'] != null ? List<String>.from(json['image_files']) : null,
      sopranoFiles: json['soprano_files'] != null ? List<String>.from(json['soprano_files']) : null,
      altoFiles: json['alto_files'] != null ? List<String>.from(json['alto_files']) : null,
      tenorFiles: json['tenor_files'] != null ? List<String>.from(json['tenor_files']) : null,
      basseFiles: json['basse_files'] != null ? List<String>.from(json['basse_files']) : null,
      tuttiFiles: json['tutti_files'] != null ? List<String>.from(json['tutti_files']) : null,
      ordre: json['ordre'] ?? 0,
      active: json['active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'section_id': sectionId,
      'titre': titre,
      'description': description,
      'audio_path': audioPath,
      'pdf_path': pdfPath,
      'image_path': imagePath,
      'audio_files': audioFiles,
      'pdf_files': pdfFiles,
      'image_files': imageFiles,
      'soprano_files': sopranoFiles,
      'alto_files': altoFiles,
      'tenor_files': tenorFiles,
      'basse_files': basseFiles,
      'tutti_files': tuttiFiles,
      'ordre': ordre,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChantDeMesse copyWith({
    int? id,
    int? sectionId,
    String? titre,
    String? description,
    String? audioPath,
    String? pdfPath,
    String? imagePath,
    List<String>? audioFiles,
    List<String>? pdfFiles,
    List<String>? imageFiles,
    List<String>? sopranoFiles,
    List<String>? altoFiles,
    List<String>? tenorFiles,
    List<String>? basseFiles,
    List<String>? tuttiFiles,
    int? ordre,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChantDeMesse(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      audioPath: audioPath ?? this.audioPath,
      pdfPath: pdfPath ?? this.pdfPath,
      imagePath: imagePath ?? this.imagePath,
      audioFiles: audioFiles ?? this.audioFiles,
      pdfFiles: pdfFiles ?? this.pdfFiles,
      imageFiles: imageFiles ?? this.imageFiles,
      sopranoFiles: sopranoFiles ?? this.sopranoFiles,
      altoFiles: altoFiles ?? this.altoFiles,
      tenorFiles: tenorFiles ?? this.tenorFiles,
      basseFiles: basseFiles ?? this.basseFiles,
      tuttiFiles: tuttiFiles ?? this.tuttiFiles,
      ordre: ordre ?? this.ordre,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Vérifier si le chant a un fichier audio
  bool hasAudio() {
    return audioPath != null || (audioFiles != null && audioFiles!.isNotEmpty);
  }

  // Vérifier si le chant a un PDF
  bool hasPdf() {
    return pdfPath != null || (pdfFiles != null && pdfFiles!.isNotEmpty);
  }

  // Vérifier si le chant a une image
  bool hasImage() {
    return imagePath != null || (imageFiles != null && imageFiles!.isNotEmpty);
  }
}
