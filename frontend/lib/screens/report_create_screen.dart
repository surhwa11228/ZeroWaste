//임시 제보 작성 스크린

import 'dart:io';
import 'package:flutter/material.dart';

class ReportCreateScreen extends StatelessWidget {
  final double lat, lng;
  final File imageFile;
  final String kind;

  const ReportCreateScreen({
    super.key,
    required this.lat,
    required this.lng,
    required this.imageFile,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('제보 작성')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(imageFile, height: 220, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Text('위치: $lat, $lng'),
          const SizedBox(height: 6),
          Text(
            '종류: $kind',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: '설명(선택)',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('제보가 전송되었습니다. (mock)')),
              );
              Navigator.pop(context);
            },
            icon: const Icon(Icons.send),
            label: const Text('제보 보내기'),
          ),
        ],
      ),
    );
  }
}
