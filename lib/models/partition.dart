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
    return Partition(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      audioPath: json['audio_path'],
      audioUrl: json['audio_path'] != null ? '${AppConstance.baseURL}/storage/${json['audio_path']}' : null,
      pdfPath: json['pdf_path'],
      pdfUrl: json['pdf_path'] != null ? '${AppConstance.baseURL}/storage/${json['pdf_path']}' : null,
      imagePath: json['image_path'],
      imageUrl: json['image_path'] != null ? '${AppConstance.baseURL}/storage/${json['image_path']}' : null,
      categoryId: json['category_id'],
      categoryName: json['category']?['name'] ?? json['category_name'],
      categoryColor: json['category']?['color'] ?? json['category_color'],
      categoryIcon: json['category']?['icon'] ?? json['category_icon'],
      choraleId: json['chorale_id'],
      choraleName: json['chorale']?['name'] ?? json['chorale_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDownloaded: json['is_downloaded'] ?? false,
      localAudioPath: json['local_audio_path'],
      localPdfPath: json['local_pdf_path'],
      localImagePath: json['local_image_path'],
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
