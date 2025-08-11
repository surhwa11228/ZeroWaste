// lib/services/network.dart
import 'package:dio/dio.dart';
import '../services/auth_service.dart';

class Network {
  static final Network _i = Network._internal();
  factory Network() => _i;
  Network._internal();

  late final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://192.168.45.141:8080/api',
            ),
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            headers: {'Accept': 'application/json'},
          ),
        )
        ..interceptors.add(
          QueuedInterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await AuthService().getAccessToken();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
            onError: (e, handler) async {
              final code = e.response?.statusCode;
              // 일부 서버가 만료 토큰에 403을 주기도 하므로 401/403 모두에서 갱신 시도
              if (code == 401 || code == 403) {
                try {
                  final newToken = await AuthService().refreshAccessToken();
                  if (newToken != null && newToken.isNotEmpty) {
                    final req = e.requestOptions;
                    req.headers['Authorization'] = 'Bearer $newToken';
                    final clone = await dio.fetch(req);
                    return handler.resolve(clone);
                  }
                } catch (_) {
                  /* ignore */
                }
              }
              handler.next(e);
            },
          ),
        );
}
