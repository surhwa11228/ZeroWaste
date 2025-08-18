import 'package:dio/dio.dart';

class Network {
  static final Network _i = Network._();
  factory Network() => _i;
  Network._();

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.45.98:8080/api', // ← 서버 도메인/로컬주소로 교체
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );
}
