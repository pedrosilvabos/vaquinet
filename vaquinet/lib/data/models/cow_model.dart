class CowModel {
  final String? id; // UUID, nullable when creating
  final String name;
  final double temperature;
  final String location;
  final double? latitude;
  final double? longitude;

  CowModel({
    this.id,
    required this.name,
    required this.temperature,
    required this.location,
    this.latitude,
    this.longitude,
  });

  factory CowModel.fromJson(Map<String, dynamic> json) => CowModel(
        id: json['id'],
        name: json['name'],
        temperature: (json['temperature'] as num).toDouble(),
        location: json['location'],
        latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
        longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      );

  Map<String, dynamic> toJson() {
    final map = {
      'name': name,
      'temperature': temperature,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
    };

    return map;
  }

  CowModel copyWith({
    String? id,
    String? name,
    double? temperature,
    String? location,
    double? latitude,
    double? longitude,
  }) {
    return CowModel(
      id: id ?? this.id,
      name: name ?? this.name,
      temperature: temperature ?? this.temperature,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
