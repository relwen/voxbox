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
