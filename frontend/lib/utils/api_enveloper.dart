import 'package:dio/dio.dart';

/// 서버 공통 응답 형태를 다루기 위한 유틸
/// 서버 응답이 보통 { status, message, data } 래퍼로 오며,
/// 때때로 data 자체만 오는 경우도 허용합니다.
class ApiEnvelope {
  final int? status;
  final String? message;
  final Object? data;

  ApiEnvelope({this.status, this.message, this.data});

  factory ApiEnvelope.fromResponse(Response res) {
    final root = res.data;
    if (root is Map<String, dynamic>) {
      return ApiEnvelope(
        status: (root['status'] as num?)?.toInt() ?? res.statusCode,
        message: root['message']?.toString(),
        data: root.containsKey('data') ? root['data'] : root, // data 키가 없으면 루트 자체
      );
    }
    return ApiEnvelope(status: res.statusCode, data: root);
  }
}

/// 성공 응답에서 data를 파싱해 반환. 파서가 없으면 그대로 반환(Map/List/프리미티브).
T unwrapData<T>(Response res, {T Function(Object? json)? parse}) {
  final env = ApiEnvelope.fromResponse(res);
  final payload = env.data;
  if (parse != null) return parse(payload);
  return payload as T;
}

/// data가 Map이어야 하는 경우 강제 변환
Map<String, dynamic> unwrapDataAsMap(Response res) {
  return unwrapData<Map<String, dynamic>>(res, parse: (json) {
    if (json is Map<String, dynamic>) return json;
    throw StateError('Expected Map in data, got: ${json.runtimeType}');
  });
}

/// data가 List이어야 하는 경우 강제 변환
List unwrapDataAsList(Response res) {
  return unwrapData<List>(res, parse: (json) {
    if (json is List) return json;
    throw StateError('Expected List in data, got: ${json.runtimeType}');
  });
}

/// ============ 추가: 타입 안전 매퍼 ============
/// data(Map) → T
T unwrapDataMapped<T>(Response res, T Function(Map<String, dynamic>) fromJson) {
  return unwrapData<T>(res, parse: (json) {
    if (json is Map<String, dynamic>) return fromJson(json);
    throw StateError('Expected Map in data, got: ${json.runtimeType}');
  });
}

/// data(List) → List<T>
List<T> unwrapDataListMapped<T>(Response res, T Function(Map<String, dynamic>) fromJson) {
  return unwrapData<List<T>>(res, parse: (json) {
    if (json is! List) throw StateError('Expected List in data, got: ${json.runtimeType}');
    return json
        .whereType<Map>()
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
  });
}

/// DioException에서 메시지 안전 추출
String extractDioMessage(DioException e) {
  final d = e.response?.data;
  if (d is Map && d['message'] != null) return d['message'].toString();
  if (d is String && d.isNotEmpty) return d;
  // 바이너리/기타 타입은 상태코드와 기본 메시지로 대체
  final sc = e.response?.statusCode;
  return 'HTTP ${sc ?? ''} ${e.message ?? 'Request failed'}'.trim();
}

// ================= 사용 예 =================
// 1) Report 등록 (응답 data가 Map)
// try {
//   final res = await _dio.post('/report', data: body);
//   final map = unwrapDataAsMap(res);          // { id: ..., ... }
// } on DioException catch (e) {
//   throw Exception(extractDioMessage(e));
// }
//
// 2) Report 검색 (응답 data가 List)
// final res = await _dio.post('/report/search', data: req);
// final list = unwrapDataListMapped<ReportSummary>(
//   res,
//   (m) => ReportSummary.fromJson(m),
// );
