import 'package:voxbox/functions/appconstants.dart';

class Vocalise {
  final int id;
  final String title;
  final String? description;
  final String voicePart;
  final String? audioPath;
  final String? audioUrl;
  final int choraleId;
  final String? choraleName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDownloaded; // Pour savoir si le fichier audio est téléchargé localement
  final String? localAudioPath; // Chemin local du fichier audio
  
  // Support multi-fichiers
  final List<String>? audioFiles; // Fichiers audio multiples
  final List<String>? pdfFiles;   // Fichiers PDF
  final List<String>? imageFiles; // Fichiers images
  final List<String>? sopranoFiles; // Fichiers spécifiques au pupitre Soprano
  final List<String>? altoFiles;    // Fichiers spécifiques au pupitre Alto
  final List<String>? tenorFiles;   // Fichiers spécifiques au pupitre Ténor
  final List<String>? basseFiles;   // Fichiers spécifiques au pupitre Basse
  final List<String>? tuttiFiles;   // Fichiers pour tous les pupitres

  // URLs complètes pour les fichiers multiples
  List<String> get audioUrls => audioFiles?.map((file) => '${AppConstance.baseURL}/storage/$file').toList() ?? [];
  List<String> get pdfUrls => pdfFiles?.map((file) => '${AppConstance.baseURL}/storage/$file').toList() ?? [];
  List<String> get imageUrls => imageFiles?.map((file) => '${AppConstance.baseURL}/storage/$file').toList() ?? [];
  
  // URLs des pupitres
  List<String> get sopranoUrls => sopranoFiles?.map((file) => '${AppConstance.baseURL}/storage/$file').toList() ?? [];
  List<String> get altoUrls => altoFiles?.map((file) => '${AppConstance.baseURL}/storage/$file').toList() ?? [];
  List<String> get tenorUrls => tenorFiles?.map((file) => '${AppConstance.baseURL}/storage/$file').toList() ?? [];
  List<String> get basseUrls => basseFiles?.map((file) => '${AppConstance.baseURL}/storage/$file').toList() ?? [];
  List<String> get tuttiUrls => tuttiFiles?.map((file) => '${AppConstance.baseURL}/storage/$file').toList() ?? [];

  Vocalise({
    required this.id,
    required this.title,
    this.description,
    required this.voicePart,
    this.audioPath,
    this.audioUrl,
    required this.choraleId,
    this.choraleName,
    required this.createdAt,
    required this.updatedAt,
    this.isDownloaded = false,
    this.localAudioPath,
    this.audioFiles,
    this.pdfFiles,
    this.imageFiles,
    this.sopranoFiles,
    this.altoFiles,
    this.tenorFiles,
    this.basseFiles,
    this.tuttiFiles,
  });

  factory Vocalise.fromJson(Map<String, dynamic> json) {
    return Vocalise(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      voicePart: json['voice_part'],
      audioPath: json['audio_path'],
      audioUrl: json['audio_path'] != null ? '${AppConstance.baseURL}/storage/${json['audio_path']}' : null,
      choraleId: json['chorale_id'],
      choraleName: json['chorale']?['name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDownloaded: json['is_downloaded'] ?? false,
      localAudioPath: json['local_audio_path'],
      audioFiles: json['audio_files'] != null ? List<String>.from(json['audio_files']) : null,
      pdfFiles: json['pdf_files'] != null ? List<String>.from(json['pdf_files']) : null,
      imageFiles: json['image_files'] != null ? List<String>.from(json['image_files']) : null,
      sopranoFiles: json['soprano_files'] != null ? List<String>.from(json['soprano_files']) : null,
      altoFiles: json['alto_files'] != null ? List<String>.from(json['alto_files']) : null,
      tenorFiles: json['tenor_files'] != null ? List<String>.from(json['tenor_files']) : null,
      basseFiles: json['basse_files'] != null ? List<String>.from(json['basse_files']) : null,
      tuttiFiles: json['tutti_files'] != null ? List<String>.from(json['tutti_files']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'voice_part': voicePart,
      'audio_path': audioPath,
      'audio_url': audioUrl,
      'chorale_id': choraleId,
      'chorale_name': choraleName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_downloaded': isDownloaded,
      'local_audio_path': localAudioPath,
      'audio_files': audioFiles,
      'pdf_files': pdfFiles,
      'image_files': imageFiles,
      'soprano_files': sopranoFiles,
      'alto_files': altoFiles,
      'tenor_files': tenorFiles,
      'basse_files': basseFiles,
      'tutti_files': tuttiFiles,
    };
  }

  Vocalise copyWith({
    int? id,
    String? title,
    String? description,
    String? voicePart,
    String? audioPath,
    String? audioUrl,
    int? choraleId,
    String? choraleName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDownloaded,
    String? localAudioPath,
    List<String>? audioFiles,
    List<String>? pdfFiles,
    List<String>? imageFiles,
    List<String>? sopranoFiles,
    List<String>? altoFiles,
    List<String>? tenorFiles,
    List<String>? basseFiles,
    List<String>? tuttiFiles,
  }) {
    return Vocalise(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      voicePart: voicePart ?? this.voicePart,
      audioPath: audioPath ?? this.audioPath,
      audioUrl: audioUrl ?? this.audioUrl,
      choraleId: choraleId ?? this.choraleId,
      choraleName: choraleName ?? this.choraleName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      audioFiles: audioFiles ?? this.audioFiles,
      pdfFiles: pdfFiles ?? this.pdfFiles,
      imageFiles: imageFiles ?? this.imageFiles,
      sopranoFiles: sopranoFiles ?? this.sopranoFiles,
      altoFiles: altoFiles ?? this.altoFiles,
      tenorFiles: tenorFiles ?? this.tenorFiles,
      basseFiles: basseFiles ?? this.basseFiles,
      tuttiFiles: tuttiFiles ?? this.tuttiFiles,
    );
  }

  @override
  String toString() {
    return 'Vocalise(id: $id, title: $title, voicePart: $voicePart, choraleId: $choraleId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vocalise && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
