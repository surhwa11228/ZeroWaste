import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_project/models/report_models.dart';
import 'package:flutter_project/utils/api_enveloper.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter_project/services/network.dart';

class ReportService {
  final _network = Network();
  ReportService._() {
    _network.init();
  }
  static final instance = ReportService._();
  Dio get _dio => _network.dio;

  static const _base = '/report';

  Future<Map<String, dynamic>> submit({
    required double gpsLat,
    required double gpsLng,
    required double selectedLat,
    required double selectedLng,
    required String wasteCategory,
  }) async {
    try {
      final body = <String, dynamic>{
        'gpsLat': gpsLat,
        'gpsLng': gpsLng,
        'selectedLat': selectedLat,
        'selectedLng': selectedLng,
        'wasteCategory': wasteCategory,
      };

      final res = await _dio.post(
        _base,
        data: body,
        options: Options(contentType: 'application/json'),
      );

      final map = unwrapDataAsMap(res);
      return map;
    } on DioException catch (e) {
      throw Exception(extractDioMessage(e));
    }
  }
}
