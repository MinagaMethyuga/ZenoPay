import 'package:flutter/material.dart';

class Challenge {
  final int id;
  final String name;
  final String description;
  final String difficulty;
  final String category;
  final String frequency;
  final int xpReward;
  final bool unlockBadge;

  // ✅ NEW: badge image url from backend (Challenge::$appends)
  final String? badgeImageUrl;

  final String? icon;
  final String? targetType;
  final String? targetValue;
  final String? duration;
  final String type;
  final bool isActive;
  final Map<String, dynamic>? winConditions;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.category,
    required this.frequency,
    required this.xpReward,
    required this.unlockBadge,
    this.badgeImageUrl, // ✅ NEW
    this.icon,
    this.targetType,
    this.targetValue,
    this.duration,
    required this.type,
    required this.isActive,
    this.winConditions,
    this.startsAt,
    this.endsAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as String,
      category: json['category'] as String,
      frequency: json['frequency'] as String,
      xpReward: json['xp_reward'] as int,
      unlockBadge: (json['unlock_badge'] == 1 || json['unlock_badge'] == true),

      // ✅ reads the appended field coming from Laravel
      badgeImageUrl: json['badge_image_url'] as String?,

      icon: json['icon'] as String?,
      targetType: json['target_type'] as String?,
      targetValue: json['target_value'] as String?,
      duration: json['duration'] as String?,
      type: json['type'] as String,
      isActive: (json['is_active'] == 1 || json['is_active'] == true),
      winConditions: json['win_conditions'] as Map<String, dynamic>?,
      startsAt: json['starts_at'] != null ? DateTime.parse(json['starts_at']) : null,
      endsAt: json['ends_at'] != null ? DateTime.parse(json['ends_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  IconData getCategoryIcon() {
    switch (category) {
      case 'Income':
        return Icons.attach_money;
      case 'Savings':
        return Icons.savings;
      case 'Budgeting':
        return Icons.account_balance_wallet;
      case 'Investing':
        return Icons.trending_up;
      case 'Learning':
        return Icons.school;
      default:
        return Icons.star;
    }
  }

  Color getDifficultyColor() {
    switch (difficulty) {
      case 'Easy':
        return const Color(0xFF10B981);
      case 'Medium':
        return const Color(0xFFFBBF24);
      case 'Hard':
        return const Color(0xFFEF4444);
      case 'Expert':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color getCategoryColor() {
    switch (category) {
      case 'Income':
        return const Color(0xFF10B981);
      case 'Savings':
        return const Color(0xFF14B8A6);
      case 'Budgeting':
        return const Color(0xFF8B5CF6);
      case 'Investing':
        return const Color(0xFF6366F1);
      case 'Learning':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color getCategoryBgColor() {
    return getCategoryColor().withValues(alpha: 0.1);
  }

  /// Parse target_value from API (may be numeric string or number) to int.
  static int? parseTargetValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      final n = int.tryParse(value.trim());
      if (n != null) return n;
      final d = double.tryParse(value.trim());
      return d?.round();
    }
    if (value is double) return value.round();
    return null;
  }
}

/// Status for a challenge accepted by the user (from /api/my-challenges).
class MyChallengeStatus {
  final String status; // 'active' | 'completed'
  final int progress;
  final int? targetValue;

  MyChallengeStatus({
    required this.status,
    required this.progress,
    this.targetValue,
  });
}

/// One item from GET /api/my-challenges (user_challenge + challenge).
class UserChallengeItem {
  final int userChallengeId;
  final String status;
  final int progress;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final Challenge challenge;

  UserChallengeItem({
    required this.userChallengeId,
    required this.status,
    required this.progress,
    this.acceptedAt,
    this.completedAt,
    required this.challenge,
  });

  static UserChallengeItem fromJson(Map<String, dynamic> json) {
    final uc = json['user_challenge'] as Map<String, dynamic>? ?? {};
    final ch = json['challenge'] as Map<String, dynamic>? ?? {};
    return UserChallengeItem(
      userChallengeId: uc['id'] as int? ?? 0,
      status: uc['status'] as String? ?? 'active',
      progress: (uc['progress'] is int) ? uc['progress'] as int : int.tryParse(uc['progress']?.toString() ?? '0') ?? 0,
      acceptedAt: uc['accepted_at'] != null ? DateTime.tryParse(uc['accepted_at'].toString()) : null,
      completedAt: uc['completed_at'] != null ? DateTime.tryParse(uc['completed_at'].toString()) : null,
      challenge: Challenge.fromJson(Map<String, dynamic>.from(ch)),
    );
  }

  MyChallengeStatus toMyChallengeStatus() {
    return MyChallengeStatus(
      status: status,
      progress: progress,
      targetValue: Challenge.parseTargetValue(challenge.targetValue),
    );
  }
}