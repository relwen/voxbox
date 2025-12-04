import 'package:voxbox/models/creation_item.dart';

class CreationFolder {
  final String id;
  final String name;
  final String? description;
  final String? color; // Couleur du dossier
  final String? icon; // Icône du dossier
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CreationItem> items; // Éléments dans le dossier

  CreationFolder({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory CreationFolder.fromJson(Map<String, dynamic> json) {
    return CreationFolder(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Nouveau Dossier',
      description: json['description'],
      color: json['color'] ?? '#2196F3',
      icon: json['icon'] ?? 'folder',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => CreationItem.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  CreationFolder copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CreationItem>? items,
  }) {
    return CreationFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  // Getters pour les statistiques
  int get totalItems => items.length;
  int get audioCount => items.where((item) => item.type == CreationType.audio).length;
  int get imageCount => items.where((item) => item.type == CreationType.image).length;
  int get textCount => items.where((item) => item.type == CreationType.text).length;

  @override
  String toString() {
    return 'CreationFolder(id: $id, name: $name, items: ${items.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreationFolder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
