import "package:zenopay/core/config.dart";
import "package:zenopay/services/api_client.dart";
import "package:zenopay/models/challenge_model.dart";

class ChallengeService {
  // ✅ this is what your ChallengesPage expects
  Future<List<Challenge>> getActiveChallenges() async {
    final dio = await ApiClient.instance(AppConfig.apiBaseUrl);

    // use the endpoint that usually returns your challenges list
    final res = await dio.get("/challenges");

    final data = res.data;

    // supports either: [ ... ] or { data: [ ... ] }
    final list = (data is List)
        ? data
        : (data is Map && data["data"] is List)
        ? data["data"]
        : [];

    return List<Challenge>.from(
      (list as List).map((x) => Challenge.fromJson(Map<String, dynamic>.from(x))),
    );
  }
}