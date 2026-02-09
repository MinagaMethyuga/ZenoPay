import 'package:dio/dio.dart';
import 'package:zenopay/core/config.dart';
import 'package:zenopay/services/api_client.dart';

class AuthApi {
  static const String baseUrl = AppConfig.apiBaseUrl; // ends with /api

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final Dio dio = await ApiClient.instance(baseUrl);

    final res = await dio.post(
      "/auth/register",
      data: {"name": name, "email": email, "password": password},
    );

    if (res.statusCode == null || res.statusCode! >= 400) {
      throw Exception("Register failed: ${res.statusCode} ${res.data}");
    }
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final Dio dio = await ApiClient.instance(baseUrl);

    final res = await dio.post(
      "/auth/login",
      data: {"email": email, "password": password},
    );

    if (res.statusCode == null || res.statusCode! >= 400) {
      throw Exception("Login failed: ${res.statusCode} ${res.data}");
    }
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> me() async {
    final Dio dio = await ApiClient.instance(baseUrl);

    final res = await dio.get("/auth/me");

    if (res.statusCode == null || res.statusCode! >= 400) {
      throw Exception("Me failed: ${res.statusCode} ${res.data}");
    }
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> logout() async {
    final Dio dio = await ApiClient.instance(baseUrl);
    try {
      await dio.post("/auth/logout");
    } catch (_) {}
    await ApiClient.clearCookies();
  }
}