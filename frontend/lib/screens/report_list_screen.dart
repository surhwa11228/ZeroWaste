import 'package:flutter/material.dart';
import 'package:flutter_project/services/report_facade.dart';
import 'package:flutter_project/models/report_models.dart';
import 'package:flutter_project/utils/waste_category_enum.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<DetailedReportSummary> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ReportFacade.instance.my();
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 제보')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final it = _items[i];
                return ListTile(
                  title: Text(it.wasteCategory.api),
                  subtitle: Text(
                    '(${it.latitude.toStringAsFixed(5)}, ${it.longitude.toStringAsFixed(5)}) • '
                    '${DateTime.fromMillisecondsSinceEpoch(it.reportedAt.millisecondsSinceEpoch)}',
                  ),
                  trailing: it.hasAdditionalInfo
                      ? const Icon(Icons.info, color: Colors.green)
                      : null,
                );
              },
            ),
    );
  }
}
