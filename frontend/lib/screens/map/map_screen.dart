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
    // ✅ 플랫폼 초기화 (필수!)
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadFlutterAsset('assets/map.html');
  }

  @override
  Widget build(BuildContext context) {
    final List<Report> markers = MapService.getMockReports();
    final json = jsonEncode(markers.map((r) => r.toJson()).toList());

    // ✅ 마커 주입은 페이지 로드 이후 실행
    Future.delayed(const Duration(seconds: 1), () {
      _controller.runJavaScript("window.addMarkers(`$json`);");
    });

    return Scaffold(
      appBar: AppBar(title: const Text('지도 보기')),
      body: WebViewWidget(controller: _controller), // ✅ 최신 문법!
    );
  }
}
