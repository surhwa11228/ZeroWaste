import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/waste_category_enum.dart'; // WasteCategory, WasteCategoryCodec(.api)

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _controller;
  bool _mapReady = false; // map.html에서 READY 신호 수신 여부
  LatLng? _currentCenter; // JS → "lat,lng" 수신해 반영
  WasteCategory? _filter; // 상단 카테고리 '표시 필터'

  static const Map<WasteCategory, String> _labels = {
    WasteCategory.cigaretteButt: '담배꽁초',
    WasteCategory.generalWaste: '일반쓰레기',
    WasteCategory.foodWaste: '음식물',
    WasteCategory.others: '기타',
  };

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'MapChannel',
        onMessageReceived: (JavaScriptMessage msg) async {
          final s = msg.message.trim();

          // map.html에서 초기화 완료 시 'READY'를 보내도록 되어 있음
          if (s == 'READY') {
            setState(() => _mapReady = true);
            // 초기 필터 상태 재적용 (있다면)
            await _applyFilterToWebView();
            return;
          }

          // (선택) 디버그 로그: ADDED:lat,lng,category,count=n
          if (s.startsWith('ADDED:')) {
            // print('[MAP JS] $s');
            return;
          }

          // "lat,lng" 형식 수신하여 중심 저장
          final parts = s.split(',');
          if (parts.length >= 2) {
            final lat = double.tryParse(parts[0]);
            final lng = double.tryParse(parts[1]);
            if (lat != null && lng != null) {
              setState(() => _currentCenter = LatLng(lat, lng));
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            // 페이지 로딩 완료 후, 혹시 READY 신호보다 먼저 JS 호출이 필요하면 여기서도 보호
            await Future<void>.delayed(const Duration(milliseconds: 50));
            if (!_mapReady) {
              // map.html이 tilesloaded에서 emitCenter()를 쏘므로 대기
            }
          },
        ),
      )
      ..loadFlutterAsset('assets/map/map.html');
  }

  Future<void> _moveToMyLocation() async {
    final perm = await Geolocator.checkPermission();
    var ensured = perm;
    if (perm == LocationPermission.denied) {
      ensured = await Geolocator.requestPermission();
    }
    if (ensured == LocationPermission.denied ||
        ensured == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 필요합니다. 설정에서 허용해주세요.')),
        );
      }
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    if (!_mapReady) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    await _controller.runJavaScript(
      'setCenter(${pos.latitude}, ${pos.longitude});',
    );
  }

  // 제보하기: 현재 지도 중심만 넘기고, 카테고리 선택은 제보 화면에서
  Future<void> _onReport() async {
    if (_currentCenter == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('지도의 중앙 위치를 정해주세요.')));
      return;
    }

    final result = await Navigator.pushNamed(
      context,
      '/report/create',
      arguments: {'lat': _currentCenter!.lat, 'lng': _currentCenter!.lng},
    );

    // 제보 성공 시: 반환값으로 넘어온 좌표/카테고리로 JS의 addMarker 호출
    if (result is Map && result['ok'] == true) {
      final double lat = (result['lat'] as num).toDouble();
      final double lng = (result['lng'] as num).toDouble();
      final String categoryApi =
          result['category'] as String; // e.g. "CIGARETTE_BUTT"

      if (!_mapReady) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      await _controller.runJavaScript("addMarker($lat, $lng, '$categoryApi');");

      // 필터 때문에 방금 추가한 마커가 숨겨지지 않도록, 동일 카테고리로 필터하거나 전체로 풀기
      if (_filter != null && _filter!.api != categoryApi) {
        // 방금 추가된 카테고리만 보이게 바꿈
        setState(() => _filter = WasteCategoryCodec.fromApi(categoryApi));
        await _applyFilterToWebView();
      }
    }
  }

  // 상단 필터 칩: 같은 걸 다시 누르면 해제 (null=전체 표시)
  Widget _filterChip(String label, WasteCategory value) {
    final bool selected = _filter == value;
    return GestureDetector(
      onTap: () async {
        setState(() => _filter = selected ? null : value);
        await _applyFilterToWebView();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selected ? Colors.green : Colors.grey.shade400,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.green : Colors.black87,
            fontSize: 15,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 과거 코드 호환: _categoryChip 호출을 _filterChip으로 위임
  Widget _categoryChip(String label, WasteCategory value) =>
      _filterChip(label, value);

  Future<void> _applyFilterToWebView() async {
    if (!_mapReady) return;
    final filter = _filter?.api; // null이면 전체 표시
    if (filter == null) {
      await _controller.runJavaScript("filterByCategory(null);");
    } else {
      await _controller.runJavaScript("filterByCategory('$filter');");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지도'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: () async {
              await _controller.reload();
              // 새로고침 후 READY 수신 시 _applyFilterToWebView()가 불림
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          // 지도(WebView)
          Positioned.fill(child: WebViewWidget(controller: _controller)),

          // 중앙 고정 마커 (Flutter 오버레이) — 터치 통과
          const IgnorePointer(
            ignoring: true,
            child: Align(
              alignment: Alignment.center,
              child: Icon(Icons.location_on, size: 48, color: Colors.red),
            ),
          ),

          // 상단: 카테고리 "표시 필터"
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Wrap(
                spacing: 8,
                children: WasteCategory.values
                    .map((wc) => _filterChip(_labels[wc]!, wc))
                    .toList(),
              ),
            ),
          ),

          // 좌하단: 현재 위치로 이동
          Positioned(
            left: 15,
            bottom: 15,
            child: ClipOval(
              child: Material(
                color: Colors.white,
                child: InkWell(
                  onTap: _moveToMyLocation,
                  child: const Padding(
                    padding: EdgeInsets.all(1),
                    child: Icon(Icons.my_location, size: 30),
                  ),
                ),
              ),
            ),
          ),

          // 우하단: 제보하기
          Positioned(
            right: 12,
            bottom: 12,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _onReport,
              icon: const Icon(Icons.edit),
              label: const Text('제보하기'),
            ),
          ),
        ],
      ),
    );
  }
}

// 간단한 LatLng 보조 클래스
class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);
}
