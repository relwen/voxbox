import 'package:voxbox/functions/appconstants.dart';

class Partition {
  final int id;
  final String title;
  final String? description;
  final String? audioPath; // Chemin du fichier audio sur le serveur
  final String? audioUrl; // URL complète du fichier audio
  final String? pdfPath; // Chemin du fichier PDF sur le serveur
  final String? pdfUrl; // URL complète du fichier PDF
  final String? imagePath; // Chemin de l'image sur le serveur
  final String? imageUrl; // URL complète de l'image
  final int categoryId;
  final String? categoryName;
  final String? categoryColor;
  final String? categoryIcon;
  final int choraleId;
  final String? choraleName;
  final DateTime createdAt;
  final DateTime updatedAt;
  bool isDownloaded;
  String? localAudioPath;
  String? localPdfPath;
  String? localImagePath;

  Partition({
    required this.id,
    required this.title,
    this.description,
    this.audioPath,
    this.audioUrl,
    this.pdfPath,
    this.pdfUrl,
    this.imagePath,
    this.imageUrl,
    required this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.categoryIcon,
    required this.choraleId,
    this.choraleName,
    required this.createdAt,
    required this.updatedAt,
    this.isDownloaded = false,
    this.localAudioPath,
    this.localPdfPath,
    this.localImagePath,
  });

  factory Partition.fromJson(Map<String, dynamic> json) {
    // Fonction helper pour convertir en int
    int _toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Partition(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      audioPath: json['audio_path']?.toString(),
      audioUrl: json['audio_path'] != null ? '${AppConstance.baseURL}/storage/${json['audio_path']}' : null,
      pdfPath: json['pdf_path']?.toString(),
      pdfUrl: json['pdf_path'] != null ? '${AppConstance.baseURL}/storage/${json['pdf_path']}' : null,
      imagePath: json['image_path']?.toString(),
      imageUrl: json['image_path'] != null ? '${AppConstance.baseURL}/storage/${json['image_path']}' : null,
      categoryId: _toInt(json['category_id']),
      categoryName: json['category']?['name']?.toString() ?? json['category_name']?.toString(),
      categoryColor: json['category']?['color']?.toString() ?? json['category_color']?.toString(),
      categoryIcon: json['category']?['icon']?.toString() ?? json['category_icon']?.toString(),
      choraleId: _toInt(json['chorale_id']),
      choraleName: json['chorale']?['name']?.toString() ?? json['chorale_name']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
      isDownloaded: json['is_downloaded'] == true || json['is_downloaded'] == 'true',
      localAudioPath: json['local_audio_path']?.toString(),
      localPdfPath: json['local_pdf_path']?.toString(),
      localImagePath: json['local_image_path']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'audio_path': audioPath,
      'audio_url': audioUrl,
      'pdf_path': pdfPath,
      'pdf_url': pdfUrl,
      'image_path': imagePath,
      'image_url': imageUrl,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_color': categoryColor,
      'category_icon': categoryIcon,
      'chorale_id': choraleId,
      'chorale_name': choraleName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_downloaded': isDownloaded,
      'local_audio_path': localAudioPath,
      'local_pdf_path': localPdfPath,
      'local_image_path': localImagePath,
    };
  }

  Partition copyWith({
    int? id,
    String? title,
    String? description,
    String? audioPath,
    String? audioUrl,
    String? pdfPath,
    String? pdfUrl,
    String? imagePath,
    String? imageUrl,
    int? categoryId,
    String? categoryName,
    String? categoryColor,
    String? categoryIcon,
    int? choraleId,
    String? choraleName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDownloaded,
    String? localAudioPath,
    String? localPdfPath,
    String? localImagePath,
  }) {
    return Partition(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      audioPath: audioPath ?? this.audioPath,
      audioUrl: audioUrl ?? this.audioUrl,
      pdfPath: pdfPath ?? this.pdfPath,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      choraleId: choraleId ?? this.choraleId,
      choraleName: choraleName ?? this.choraleName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      localPdfPath: localPdfPath ?? this.localPdfPath,
      localImagePath: localImagePath ?? this.localImagePath,
    );
  }

  // Vérifier si la partition a au moins un fichier (audio, PDF ou image)
  bool hasAnyFile() {
    return (audioPath != null) || (pdfPath != null) || (imagePath != null);
  }

  // Vérifier si la partition a un fichier audio
  bool hasAudio() {
    return audioPath != null;
  }

  // Vérifier si la partition a un PDF
  bool hasPdf() {
    return pdfPath != null;
  }

  // Vérifier si la partition a une image
  bool hasImage() {
    return imagePath != null;
  }

  // Obtenir le type de fichier principal
  String getFileType() {
    if (hasAudio()) return 'Audio';
    if (hasPdf()) return 'PDF';
    if (hasImage()) return 'Image';
    return 'Aucun';
  }
}
