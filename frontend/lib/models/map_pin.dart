import 'package:flutter_project/utils/waste_category_enum.dart';

class MapPin {
  final String docId;
  final double lat;
  final double lng;
  final WasteCategory category;

  // UI 전용 필드들 (필요시)
  final bool isSelected;
  final int? clusterId;
  final String? iconKey;

  const MapPin({
    required this.docId,
    required this.lat,
    required this.lng,
    required this.category,
    this.isSelected = false,
    this.clusterId,
    this.iconKey,
  });

  Map<String, dynamic> toJsMap() => {
    'documentId': docId,      // JS에 docId 실어 보내기
    'latitude': lat,
    'longitude': lng,
    'wasteCategory': category.api,
  };
}