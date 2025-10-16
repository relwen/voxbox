class Chorale {
  final int id;
  final String nom;
  final String? description;
  final String? ville;
  final String? pays;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chorale({
    required this.id,
    required this.nom,
    this.description,
    this.ville,
    this.pays,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chorale.fromJson(Map<String, dynamic> json) {
    return Chorale(
      id: json['id'],
      nom: json['name'] ?? json['nom'], // Support des deux formats
      description: json['description'],
      ville: json['location'] ?? json['ville'], // Support des deux formats
      pays: json['pays'],
      active: json['active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': nom, // Utiliser 'name' pour correspondre au backend
      'description': description,
      'location': ville, // Utiliser 'location' pour correspondre au backend
      'pays': pays,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return nom;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chorale && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
