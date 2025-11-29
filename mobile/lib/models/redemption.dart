enum RedemptionStatus {
  pending,
  claimed,
  expired,
}

class Redemption {
  final String id;
  final String userId;
  final String cafeId;
  final int stampsUsed;
  final String rewardDescription;
  final String redemptionCode;
  final bool isClaimed;
  final DateTime createdAt;
  final DateTime? claimedAt;
  final DateTime expiresAt;

  // Joined data
  final String? cafeName;
  final String? cafeLogoUrl;

  Redemption({
    required this.id,
    required this.userId,
    required this.cafeId,
    required this.stampsUsed,
    required this.rewardDescription,
    required this.redemptionCode,
    this.isClaimed = false,
    required this.createdAt,
    this.claimedAt,
    required this.expiresAt,
    this.cafeName,
    this.cafeLogoUrl,
  });

  factory Redemption.fromJson(Map<String, dynamic> json) {
    return Redemption(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cafeId: json['cafe_id'] as String,
      stampsUsed: json['stamps_used'] as int,
      rewardDescription: json['reward_description'] as String,
      redemptionCode: json['redemption_code'] as String,
      isClaimed: json['is_claimed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      claimedAt: json['claimed_at'] != null
          ? DateTime.parse(json['claimed_at'] as String)
          : null,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      cafeName: json['cafe_name'] as String?,
      cafeLogoUrl: json['cafe_logo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'cafe_id': cafeId,
      'stamps_used': stampsUsed,
      'reward_description': rewardDescription,
      'redemption_code': redemptionCode,
      'is_claimed': isClaimed,
      'created_at': createdAt.toIso8601String(),
      'claimed_at': claimedAt?.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  RedemptionStatus get status {
    if (isClaimed) return RedemptionStatus.claimed;
    if (DateTime.now().isAfter(expiresAt)) return RedemptionStatus.expired;
    return RedemptionStatus.pending;
  }

  bool get isValid => status == RedemptionStatus.pending;

  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  String get timeRemainingText {
    if (!isValid) return 'Expired';
    final remaining = timeRemaining;
    if (remaining.inMinutes < 1) return 'Less than 1 min';
    if (remaining.inMinutes < 60) return '${remaining.inMinutes} min';
    return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
  }
}
