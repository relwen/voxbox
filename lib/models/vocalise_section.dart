class VocaliseSection {
  final int id;
  final String nom;
  final String? description;
  final String type; // 'dossier' ou 'section'
  final String couleur;
  final String icone;
  final int vocalisesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  VocaliseSection({
    required this.id,
    required this.nom,
    this.description,
    required this.type,
    required this.couleur,
    required this.icone,
    required this.vocalisesCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VocaliseSection.fromJson(Map<String, dynamic> json) {
    return VocaliseSection(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      type: json['type'] ?? 'section',
      couleur: json['couleur'] ?? '#9C27B0',
      icone: json['icone'] ?? 'music_note',
      vocalisesCount: json['vocalises_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'type': type,
      'couleur': couleur,
      'icone': icone,
      'vocalises_count': vocalisesCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
