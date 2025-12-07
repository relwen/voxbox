import 'package:voxbox/models/chant_de_messe.dart';

class ChantSection {
  final int id;
  final String nom;
  final String? description;
  final String couleur;
  final String icone;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChantDeMesse>? chants;
  final int chantsCount;

  ChantSection({
    required this.id,
    required this.nom,
    this.description,
    required this.couleur,
    required this.icone,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.chants,
    this.chantsCount = 0,
  });

  factory ChantSection.fromJson(Map<String, dynamic> json) {
    return ChantSection(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? 'Section sans nom',
      description: json['description'],
      couleur: json['couleur'] ?? '#4CAF50',
      icone: json['icone'] ?? 'music_note',
      active: json['active'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      chants: json['chants'] != null
          ? (json['chants'] as List)
              .map((chant) => ChantDeMesse.fromJson(chant))
              .toList()
          : null,
      chantsCount: json['chants_count'] ?? 0,
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
      'chants': chants?.map((chant) => chant.toJson()).toList(),
      'chants_count': chantsCount,
    };
  }

  ChantSection copyWith({
    int? id,
    String? nom,
    String? description,
    String? couleur,
    String? icone,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChantDeMesse>? chants,
    int? chantsCount,
  }) {
    return ChantSection(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      couleur: couleur ?? this.couleur,
      icone: icone ?? this.icone,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chants: chants ?? this.chants,
      chantsCount: chantsCount ?? this.chantsCount,
    );
  }
}

