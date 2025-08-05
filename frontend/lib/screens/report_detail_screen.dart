import 'package:flutter/material.dart';

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('제보 상세')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.image, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            '불법 투기 의심 쓰레기',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '서울시 강남구 역삼동 · 2025-08-05',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Divider(height: 32),
          Text(
            '설명',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text('주택가 골목에서 발견된 쓰레기 더미. 악취 발생.'),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            children: const [
              Chip(label: Text('대기')),
              Chip(label: Text('사진 1')),
              Chip(label: Text('신고자 A')),
            ],
          ),
        ],
      ),
    );
  }
}
