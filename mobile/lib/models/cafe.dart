class Cafe {
  final String id;
  final String name;
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? logoUrl;
  final String? nfcTagId;
  final String? qrCodeUrl;
  final int stampsRequired;
  final String? rewardDescription;
  final bool isActive;
  final DateTime createdAt;

  // Computed for user context
  final int? userStampCount;
  final double? distanceKm;

  Cafe({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.logoUrl,
    this.nfcTagId,
    this.qrCodeUrl,
    this.stampsRequired = 10,
    this.rewardDescription,
    this.isActive = true,
    required this.createdAt,
    this.userStampCount,
    this.distanceKm,
  });

  factory Cafe.fromJson(Map<String, dynamic> json) {
    return Cafe(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      logoUrl: json['logo_url'] as String?,
      nfcTagId: json['nfc_tag_id'] as String?,
      qrCodeUrl: json['qr_code_url'] as String?,
      stampsRequired: json['stamps_required'] as int? ?? 10,
      rewardDescription: json['reward_description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      userStampCount: json['user_stamp_count'] as int?,
      distanceKm: json['distance_km'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'logo_url': logoUrl,
      'nfc_tag_id': nfcTagId,
      'qr_code_url': qrCodeUrl,
      'stamps_required': stampsRequired,
      'reward_description': rewardDescription,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  int get stampsRemaining => stampsRequired - (userStampCount ?? 0);
  double get progress => (userStampCount ?? 0) / stampsRequired;
  bool get canRedeem => (userStampCount ?? 0) >= stampsRequired;

  String get displayReward =>
      rewardDescription ?? 'Free coffee after $stampsRequired stamps';
}
