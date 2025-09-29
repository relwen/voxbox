import 'package:voxbox/models/messe_section.dart';

class Messe {
  int? id;
  String? title;
  String? description;
  String? date;
  String? voicePart; // Pupitre (Basse, Ténor, Soprano, etc.)
  String? status;
  String? createdAt;
  String? updatedAt;
  List<MesseSection>? sections;

  Messe({
    this.id,
    this.title,
    this.description,
    this.date,
    this.voicePart,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.sections,
  });

  Messe.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    date = json['date'];
    voicePart = json['voice_part'];
    status = json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    
    if (json['sections'] != null) {
      sections = (json['sections'] as List)
          .map((section) => MesseSection.fromJson(section))
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['description'] = this.description;
    data['date'] = this.date;
    data['voice_part'] = this.voicePart;
    data['status'] = this.status;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    
    if (sections != null) {
      data['sections'] = sections!.map((section) => section.toJson()).toList();
    }

    return data;
  }
} 