import 'package:flutter/material.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _latitude = TextEditingController();
  final TextEditingController _longitude = TextEditingController();
  final TextEditingController _category = TextEditingController();
  final TextEditingController _comment = TextEditingController();
  final TextEditingController _imageUrl = TextEditingController(); // mock

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final report = Report(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: double.tryParse(_latitude.text) ?? 0,
        longitude: double.tryParse(_longitude.text) ?? 0,
        imageUrl: _imageUrl.text,
        wasteCategory: _category.text,
        comment: _comment.text,
        createAt: DateTime.now().toIso8601String(),
      );

      await ReportService.submitReport(report);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('제보가 등록되었습니다')));

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('제보 등록')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _imageUrl,
                decoration: const InputDecoration(labelText: '사진 URL (mock)'),
                validator: (v) => v!.isEmpty ? '사진 URL을 입력하세요' : null,
              ),
              TextFormField(
                controller: _latitude,
                decoration: const InputDecoration(labelText: '위도'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? '위도를 입력하세요' : null,
              ),
              TextFormField(
                controller: _longitude,
                decoration: const InputDecoration(labelText: '경도'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? '경도를 입력하세요' : null,
              ),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: '쓰레기 종류'),
                validator: (v) => v!.isEmpty ? '분류를 입력하세요' : null,
              ),
              TextFormField(
                controller: _comment,
                decoration: const InputDecoration(labelText: '설명'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: const Text('제보 등록')),
            ],
          ),
        ),
      ),
    );
  }
}
