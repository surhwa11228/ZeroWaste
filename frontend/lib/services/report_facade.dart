import 'dart:convert';
import 'package:dio/dio.dart';

// 기존 인프라/모델 최대 활용 (경로는 프로젝트에 맞게 조정)
import 'package:flutter_project/services/network.dart';
import 'package:flutter_project/models/report_models.dart';
import 'package:flutter_project/utils/waste_category_enum.dart';

class ReportFacade {
  ReportFacade._() {
    _network.init();
  }
  static final instance = ReportFacade._();

  final _network = Network();
  Dio get _dio => _network.dio;

  static const _submitBase = '/report'; // POST
  static const _searchBase = '/report/search'; // POST
  static const _myBase = '/report/my'; // GET

  /// 제보 생성
  Future<ReportSummary> submit({
    required double gpsLatitude,
    required double gpsLongitude,
    required double selectedLat,
    required double selectedLng,
    required WasteCategory category,
  }) async {
    try {
      final body = {
        'gpsLatitude': gpsLatitude,
        'gpsLongitude': gpsLongitude,
        'selectedLat': selectedLat,
        'selectedLng': selectedLng,
        'wasteCategory': category.api,
      };

      final res = await _dio.post(
        _submitBase,
        data: body,
        options: Options(contentType: 'application/json'),
      );

      final map = _unwrapDataAsMap(res);
      return ReportSummary.fromJson(map);
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    }
  }

  /// 주변 제보 검색
  Future<List<ReportSummary>> search({
    required double centerLat,
    required double centerLng,
    required double radius,
    WasteCategory? category,
  }) async {
    try {
      final body = {
        'centerLat': centerLat,
        'centerLng': centerLng,
        'radius': radius,
        if (category != null) 'wasteCategory': category.api,
      };

      final res = await _dio.post(
        _searchBase,
        data: body,
        options: Options(contentType: 'application/json'),
      );

      final list = _unwrapDataAsList(res);
      return list.map((e) => ReportSummary.fromJson(_asMap(e))).toList();
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    }
  }

  /// 내 제보 목록
  Future<List<DetailedReportSummary>> my({int? startAfter}) async {
    try {
      final res = await _dio.get(
        _myBase,
        queryParameters: {if (startAfter != null) 'startAfter': startAfter},
      );

      final list = _unwrapDataAsList(res);
      return list
          .map((e) => DetailedReportSummary.fromJson(_asMap(e)))
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e));
    }
  }
}

// ────────────────────── Local JSON helpers ──────────────────────
// 서버가 { "data": ... } 래퍼를 쓸 수도/안 쓸 수도 있어서 둘 다 지원
Map<String, dynamic> _unwrapDataAsMap(Response res) {
  final d = res.data;
  if (d is Map<String, dynamic>) {
    final data = d['data'];
    if (data is Map<String, dynamic>) return data;
    return d;
  }
  // 객체가 바로 올 때를 대비해 강제 변환
  return jsonDecode(jsonEncode(d)) as Map<String, dynamic>;
}

List<dynamic> _unwrapDataAsList(Response res) {
  final d = res.data;
  if (d is Map<String, dynamic>) {
    final data = d['data'];
    if (data is List) return data;
    if (data is Map<String, dynamic>) return [data];
  }
  if (d is List) return d;
  return jsonDecode(jsonEncode(d)) as List<dynamic>;
}

Map<String, dynamic> _asMap(dynamic v) => v is Map<String, dynamic>
    ? v
    : jsonDecode(jsonEncode(v)) as Map<String, dynamic>;

String _extractDioMessage(DioException e) {
  try {
    final data = e.response?.data;
    if (data is Map && data['message'] is String)
      return data['message'] as String;
    return e.message ?? 'Network error';
  } catch (_) {
    return e.message ?? 'Network error';
  }
}
