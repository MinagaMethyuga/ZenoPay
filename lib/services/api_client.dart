import "dart:io";
import "package:dio/dio.dart";
import "package:cookie_jar/cookie_jar.dart";
import "package:dio_cookie_manager/dio_cookie_manager.dart";
import "package:path_provider/path_provider.dart";

class ApiClient {
  static Dio? _dio;
  static PersistCookieJar? _cookieJar;
  static String? _baseUrl;

  // ✅ Backward-compatible: ApiClient.instance(AppConfig.apiBaseUrl)
  static Future<Dio> instance(String baseUrl) async {
    if (_dio != null && _baseUrl == baseUrl) return _dio!;
    _baseUrl = baseUrl;

    if (_cookieJar == null) {
      final dir = await getApplicationDocumentsDirectory();
      final cookiePath = "${dir.path}${Platform.pathSeparator}cookies";
      _cookieJar = PersistCookieJar(
        ignoreExpires: true,
        storage: FileStorage(cookiePath),
      );
    }

    final d = Dio(BaseOptions(
      baseUrl: baseUrl, // ex: https://xxxx.ngrok.../api
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
    ));

    d.interceptors.add(CookieManager(_cookieJar!));
    _dio = d;
    return _dio!;
  }
}