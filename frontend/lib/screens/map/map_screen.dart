import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../models/report.dart';
import '../../services/map_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadFlutterAsset('assets/map.html');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final List<Report> markers = MapService.getMockReports();
    final json = jsonEncode(markers.map((r) => r.toJson()).toList());

    Future.delayed(const Duration(seconds: 1), () {
      _controller.runJavaScript("window.addMarkers(`$json`);");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('지도 보기')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
