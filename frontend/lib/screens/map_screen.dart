import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_project/services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _controller;
  bool _pageLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            _pageLoaded = true;
            await Future.delayed(const Duration(milliseconds: 100));
            await initMap(37.5665, 126.9780, level: 4);
          },
        ),
      );

    _loadHtml();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadHtml() async {
    final html = await rootBundle.loadString('assets/map/map.html');
    await _controller.loadHtmlString(html, baseUrl: 'https://localhost');
  }

  Future<void> initMap(double lat, double lng, {int level = 4}) async {
    if (!_pageLoaded) return;
    await _controller.runJavaScript('window.initMap($lat, $lng, $level)');
  }

  Future<void> moveTo(double lat, double lng) async {
    if (!_pageLoaded) return;
    await _controller.runJavaScript('window.moveTo($lat, $lng)');
  }

  // 현 위치로 이동 + 내 위치 마커 표시
  Future<void> goToCurrentLocation() async {
    final pos = await LocationService.current();
    if (pos == null) {
      _toast('위치 권한이 필요합니다. 설정에서 켜주세요.');
      return;
    }
    final lat = pos.latitude;
    final lng = pos.longitude;
    await _controller.runJavaScript('window.setMyLocation($lat, $lng)');
    await moveTo(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('ZeroWaste 지도'),
      ),
      body: WebViewWidget(controller: _controller),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: goToCurrentLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('현위치'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: () => moveTo(36.3353, 127.4579),
            icon: const Icon(Icons.map),
            label: const Text('대전대학교로 이동'),
          ),
        ],
      ),
    );
  }
}
