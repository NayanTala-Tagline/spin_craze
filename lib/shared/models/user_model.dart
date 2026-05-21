import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final String? email;
  final String? referredBy;
  final String deviceId;
  final double xp;
  final double level;
  final double coin;
  final DateTime createdAt;
  final bool isGuest;
  final String? photoUrl;
  final bool hasRated;
  final int checkInStreak;
  final DateTime? lastCheckInDate;
  final int totalClaimDays;

  const UserModel({
    required this.userId,
    required this.name,
    required this.deviceId,
    required this.xp,
    required this.level,
    required this.coin,
    required this.createdAt,
    required this.isGuest,
    this.email,
    this.referredBy,
    this.photoUrl,
    this.hasRated = false,
    this.checkInStreak = 0,
    this.lastCheckInDate,
    this.totalClaimDays = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      referredBy: map['referred_by'] as String?,
      deviceId: map['device_id'] as String,
      xp: (map['xp'] as num).toDouble(),
      level: (map['level'] as num).toDouble(),
      coin: (map['coin'] as num).toDouble(),
      createdAt: map['created_at'] is Timestamp
          ? (map['created_at'] as Timestamp).toDate()
          : DateTime.parse(map['created_at'] as String),
      isGuest: map['is_guest'] as bool? ?? false,
      photoUrl: map['photo_url'] as String?,
      hasRated: map['has_rated'] as bool? ?? false,
      checkInStreak: (map['check_in_streak'] as int?) ?? 0,
      lastCheckInDate: map['last_check_in_date'] is Timestamp
          ? (map['last_check_in_date'] as Timestamp).toDate()
          : map['last_check_in_date'] != null
              ? DateTime.parse(map['last_check_in_date'] as String)
              : null,
      totalClaimDays: (map['total_claim_days'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'referred_by': referredBy,
      'device_id': deviceId,
      'xp': xp,
      'level': level,
      'coin': coin,
      'created_at': Timestamp.fromDate(createdAt),
      'is_guest': isGuest,
      'photo_url': photoUrl,
      'has_rated': hasRated,
      'check_in_streak': checkInStreak,
      'last_check_in_date':
          lastCheckInDate != null ? Timestamp.fromDate(lastCheckInDate!) : null,
      'total_claim_days': totalClaimDays,
    };
  }

  /// Map without Firestore-specific types, safe for local Hive storage.
  Map<String, dynamic> toLocalMap() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'referred_by': referredBy,
      'device_id': deviceId,
      'xp': xp,
      'level': level,
      'coin': coin,
      'created_at': createdAt.toIso8601String(),
      'is_guest': isGuest,
      'photo_url': photoUrl,
      'has_rated': hasRated,
      'check_in_streak': checkInStreak,
      'last_check_in_date': lastCheckInDate?.toIso8601String(),
      'total_claim_days': totalClaimDays,
    };
  }

  factory UserModel.fromLocalMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['user_id'] as String,
      name: map['name'] as String,
      email: map['email'] as String?,
      referredBy: map['referred_by'] as String?,
      deviceId: map['device_id'] as String,
      xp: (map['xp'] as num).toDouble(),
      level: (map['level'] as num).toDouble(),
      coin: (map['coin'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      isGuest: map['is_guest'] as bool? ?? false,
      photoUrl: map['photo_url'] as String?,
      hasRated: map['has_rated'] as bool? ?? false,
      checkInStreak: (map['check_in_streak'] as int?) ?? 0,
      lastCheckInDate: map['last_check_in_date'] != null
          ? DateTime.parse(map['last_check_in_date'] as String)
          : null,
      totalClaimDays: (map['total_claim_days'] as int?) ?? 0,
    );
  }

  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? referredBy,
    String? deviceId,
    double? xp,
    double? level,
    double? coin,
    DateTime? createdAt,
    bool? isGuest,
    String? photoUrl,
    bool? hasRated,
    int? checkInStreak,
    DateTime? lastCheckInDate,
    bool clearLastCheckInDate = false,
    int? totalClaimDays,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      referredBy: referredBy ?? this.referredBy,
      deviceId: deviceId ?? this.deviceId,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      coin: coin ?? this.coin,
      createdAt: createdAt ?? this.createdAt,
      isGuest: isGuest ?? this.isGuest,
      photoUrl: photoUrl ?? this.photoUrl,
      hasRated: hasRated ?? this.hasRated,
      checkInStreak: checkInStreak ?? this.checkInStreak,
      lastCheckInDate:
          clearLastCheckInDate ? null : (lastCheckInDate ?? this.lastCheckInDate),
      totalClaimDays: totalClaimDays ?? this.totalClaimDays,
    );
  }
}
