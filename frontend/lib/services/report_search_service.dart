import 'package:dio/dio.dart';
import 'package:flutter_project/models/report_models.dart';
import 'package:flutter_project/utils/api_enveloper.dart';
import 'network.dart';

class ReportSearchService {
  final _network = Network();
  ReportSearchService._() {
    _network.init();
  }
  static final instance = ReportSearchService._();

  Dio get _dio => _network.dio;

  static const _base = '/report/search';
  static const _my = '/report/my';

  /// POST /api/report/search
  Future<List<ReportSummary>> search({
    required double centerLat,
    required double centerLng,
    required double radius, // meters
    String?
    wasteCategory, // 'CIGARETTE_BUTT' | 'GENERAL_WASTE' | 'FOOD_WASTE' | 'OTHERS'
    CancelToken? cancelToken,
  }) async {
    final body = <String, dynamic>{
      'centerLat': centerLat,
      'centerLng': centerLng,
      'radius': radius,
      if (wasteCategory != null && wasteCategory.isNotEmpty)
        'wasteCategory': wasteCategory,
    };

    try {
      final res = await _dio.post(_base, data: body, cancelToken: cancelToken);

      final summaries = unwrapDataListMapped<ReportSummary>(
        res,
        (m) => ReportSummary.fromJson(m),
      );
      return summaries;
    } on DioException catch (e) {
      throw Exception(extractDioMessage(e));
    }
  }

  Future<List<DetailedReportSummary>> searchMyReports({
    DateTime? startAfter,
    CancelToken? cancelToekn,
  }) async {
    final qp = <String, dynamic>{
      if (startAfter != null)
        'startAfter': startAfter.toUtc().millisecondsSinceEpoch,
    };

    try {
      final res = await _dio.get(
        _base,
        queryParameters: qp.isNotEmpty ? qp : null,
        cancelToken: cancelToekn,
      );

      final summaries = unwrapDataListMapped<DetailedReportSummary>(
        res,
        (m) => DetailedReportSummary.fromJson(m),
      );
      return summaries;
    } on DioException catch (e) {
      throw Exception(extractDioMessage(e));
    }
  }
}
