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
  });

  factory Vocalise.fromJson(Map<String, dynamic> json) {
    return Vocalise(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      voicePart: json['voice_part'],
      audioPath: json['audio_path'],
      audioUrl: json['audio_url'],
      choraleId: json['chorale_id'],
      choraleName: json['chorale']?['name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isDownloaded: json['is_downloaded'] ?? false,
      localAudioPath: json['local_audio_path'],
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
