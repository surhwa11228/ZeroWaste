import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ReportListScreen extends StatelessWidget {
  const ReportListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      {'title': '불법 투기 제보 #1', 'status': '대기중'},
      {'title': '불법 투기 제보 #2', 'status': '승인됨'},
      {'title': '불법 투기 제보 #3', 'status': '거절됨'},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final report = reports[index];
        final status = report['status']!;
        final chipColor = _getStatusColor(status);
        final textColor = status == '거절됨' ? Colors.white : Colors.black87;

        return Card(
          child: ListTile(
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
              child: const Icon(Icons.image, size: 32, color: Colors.white70),
            ),
            title: Text(report['title']!),
            subtitle: const Text('서울시 강남구 • 2025.08.06'),
            trailing: Chip(
              label: Text(status, style: TextStyle(color: textColor)),
              backgroundColor: chipColor,
              side: BorderSide.none,
            ),
            onTap: () {},
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '대기중':
        return AppColors.yellow;
      case '승인됨':
        return AppColors.greenLight;
      case '거절됨':
        return AppColors.red;
      default:
        return Colors.grey[200]!;
    }
  }
}
