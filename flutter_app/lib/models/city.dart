class City {
  final String id;
  final String name;
  final String urdu;
  final String country;
  final double lat;
  final double lng;
  final double tz;

  const City({
    required this.id,
    required this.name,
    required this.urdu,
    required this.country,
    required this.lat,
    required this.lng,
    required this.tz,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'urdu': urdu,
    'country': country,
    'lat': lat,
    'lng': lng,
    'tz': tz,
  };

  factory City.fromJson(Map<String, dynamic> json) => City(
    id: json['id'] as String? ?? 'delhi',
    name: json['name'] as String? ?? 'Delhi / New Delhi',
    urdu: json['urdu'] as String? ?? 'دہلی',
    country: json['country'] as String? ?? 'India',
    lat: (json['lat'] as num?)?.toDouble() ?? 28.6139,
    lng: (json['lng'] as num?)?.toDouble() ?? 77.2090,
    tz: (json['tz'] as num?)?.toDouble() ?? 5.5,
  );
}

