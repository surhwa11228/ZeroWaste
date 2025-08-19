import 'dart:convert';
import 'dart:async';
import 'dart:math' show cos, sin, asin, sqrt, pi;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/waste_category_enum.dart'; // WasteCategory, WasteCategoryCodec(.api)
import '../services/report_facade.dart';
import '../models/report_models.dart';

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

  // 화면 변경 → 서버 조회 디바운스
  Timer? _boundsDebounce;
  bool _fetching = false;

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
            _mapReady = true;
            _scheduleFetchPins();
            return;
          }

          if (s.startsWith('BOUNDS:')) {
            _scheduleFetchPins();
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
            // // 페이지 로딩 완료 후, 혹시 READY 신호보다 먼저 JS 호출이 필요하면 여기서도 보호
            // await Future<void>.delayed(const Duration(milliseconds: 50));
            if (!_mapReady) {
              _scheduleFetchPins();
            }
          },
        ),
      )
      ..loadFlutterAsset('assets/map/map.html');
  }

  // ───────────────────────── 자동 핀 로딩 ─────────────────────────

  void _scheduleFetchPins() {
    _boundsDebounce?.cancel();
    _boundsDebounce = Timer(
      const Duration(milliseconds: 350),
      _fetchPinsForViewport,
    );
  }

  Future<void> _fetchPinsForViewport() async {
    if (!_mapReady || _fetching) return;
    _fetching = true;

    try {
      // JS에서 현재 뷰포트 경계 가져오기
      final boundsJson = await _controller.runJavaScriptReturningResult(
        'JSON.stringify(getBounds && getBounds())',
      );
      if (boundsJson == 'null') return;

      final map = _parseJsonMap(boundsJson.toString());
      if (map == null) return;

      final south = (map['south'] as num).toDouble();
      final west = (map['west'] as num).toDouble();
      final north = (map['north'] as num).toDouble();
      final east = (map['east'] as num).toDouble();
      final level = map['level'];

      // debugPrint(
      //   '[Bounds]'
      //   ' south=$south west=$west north=$north east=$east level=$level',
      // );

      // 중심: 저장된 값이 있으면 사용, 없으면 뷰포트 중앙
      final centerLat = _currentCenter?.lat ?? (south + north) / 2.0;
      final centerLng = _currentCenter?.lng ?? (west + east) / 2.0;

      final radiusM = _radiusMetersFromBounds(
        south: south,
        west: west,
        north: north,
        east: east,
      );

      // debugPrint(
      //   '[Radius]'
      //   ' center=($centerLat,$centerLng)'
      //   ' -> send radiusM=$radiusM',
      // );

      // 서버 조회 (필터가 있으면 해당 카테고리만)
      final items = await ReportFacade.instance.search(
        centerLat: centerLat,
        centerLng: centerLng,
        radius: radiusM,
        category: _filter, // null이면 전체
      );

      // debugPrint(
      //   '[Result] count=${items.length} (filter=${_filter?.api ?? 'ALL'})',
      // );

      // 최대 n개로 제한
      final top = items.take(80).toList();

      // if (items.isEmpty) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('표시할 제보가 없습니다. (기간/범위를 조정하거나 지도를 이동해 보세요)'),
      //     ),
      //   );
      // } else if (items.length >= 50) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('핀을 더 보려면 지도를 확대하세요. (최대 50개 표시)')),
      //   );
      // }

      // 지도 갱신: 모두 지우고 다시 그림
      await _controller.runJavaScript('clearMarkers();');
      for (final ReportSummary it in top) {
        final cat = it.wasteCategory.api; // enum → API 문자열
        final js = "addMarker(${it.latitude}, ${it.longitude}, '$cat');";
        await _controller.runJavaScript(js);
      }

      // 필터 재적용(안전)
      await _applyFilterToWebView();
    } catch (e, st) {
      // debugPrint('[Search ERROR] $e\n$st');
      // 네트워크/파싱 실패는 조용히 무시 (원하면 로그/스낵바 추가)
    } finally {
      _fetching = false;
    }
  }

  // WebView에서 온 JSON 문자열을 안전 파싱
  Map<String, dynamic>? _parseJsonMap(String raw) {
    try {
      String s = raw.trim();
      if (s.startsWith('"') && s.endsWith('"')) {
        // JS → Dart로 올 때 큰따옴표로 한번 감싸져 올 수 있음
        s = s.substring(1, s.length - 1).replaceAll(r'\"', '"');
      }
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
      return null;
    } catch (_) {
      return null;
    }
  }

  // 하버사인 (km)
  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    return R * c;
  }

  /// 뷰포트에서 보낼 반경(m) 계산:
  /// - 기존: center→north 한쪽만 보던 것을
  /// - 개선: center→NE(대각선 반쪽) 거리 사용 (화면 반경에 더 근접)
  /// - 안전 캡: 50m ~ 5000m
  double _radiusMetersFromBounds({
    required double south,
    required double west,
    required double north,
    required double east,
  }) {
    final centerLat = (south + north) / 2.0;
    final centerLng = (west + east) / 2.0;

    // center → NE 코너까지 (뷰포트 대각선의 반)
    final diagHalfKm = _haversineKm(centerLat, centerLng, north, east);
    // 일부 SDK에서 level 낮을 때 bounds가 커질 수 있으니 안전계수 0.9
    final meters = (diagHalfKm * 1000.0 * 0.9);

    // 서버 보호 및 과소/과대 질의 방지
    final clamped = meters.clamp(50.0, 5000.0);
    return clamped.toDouble();
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

  Future<void> _applyFilterToWebView() async {
    if (!_mapReady) return;
    final filter = _filter?.api; // null이면 전체 표시
    if (filter == null) {
      await _controller.runJavaScript("filterByCategory(null);");
    } else {
      await _controller.runJavaScript("filterByCategory('$filter');");
    }
  }

  // 상단 필터 칩: 같은 걸 다시 누르면 해제 (null=전체 표시)
  Widget _filterChip(String label, WasteCategory value) {
    final bool selected = _filter == value;
    return GestureDetector(
      onTap: () async {
        setState(() => _filter = selected ? null : value);
        await _applyFilterToWebView();
        _scheduleFetchPins();
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

  @override
  void dispose() {
    _boundsDebounce?.cancel();
    super.dispose();
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

          // 상단 우측에 현재 반경/필터를 표시 (디버그용)
          // Positioned(
          //   top: 40,
          //   right: 16,
          //   child: Container(
          //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          //     decoration: BoxDecoration(
          //       color: Colors.black.withOpacity(0.5),
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //     child: Builder(
          //       builder: (_) {
          //         final f = _filter?.labelKo ?? '전체';
          //         return FutureBuilder<String>(
          //           future: _controller
          //               .runJavaScriptReturningResult(
          //                 'JSON.stringify(getBounds && getBounds())',
          //               )
          //               .then((v) {
          //                 final m = _parseJsonMap(v.toString());
          //                 if (m == null) return '반경: -';
          //                 final r = _radiusMetersFromBounds(
          //                   south: (m['south'] as num).toDouble(),
          //                   west: (m['west'] as num).toDouble(),
          //                   north: (m['north'] as num).toDouble(),
          //                   east: (m['east'] as num).toDouble(),
          //                 );
          //                 return '반경: ${r.toStringAsFixed(0)} m';
          //               })
          //               .catchError((_) => '반경: -'),
          //           builder: (context, snap) {
          //             final radiusText = snap.data ?? '반경: -';
          //             return Text(
          //               '$radiusText · 필터: $f',
          //               style: const TextStyle(
          //                 color: Colors.white,
          //                 fontSize: 12,
          //               ),
          //             );
          //           },
          //         );
          //       },
          //     ),
          //   ),
          // ),

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
