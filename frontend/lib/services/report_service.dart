import '../models/report.dart';

class ReportService {
  static final List<Report> _reports = [];

  static Future<void> submitReport(Report report) async {
    await Future.delayed(Duration(milliseconds: 500));
    _reports.add(report);
    print('제보 저장됨 (mock): ${report.toJson()}');
  }

  static List<Report> getReports() => _reports;
}
