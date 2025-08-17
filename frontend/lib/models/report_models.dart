import 'package:flutter_project/models/map_pin.dart';
import 'package:flutter_project/utils/waste_category_enum.dart';

class ReportSummary {
  final String documentId;
  final double latitude;
  final double longitude;
  final WasteCategory wasteCategory;

  ReportSummary({
    required this.documentId,
    required this.latitude,
    required this.longitude,
    required this.wasteCategory,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> j) => ReportSummary(
    documentId: j['documentId'].toString(),
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    wasteCategory: WasteCategoryCodec.fromApi(j['wasteCategory']),
  );
}

extension ReportSummaryX on ReportSummary {
  MapPin toMapPin() => MapPin(
    docId: documentId,
    lat: latitude,
    lng: longitude,
    category: wasteCategory,
  );
}

class DetailedReportSummary extends ReportSummary {
  final DateTime reportedAt;
  final bool hasAdditionalInfo;

 DetailedReportSummary({
    required super.documentId,
    required super.latitude,
    required super.longitude,
    required super.wasteCategory,
    required this.reportedAt,
    required this.hasAdditionalInfo,
  });

  factory DetailedReportSummary.fromJson(Map<String, dynamic> j) =>
      DetailedReportSummary(
        documentId: j['documentId'].toString(),
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        wasteCategory: WasteCategoryCodec.fromApi(j['wasteCategory']),
        reportedAt: _epochToDateTime(j['reportedAt']),
        hasAdditionalInfo: j['hasAdditionalInfo'] as bool? ?? false,
      );

  static DateTime _epochToDateTime(Object? v, {bool isUtc = true}) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final n = (v as num).toInt();
    // 초(10자리)로 오면 ms로 보정
    final ms = n < 1000000000000 ? n * 1000 : n;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: isUtc);
    return isUtc ? dt.toLocal() : dt;
  }
}