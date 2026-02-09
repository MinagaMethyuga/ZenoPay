import "package:zenopay/core/config.dart";
import "package:zenopay/services/api_client.dart";
import "package:zenopay/models/challenge_model.dart";

class ChallengeService {
  String? _toAbsoluteUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith("http://") || url.startsWith("https://")) return url;

    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r"/+$"), "");
    final path = url.startsWith("/") ? url : "/$url";
    return "$base$path";
  }

  Future<List<Challenge>> getActiveChallenges() async {
    final dio = await ApiClient.instance(AppConfig.apiBaseUrl);
    final res = await dio.get("/challenges");

    final data = res.data;

    final list = (data is List)
        ? data
        : (data is Map && data["data"] is List)
        ? data["data"]
        : [];

    final challenges = List<Challenge>.from(
      (list as List).map((x) => Challenge.fromJson(Map<String, dynamic>.from(x))),
    );

    // ✅ normalize badge_image_url to absolute
    return challenges.map((c) {
      return Challenge(
        id: c.id,
        name: c.name,
        description: c.description,
        difficulty: c.difficulty,
        category: c.category,
        frequency: c.frequency,
        xpReward: c.xpReward,
        unlockBadge: c.unlockBadge,
        badgeImageUrl: _toAbsoluteUrl(c.badgeImageUrl),
        icon: c.icon,
        targetType: c.targetType,
        targetValue: c.targetValue,
        duration: c.duration,
        type: c.type,
        isActive: c.isActive,
        winConditions: c.winConditions,
        startsAt: c.startsAt,
        endsAt: c.endsAt,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      );
    }).toList();
  }

  /// User's accepted challenges: GET /api/my-challenges?status=active|completed
  Future<List<UserChallengeItem>> getMyChallenges(String status) async {
    final dio = await ApiClient.instance(AppConfig.apiBaseUrl);
    final res = await dio.get("/my-challenges", queryParameters: {"status": status});

    final data = res.data;
    final list = (data is List)
        ? data
        : (data is Map && data["data"] is List)
            ? data["data"]
            : [];

    return (list as List)
        .map((x) => UserChallengeItem.fromJson(Map<String, dynamic>.from(x as Map)))
        .toList();
  }

  // ✅ Accept a quest: POST /api/challenges/{id}/accept
  Future<void> acceptQuest(int challengeId) async {
    final dio = await ApiClient.instance(AppConfig.apiBaseUrl);
    await dio.post("/challenges/$challengeId/accept");
  }
}