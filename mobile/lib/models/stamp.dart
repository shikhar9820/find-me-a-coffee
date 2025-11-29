class Stamp {
  final String id;
  final String userId;
  final String cafeId;
  final DateTime stampedAt;

  // Joined data
  final String? cafeName;

  Stamp({
    required this.id,
    required this.userId,
    required this.cafeId,
    required this.stampedAt,
    this.cafeName,
  });

  factory Stamp.fromJson(Map<String, dynamic> json) {
    return Stamp(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cafeId: json['cafe_id'] as String,
      stampedAt: DateTime.parse(json['stamped_at'] as String),
      cafeName: json['cafe_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'cafe_id': cafeId,
      'stamped_at': stampedAt.toIso8601String(),
    };
  }
}

class StampSummary {
  final String cafeId;
  final String cafeName;
  final String? cafeLogoUrl;
  final int stampCount;
  final int stampsRequired;
  final String rewardDescription;
  final DateTime? lastStampedAt;

  StampSummary({
    required this.cafeId,
    required this.cafeName,
    this.cafeLogoUrl,
    required this.stampCount,
    required this.stampsRequired,
    required this.rewardDescription,
    this.lastStampedAt,
  });

  factory StampSummary.fromJson(Map<String, dynamic> json) {
    return StampSummary(
      cafeId: json['cafe_id'] as String,
      cafeName: json['cafe_name'] as String,
      cafeLogoUrl: json['cafe_logo_url'] as String?,
      stampCount: json['stamp_count'] as int,
      stampsRequired: json['stamps_required'] as int,
      rewardDescription: json['reward_description'] as String? ?? 'Free coffee',
      lastStampedAt: json['last_stamped_at'] != null
          ? DateTime.parse(json['last_stamped_at'] as String)
          : null,
    );
  }

  int get stampsRemaining => stampsRequired - stampCount;
  double get progress => stampCount / stampsRequired;
  bool get canRedeem => stampCount >= stampsRequired;
}
