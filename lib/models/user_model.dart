/// Profile payload from API (user_profiles): xp, level (int 1/2/3).
class UserProfile {
  final int xp;
  final int level; // 1=Beginner, 2=Intermediate, 3=Pro

  const UserProfile({
    required this.xp,
    required this.level,
  });

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      xp: _asInt(json["xp"], 0),
      level: _asInt(json["level"], 1),
    );
  }

  /// Map profile.level (int) to display name.
  static String levelIntToName(int level) {
    switch (level) {
      case 1:
        return "Beginner";
      case 2:
        return "Intermediate";
      case 3:
        return "Pro";
      default:
        return "Beginner";
    }
  }
}

/// User model: prefers root gamification fields, fallback to profile.
/// API (UserResource) provides: total_xp, level (string), xp_to_next_level.
/// Nested user.profile provides: xp, level (int 1/2/3).
class ZenoUser {
  final int id;
  final String name;
  final String? email;
  final int totalXp;
  final String levelName; // Beginner | Intermediate | Pro
  final int xpToNextLevel;
  final UserProfile? profile;

  const ZenoUser({
    required this.id,
    required this.name,
    required this.email,
    required this.totalXp,
    required this.levelName,
    required this.xpToNextLevel,
    this.profile,
  });

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static String _asString(dynamic value, [String fallback = ""]) {
    if (value == null) return fallback;
    final s = value.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  factory ZenoUser.fromJson(Map<String, dynamic> json) {
    // Parse nested profile safely
    UserProfile? profile;
    final rawProfile = json["profile"];
    if (rawProfile is Map<String, dynamic>) {
      profile = UserProfile.fromJson(rawProfile);
    } else if (rawProfile is Map) {
      profile = UserProfile.fromJson(rawProfile.cast<String, dynamic>());
    }

    // Prefer root gamification fields; fallback to profile
    final rootTotalXp = _asInt(json["total_xp"], -1);
    final totalXp = rootTotalXp >= 0
        ? rootTotalXp
        : (profile?.xp ?? 0);

    final rootLevel = _asString(json["level"]);
    final levelName = rootLevel.isNotEmpty
        ? rootLevel
        : UserProfile.levelIntToName(profile?.level ?? 1);

    final xpToNextLevel = _asInt(json["xp_to_next_level"], 0);

    return ZenoUser(
      id: _asInt(json["id"], 0),
      name: _asString(json["name"], "Student"),
      email: json["email"]?.toString(),
      totalXp: totalXp,
      levelName: levelName,
      xpToNextLevel: xpToNextLevel,
      profile: profile,
    );
  }

  ZenoUser copyWith({
    int? id,
    String? name,
    String? email,
    int? totalXp,
    String? levelName,
    int? xpToNextLevel,
    UserProfile? profile,
  }) {
    return ZenoUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      totalXp: totalXp ?? this.totalXp,
      levelName: levelName ?? this.levelName,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      profile: profile ?? this.profile,
    );
  }
}
