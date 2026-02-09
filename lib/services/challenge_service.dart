import 'package:dio/dio.dart';
import 'package:zenopay/core/config.dart';
import 'package:zenopay/services/api_client.dart';
import '../models/challenge_model.dart';

class ChallengeService {
  static const String baseUrl = AppConfig.apiBaseUrl; // ends with /api

  Future<List<Challenge>> getActiveChallenges() async {
    final Dio dio = await ApiClient.instance(baseUrl);

    final res = await dio.get(
      "/challenges",
      queryParameters: {"filter": "active"},
      options: Options(
        headers: {"accept": "application/json"},
      ),
    );

    if (res.statusCode == null || res.statusCode! >= 400) {
      throw Exception("Failed: ${res.statusCode} ${res.data}");
    }

    final data = res.data;

    // backend returns a plain JSON array: [ {...}, {...} ]
    if (data is List) {
      return data
          .map((e) => Challenge.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    // fallback if backend ever wraps: { data: [...] }
    if (data is Map && data["data"] is List) {
      return (data["data"] as List)
          .map((e) => Challenge.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return [];
  }

  Future<List<Challenge>> getChallengesByFrequency(String frequency) async {
    final challenges = await getActiveChallenges();
    return challenges.where((c) => c.frequency == frequency).toList();
  }

  Future<Challenge?> getChallengeById(int id) async {
    final Dio dio = await ApiClient.instance(baseUrl);

    final res = await dio.get("/challenges/$id");

    if (res.statusCode == null || res.statusCode! >= 400) {
      return null;
    }

    final data = res.data;
    if (data is Map) {
      return Challenge.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }
}