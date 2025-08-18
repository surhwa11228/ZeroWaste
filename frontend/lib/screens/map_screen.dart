import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'report_create_screen.dart';
import 'package:flutter_project/services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _controller;
  bool _pageLoaded = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'KakaoBridge', // map.html과 동일
        onMessageReceived: _onJsMessage,
      )
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

  // ▼ JS → Flutter 메시지 처리 (지도 터치 후 "이 위치로 제보" 눌렀을 때)
  Future<void> _onJsMessage(JavaScriptMessage msg) async {
    final m = msg.message;

    // 문자열/JSON 모두 수용
    Map<String, dynamic>? data;
    try {
      data = jsonDecode(m) as Map<String, dynamic>;
    } catch (_) {
      // 'MAP_INIT_DONE' 같은 단순 문자열은 무시
      return;
    }
    final type = data['type'];

    if (type == 'location_selected') {
      final lat = (data['lat'] as num).toDouble();
      final lng = (data['lng'] as num).toDouble();

      // 1) 카메라 촬영
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
      );
      if (picked == null) return; // 사용자 취소
      final file = File(picked.path);

      // 2) 쓰레기 종류 선택
      final kind = await _pickTrashKind(context);
      if (kind == null) return;

      // 3) 제보 작성 화면으로 이동
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportCreateScreen(
            lat: lat,
            lng: lng,
            imageFile: file,
            kind: kind,
          ),
        ),
      );

      // (선택) 선택 상태 초기화
      await _controller.runJavaScript(
        'window.clearSelection && clearSelection();',
      );
    }
  }

  Future<String?> _pickTrashKind(BuildContext context) async {
    const kinds = ['일반쓰레기', '대형폐기물', '재활용', '음식물', '기타'];

    final scheme = Theme.of(context).colorScheme;
    final Color chipBg = scheme.surfaceVariant; // 미선택 배경
    final Color chipText = scheme.onSurfaceVariant; // 미선택 글자
    final Color chipBorder = scheme.outlineVariant; // 미선택 테두리
    final Color chipSelectedBg = const Color(0xFF2F7D32); // ✅ 선택 배경(브랜드 그린)

    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 12,
          children: [
            const Text(
              '쓰레기 종류 선택',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kinds
                  .map(
                    (k) => ChoiceChip(
                      label: Text(k),
                      selected: false,
                      backgroundColor: chipBg,
                      labelStyle: TextStyle(
                        color: chipText,
                        fontWeight: FontWeight.w600,
                      ),
                      selectedColor: chipSelectedBg,
                      side: BorderSide(color: chipBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      onSelected: (_) => Navigator.pop(ctx, k),
                    ),
                  )
                  .toList(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소'),
              ),
            ),
          ],
        ),
      ),
    );
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
