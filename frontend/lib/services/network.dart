import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_project/services/auth_service.dart';

/// Centralized Dio with auto token attach & refresh-on-401.
/// ❗️로그인 성공(파이어베이스 로그인 → /auth/login 교환) 후 Network().init()을 한 번 호출하세요.
class Network {
  static final Network _i = Network._();
  factory Network() => _i;
  Network._();

  final AuthService _auth = AuthService();

  /// Single Dio instance used across the app.
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://8161cbf309f3.ngrok-free.app/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=utf-8',
      },
    ),
  );

  bool _initialized = false;

  /// 동시 401 발생 시 리프레시 1회만 수행하도록 dedupe
  Future<String?>? _refreshing;

  void init() {
    if (_initialized) return;
    _initialized = true;

    // if (kDebugMode) {
    //   dio.interceptors.add(
    //     LogInterceptor(
    //       request: true,
    //       requestHeader: true,
    //       requestBody: true,
    //       responseHeader: false,
    //       responseBody: false,
    //       error: true,
    //     ),
    //   );
    // }

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // /api/auth/** 는 토큰 불요
          final path = options.path; // 예: /auth/login, /board, /report/search
          final isAuth =
              path.startsWith('/auth') || path.contains('/api/auth/');
          if (!isAuth) {
            final token = await _auth.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          if (!_shouldTryRefresh(e)) {
            return handler.next(e);
          }

          try {
            final newToken = await _refreshTokenDedupe();
            if (newToken != null && newToken.isNotEmpty) {
              // 새 토큰으로 원요청 1회 재시도
              final req = e.requestOptions;
              req.headers['Authorization'] = 'Bearer $newToken';
              req.extra['__retried'] = true;

              final response = await dio.fetch(req);
              return handler.resolve(response);
            }
          } catch (err, st) {
            if (kDebugMode) {
              debugPrint('[DIO] refresh failed: $err\n$st');
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  bool _shouldTryRefresh(DioException e) {
    // 401만 대상
    if (e.response?.statusCode != 401) return false;

    final req = e.requestOptions;

    // 이미 재시도 한 요청은 제외 (무한 루프 방지)
    if (req.extra['__retried'] == true) return false;

    // /api/auth/** 에 대한 401은 리프레시 대상 아님
    final path = req.path;
    final isAuth = path.startsWith('/auth') || path.contains('/api/auth/');
    if (isAuth) return false;

    return true;
  }

  Future<String?> _refreshTokenDedupe() async {
    // 리프레시가 이미 진행 중이면 그 Future를 기다림
    final inFlight = _refreshing;
    if (inFlight != null) return inFlight;

    final completer = Completer<String?>();
    _refreshing = completer.future;

    () async {
      try {
        final newToken = await _auth.refreshAccessToken();
        completer.complete(newToken);
      } catch (_) {
        completer.complete(null);
      } finally {
        // 잠깐 지연 후 락 해제 (대기중인 요청들이 결과를 받을 시간)
        await Future<void>.delayed(const Duration(milliseconds: 40));
        _refreshing = null;
      }
    }();

    return _refreshing!;
  }
}
