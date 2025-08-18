import 'package:dio/dio.dart';
import 'package:flutter_project/services/auth_service.dart';

class Network {
  static final Network _i = Network._();
  factory Network() => _i;
  Network._();

  final AuthService authService = AuthService();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.45.98:8080/api', // ← 서버 도메인/로컬주소로 교체
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  void init() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 요청 직전에 토큰 주입
          final token = await authService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (e, handler) {
          // 에러 로깅, 토큰 만료 시 처리 등 가능
          return handler.next(e);
        },
      ),
    );
  }
}
