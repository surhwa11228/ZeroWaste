import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('제보 등록')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              alignment: Alignment.center,
              child: const Text('사진 영역 (플레이스홀더)'),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: '위치 (예: 서울시 강남구...)'),
            ),
            const SizedBox(height: 12),
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(labelText: '설명'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () {}, child: const Text('제보하기')),
          ],
        ),
      ),
    );
  }
}
