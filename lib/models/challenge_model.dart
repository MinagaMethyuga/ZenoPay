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

  // Get icon for category
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

  // Get color for difficulty
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

  // Get color for category
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

  // Get background color for category
  Color getCategoryBgColor() {
    return getCategoryColor().withValues(alpha: 0.1);
  }
}