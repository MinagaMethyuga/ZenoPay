import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

class ApiClient {
  static Dio? _dio;
  static CookieJar? _jar;

  static Future<Dio> instance(String baseUrl) async {
    if (_dio != null) return _dio!;

    _jar = CookieJar(); // in-memory cookie jar

    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: {"accept": "application/json"},
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        validateStatus: (code) => code != null && code >= 200 && code < 500,
      ),
    );

    dio.interceptors.add(CookieManager(_jar!));

    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ));

    _dio = dio;
    return dio;
  }

  static Future<void> clearCookies() async {
    await _jar?.deleteAll();
  }
}