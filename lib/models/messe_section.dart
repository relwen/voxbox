import 'package:voxbox/models/chant_de_messe.dart';

class MesseSection {
  final int id;
  final int messeId;
  final String nom;
  final String? description;
  final int ordre;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChantDeMesse>? chants;

  MesseSection({
    required this.id,
    required this.messeId,
    required this.nom,
    this.description,
    required this.ordre,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.chants,
  });

  factory MesseSection.fromJson(Map<String, dynamic> json) {
    return MesseSection(
      id: json['id'],
      messeId: json['messe_id'],
      nom: json['nom'],
      description: json['description'],
      ordre: json['ordre'] ?? 0,
      active: json['active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      chants: json['chants'] != null
          ? (json['chants'] as List)
              .map((chant) => ChantDeMesse.fromJson(chant))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messe_id': messeId,
      'nom': nom,
      'description': description,
      'ordre': ordre,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'chants': chants?.map((chant) => chant.toJson()).toList(),
    };
  }

  MesseSection copyWith({
    int? id,
    int? messeId,
    String? nom,
    String? description,
    int? ordre,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChantDeMesse>? chants,
  }) {
    return MesseSection(
      id: id ?? this.id,
      messeId: messeId ?? this.messeId,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      ordre: ordre ?? this.ordre,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chants: chants ?? this.chants,
    );
  }
}
