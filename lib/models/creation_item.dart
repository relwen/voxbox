enum CreationType {
  audio,
  image,
  text,
}

class CreationItem {
  final String id;
  final String name;
  final String? description;
  final CreationType type;
  final String? content; // Pour le texte
  final String? filePath; // Pour les fichiers (audio, image)
  final String? thumbnailPath; // Miniature pour les images
  final int? duration; // Durée en secondes pour l'audio
  final int? fileSize; // Taille du fichier en bytes
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata; // Métadonnées supplémentaires

  CreationItem({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.content,
    this.filePath,
    this.thumbnailPath,
    this.duration,
    this.fileSize,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory CreationItem.fromJson(Map<String, dynamic> json) {
    return CreationItem(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Nouvel Élément',
      description: json['description'],
      type: CreationType.values.firstWhere(
        (e) => e.toString() == 'CreationType.${json['type']}',
        orElse: () => CreationType.text,
      ),
      content: json['content'],
      filePath: json['file_path'],
      thumbnailPath: json['thumbnail_path'],
      duration: json['duration'],
      fileSize: json['file_size'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'content': content,
      'file_path': filePath,
      'thumbnail_path': thumbnailPath,
      'duration': duration,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  CreationItem copyWith({
    String? id,
    String? name,
    String? description,
    CreationType? type,
    String? content,
    String? filePath,
    String? thumbnailPath,
    int? duration,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return CreationItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      content: content ?? this.content,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Getters pour l'affichage
  String get typeDisplayName {
    switch (type) {
      case CreationType.audio:
        return 'Audio';
      case CreationType.image:
        return 'Image';
      case CreationType.text:
        return 'Texte';
    }
  }

  String get typeIcon {
    switch (type) {
      case CreationType.audio:
        return '🎵';
      case CreationType.image:
        return '🖼️';
      case CreationType.text:
        return '📝';
    }
  }

  String get formattedDuration {
    if (duration == null) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedFileSize {
    if (fileSize == null) return '';
    if (fileSize! < 1024) {
      return '${fileSize} B';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  String toString() {
    return 'CreationItem(id: $id, name: $name, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreationItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
