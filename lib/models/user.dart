class User {
  int? id;
  String? name;
  String? email;
  String? phone;
  String? voicePart;
  String? role;
  String? status;
  Map<String, dynamic>? chorale;

  User({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.voicePart,
    this.role,
    this.status,
    this.chorale,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    phone = json['phone'];
    voicePart = json['voice_part'];
    role = json['role'];
    status = json['status'];
    chorale = json['chorale'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['email'] = this.email;
    data['phone'] = this.phone;
    data['voice_part'] = this.voicePart;
    data['role'] = this.role;
    data['status'] = this.status;
    data['chorale'] = this.chorale;

    return data;
  }
}

// Garder l'ancien modèle pour compatibilité
class Collector {
  int? id;
  String? name;
  String? phone;

  Collector({
    this.id,
    this.name,
    this.phone,
  });

  Collector.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    phone = json['phone'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['phone'] = this.phone;

    return data;
  }
}
