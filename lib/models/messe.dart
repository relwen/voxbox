import 'package:voxbox/models/messe_section.dart';

class Messe {
  final int id;
  final String nom;
  final String? description;
  final String couleur;
  final String icone;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<MesseSection>? sections;

  Messe({
    required this.id,
    required this.nom,
    this.description,
    required this.couleur,
    required this.icone,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.sections,
  });

  factory Messe.fromJson(Map<String, dynamic> json) {
    return Messe(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? 'Messe sans nom',
      description: json['description'],
      couleur: json['couleur'] ?? '#2196F3',
      icone: json['icone'] ?? 'church',
      active: json['active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      sections: json['sections'] != null
          ? (json['sections'] as List)
              .map((section) => MesseSection.fromJson(section))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'couleur': couleur,
      'icone': icone,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sections': sections?.map((section) => section.toJson()).toList(),
    };
  }

  Messe copyWith({
    int? id,
    String? nom,
    String? description,
    String? couleur,
    String? icone,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<MesseSection>? sections,
  }) {
    return Messe(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      couleur: couleur ?? this.couleur,
      icone: icone ?? this.icone,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sections: sections ?? this.sections,
    );
  }
}
