import "package:zenopay/core/config.dart";
import "package:zenopay/services/api_client.dart";

class AuthApi {
  // ✅ keep positional arguments (so your UI pages don't change)
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final dio = await ApiClient.instance(AppConfig.apiBaseUrl);

    final res = await dio.post("/auth/register", data: {
      "name": name,
      "email": email,
      "password": password,
      "password_confirmation": password,
    });

    return _asMap(res.data);
  }

  // ✅ keep positional arguments (so your Login.dart stays same)
  Future<Map<String, dynamic>> login(String email, String password) async {
    final dio = await ApiClient.instance(AppConfig.apiBaseUrl);

    final res = await dio.post("/auth/login", data: {
      "email": email,
      "password": password,
    });

    return _asMap(res.data);
  }

  Future<void> logout() async {
    final dio = await ApiClient.instance(AppConfig.apiBaseUrl);
    await dio.post("/auth/logout");
  }

  Future<Map<String, dynamic>> me() async {
    final dio = await ApiClient.instance(AppConfig.apiBaseUrl);
    final res = await dio.get("/auth/me");
    return _asMap(res.data);
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return {"data": data};
  }
}