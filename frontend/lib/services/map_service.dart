import '../models/report.dart';

class MapService {
  static List<Report> getMockReports() {
    return [
      Report(
        id: '1',
        latitude: 37.5665,
        longitude: 126.9780,
        imageUrl: '',
        wasteCategory: '가구',
        comment: '소파 무단투기',
        createAt: DateTime.now().toIso8601String(),
      ),
      Report(
        id: '2',
        latitude: 37.5700,
        longitude: 126.9820,
        imageUrl: '',
        wasteCategory: '생활쓰레기',
        comment: '봉투 없이 버림',
        createAt: DateTime.now().toIso8601String(),
      ),
    ];
  }
}
