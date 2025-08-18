import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _web;
  bool _mapReady = false;
  LatLng? _center; // 현재 지도 중심(선택된 좌표)
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('KakaoBridge', onMessageReceived: _onJsMessage)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            // HTML 로드가 끝나면, 위치 권한을 요청하고 현재 위치로 initMap 호출
            await _initWithMyLocation();
          },
        ),
      )
      ..loadFlutterAsset('assets/map/map.html');
  }

  void _onJsMessage(JavaScriptMessage msg) {
    final raw = msg.message;
    // 간단 형태('KAKAO_SDK_LOADED' 등) 혹은 JSON
    if (raw == 'KAKAO_SDK_LOADED' || raw == 'MAP_INIT_DONE') {
      // 필요 시 로깅
      return;
    }
    if (raw == 'KAKAO_SDK_ERROR' || raw == 'KAKAO_NOT_READY') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('지도 SDK 로드에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type == 'js_error') {
        // map.html에서 window.onerror 전달
        return;
      }
      if (type == 'map_click') {
        // (참고) map.html에서 클릭 이벤트를 보낼 수도 있으나, 우리는 중심좌표를 사용
        return;
      }
      if (type == 'location_selected') {
        final lat = (data['lat'] as num).toDouble();
        final lng = (data['lng'] as num).toDouble();
        setState(() => _center = LatLng(lat, lng));

        // 여기서 바로 제보 화면으로 이동하거나, 외부 버튼에서만 이동해도 된다.
        // 현재 설계는 "화면 버튼"을 눌렀을 때 JS로 location_selected를 강제로 발생시킨 뒤 이 콜백에서 네비게이션 한다.
        _goReportCreate(LatLng(lat, lng));
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _initWithMyLocation() async {
    try {
      // 권한
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever) {
        p = await Geolocator.requestPermission();
      }

      // 현재 위치 (실패 시 기본값 사용)
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition();
      } catch (_) {}

      final lat = pos?.latitude ?? 37.5665; // 서울시청 기본값
      final lng = pos?.longitude ?? 126.9780;

      // map.html의 initMap(lat,lng,level) 호출
      await _web.runJavaScript('initMap($lat,$lng,4);');
      // 중심좌표 내부 상태도 갱신
      setState(() {
        _mapReady = true;
        _loading = false;
        _center = LatLng(lat, lng);
      });

      // (선택) 내 위치 마커 표시
      await _web.runJavaScript('setMyLocation($lat,$lng);');
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('지도를 초기화하지 못했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onPickHere() async {
    if (!_mapReady) return;
    await _web.runJavaScript('''
      (function(){
        if(!window.map){ KakaoBridge.postMessage('KAKAO_NOT_READY'); return; }
        var c = map.getCenter();
        KakaoBridge.postMessage(JSON.stringify({type:'location_selected', lat: c.getLat(), lng: c.getLng()}));
      })();
    ''');
  }

  Future<void> _moveToMyLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      await _web.runJavaScript('moveTo(${pos.latitude}, ${pos.longitude});');
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('현재 위치를 가져오지 못했습니다.')));
    }
  }

  void _goReportCreate(LatLng target) {
    Navigator.pushNamed(
      context,
      '/report/create',
      arguments: {'lat': target.lat, 'lng': target.lng},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('위치 선택'),
        actions: [
          IconButton(
            onPressed: _moveToMyLocation,
            icon: const Icon(Icons.my_location),
            tooltip: '내 위치로',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _web),

          // 로딩 인디케이터
          if (_loading) const Center(child: CircularProgressIndicator()),

          // 하단 고정 패널: 안내 + 선택 좌표 미리보기 + 제보 버튼
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _center == null
                          ? '지도를 움직여 가운데 핀 위치를 맞춰주세요'
                          : '선택 위치: ${_center!.lat.toStringAsFixed(6)}, ${_center!.lng.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _onPickHere,
                        icon: const Icon(Icons.send),
                        label: const Text('이 위치로 제보'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LatLng {
  final double lat;
  final double lng;
  LatLng(this.lat, this.lng);
}
