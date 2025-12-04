class User {
  int? id;
  String? name;
  String? email;
  String? phone;
  String? voicePart;
  String? role;
  String? status;
  Map<String, dynamic>? chorale;
  int? choraleId;
  bool? profileComplete;
  bool? profileIncomplete;

  User({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.voicePart,
    this.role,
    this.status,
    this.chorale,
    this.choraleId,
    this.profileComplete,
    this.profileIncomplete,
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
    choraleId = json['chorale_id'];
    profileComplete = json['profile_complete'];
    profileIncomplete = json['profile_incomplete'];
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
    data['chorale_id'] = this.choraleId;
    data['profile_complete'] = this.profileComplete;
    data['profile_incomplete'] = this.profileIncomplete;

    return data;
  }

  // Vérifier si le profil est incomplet (sans email - email n'est plus requis)
  bool isProfileIncomplete() {
    return name == null || 
           name!.isEmpty || 
           voicePart == null || 
           voicePart!.isEmpty ||
           choraleId == null;
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
