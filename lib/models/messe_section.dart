class MesseSection {
  int? id;
  String? name;
  String? writtenPartition;
  String? musicalPartition;
  String? audioFile;
  String? voicePart;
  int? messeId;
  String? createdAt;
  String? updatedAt;

  MesseSection({
    this.id,
    this.name,
    this.writtenPartition,
    this.musicalPartition,
    this.audioFile,
    this.voicePart,
    this.messeId,
    this.createdAt,
    this.updatedAt,
  });

  MesseSection.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    writtenPartition = json['written_partition'];
    musicalPartition = json['musical_partition'];
    audioFile = json['audio_file'];
    voicePart = json['voice_part'];
    messeId = json['messe_id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['written_partition'] = this.writtenPartition;
    data['musical_partition'] = this.musicalPartition;
    data['audio_file'] = this.audioFile;
    data['voice_part'] = this.voicePart;
    data['messe_id'] = this.messeId;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;

    return data;
  }
} 