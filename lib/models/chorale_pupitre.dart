class ChoralePupitre {
  final int id;
  final int choraleId;
  final String nom;
  final String? description;
  final String? color;
  final String? icon;
  final int order;
  final bool isDefault;

  ChoralePupitre({
    required this.id,
    required this.choraleId,
    required this.nom,
    this.description,
    this.color,
    this.icon,
    required this.order,
    required this.isDefault,
  });

  factory ChoralePupitre.fromJson(Map<String, dynamic> json) {
    return ChoralePupitre(
      id: json['id'],
      choraleId: json['chorale_id'],
      nom: json['nom'],
      description: json['description'],
      color: json['color'],
      icon: json['icon'],
      order: json['order'] ?? 0,
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chorale_id': choraleId,
      'nom': nom,
      'description': description,
      'color': color,
      'icon': icon,
      'order': order,
      'is_default': isDefault,
    };
  }

  @override
  String toString() {
    return nom;
  }
}

