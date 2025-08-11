import 'package:flutter/material.dart';

class ReportListScreen extends StatelessWidget {
  const ReportListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      {'title': '불법 투기 포대', 'address': '마포구 서교동 123-4'},
      {'title': '무단 폐기 가구', 'address': '관악구 신림동 512-8'},
      {'title': '대형 폐기물 방치', 'address': '강서구 등촌동 77-9'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('제보 내역')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final item = reports[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: const Icon(Icons.photo_outlined),
              ),
              title: Text(
                item['title']!,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(item['address']!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: 상세 페이지로 이동
              },
            ),
          );
        },
      ),
    );
  }
}
