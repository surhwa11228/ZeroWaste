import 'dart:convert';
import 'dart:async';
import 'dart:math' show cos, sin, asin, sqrt, pi, max;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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

  /// 지도에서 가장 최근 수신한 중심(센터)
  LatLng? _currentCenter;

  /// 마지막으로 서버에 실제로 질의(fetch)한 중심(센터)
  LatLng? _lastFetchedCenter;

  /// 최근 뷰포트 반경(대각선/2 기반, meter)
  double? _latestViewportRadiusM;

  /// 상단 '현 지도에서 검색' 버튼 표시 여부
  bool _showSearchHere = false;

  /// CENTER/BOUNDS 이벤트 디바운스
  Timer? _centerDebounce;

  /// 카테고리 '표시 필터'
  WasteCategory? _filter;

  /// 내부 fetch 진행 중 보호
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

          // map.html → 초기화 완료
          if (s == 'READY') {
            _mapReady = true;
            // 초기 진입: GPS 기준으로 지도 이동 + 1회 자동 새로고침
            unawaited(_bootstrapInitialGpsFetch());
            return;
          }

          // BOUNDS:south,west,north,east,level
          if (s.startsWith('BOUNDS:')) {
            final parts = s.substring(7).split(',');
            if (parts.length >= 4) {
              final south = double.tryParse(parts[0]);
              final west = double.tryParse(parts[1]);
              final north = double.tryParse(parts[2]);
              final east = double.tryParse(parts[3]);
              if (south != null &&
                  west != null &&
                  north != null &&
                  east != null) {
                // 최신 반경 저장
                _latestViewportRadiusM = _radiusMetersFromBounds(
                  south: south,
                  west: west,
                  north: north,
                  east: east,
                );
                _scheduleCenterCheck(); // 버튼 노출 여부 재평가
              }
            }
            return;
          }

          // CENTER:lat,lng  혹은 "lat,lng"
          final centerStr = s.startsWith('CENTER:') ? s.substring(7) : s;
          final parts = centerStr.split(',');
          if (parts.length >= 2) {
            final lat = double.tryParse(parts[0]);
            final lng = double.tryParse(parts[1]);
            if (lat != null && lng != null) {
              _currentCenter = LatLng(lat, lng);
              _scheduleCenterCheck(); // 버튼 노출 여부 재평가
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            // 페이지 로딩 완료 후 READY 이전이라면 대기
            if (!_mapReady) {
              // READY 이후 _bootstrapInitialGpsFetch()가 실행됨
            }
          },
        ),
      );
    // ..loadFlutterAsset('assets/map/map.html');
    _initMapPage();
  }

  Future<void> _initMapPage() async {
    final html = await _loadMapHtmlInjected();
    await _controller.loadHtmlString(html, baseUrl: 'assets/map/');
  }

  Future<String> _loadMapHtmlInjected() async {
    // flutter run/build 시 --dart-define=KAKAO_JS_KEY=실제키 로 주입
    final key = const String.fromEnvironment('KAKAO_JS_KEY', defaultValue: '');
    var html = await rootBundle.loadString('assets/map/map.html');
    if (key.isEmpty) {
      debugPrint('[Kakao] KAKAO_JS_KEY 가 설정되지 않았습니다.');
    }
    return html.replaceFirst('__KAKAO_JS_KEY__', key);
  }

  // ───────────────────────── '현 지도에서 검색' 버튼 로직 ─────────────────────────

  void _scheduleCenterCheck() {
    _centerDebounce?.cancel();
    _centerDebounce = Timer(
      const Duration(milliseconds: 180),
      _updateSearchHereState,
    );
  }

  void _updateSearchHereState() {
    // 아직 한 번도 fetch하지 않았다면 버튼은 숨김(초기/GPS/카테고리에서 자동 fetch가 들어옴)
    if (_currentCenter == null || _lastFetchedCenter == null) {
      if (_showSearchHere) {
        setState(() => _showSearchHere = false);
      }
      return;
    }

    final r = _latestViewportRadiusM ?? 0.0;
    // 줌/화면 크기에 따라 달라지는 동적 임계치 (최소 120m, 또는 화면 반경의 25%)
    final threshold = max(120.0, 0.25 * r);

    final d = _haversineMeters(
      _currentCenter!.lat,
      _currentCenter!.lng,
      _lastFetchedCenter!.lat,
      _lastFetchedCenter!.lng,
    );

    final shouldShow = d >= threshold;
    if (shouldShow != _showSearchHere) {
      setState(() => _showSearchHere = shouldShow);
    }
  }

  Future<void> _onSearchHerePressed() async {
    if (_currentCenter == null) return;
    await _reloadPins(center: _currentCenter!, category: _filter);
    setState(() {
      _lastFetchedCenter = _currentCenter;
      _showSearchHere = false;
    });
  }

  // ───────────────────────── 자동 새로고침(초기/GPS/카테고리) ─────────────────────────

  /// 앱 첫 진입: GPS 기준 지도 이동 후 1회 새로고침
  Future<void> _bootstrapInitialGpsFetch() async {
    final gps = await _tryGetGpsLatLng();
    if (gps != null) {
      await _moveMapTo(gps);
      await _reloadPins(center: gps, category: _filter);
      setState(() {
        _lastFetchedCenter = gps;
        _showSearchHere = false;
      });
      return;
    }

    // 권한 거부/실패 시: 현재 뷰포트 중심 기준 1회 새로고침
    final fallback = await _getViewportCenterViaJs();
    if (fallback != null) {
      await _reloadPins(center: fallback, category: _filter);
      setState(() {
        _lastFetchedCenter = fallback;
        _showSearchHere = false;
      });
    }
  }

  /// 좌하단 '현위치' 버튼: GPS로 지도 이동 + 1회 자동 새로고침
  Future<void> _moveToMyLocation() async {
    final gps = await _tryGetGpsLatLng();
    if (gps == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 필요합니다. 설정에서 허용해주세요.')),
        );
      }
      return;
    }

    await _moveMapTo(gps);
    await _reloadPins(center: gps, category: _filter);
    setState(() {
      _lastFetchedCenter = gps;
      _showSearchHere = false;
    });
  }

  /// 카테고리 변경: 현재 보이는 지도 중심(있으면 그 값, 없으면 마지막 검색 중심) 기준 자동 새로고침
  Future<void> _onCategoryChanged(WasteCategory? next) async {
    setState(() => _filter = next);

    final center =
        _currentCenter ?? _lastFetchedCenter ?? await _getViewportCenterViaJs();
    if (center == null) return;

    await _reloadPins(center: center, category: _filter);
    setState(() {
      _lastFetchedCenter = center;
      _showSearchHere = false;
    });
  }

  // ───────────────────────── 검색/표시 핵심 ─────────────────────────

  /// 현재 뷰포트 bounds를 JS에서 읽고, radius(m)를 계산하여 서버 질의 후 WebView 마커 갱신
  Future<void> _reloadPins({
    required LatLng center,
    WasteCategory? category,
  }) async {
    if (!_mapReady || _fetching) return;
    _fetching = true;
    try {
      // JS에서 현재 뷰포트 경계
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

      final radiusM = _radiusMetersFromBounds(
        south: south,
        west: west,
        north: north,
        east: east,
      );
      _latestViewportRadiusM = radiusM; // 최신 보관

      // 서버 조회 (필터 있으면 해당 카테고리만)
      final items = await ReportFacade.instance.search(
        centerLat: center.lat,
        centerLng: center.lng,
        radius: radiusM,
        category: category, // null이면 전체
      );

      // 최대 80개로 제한
      final top = items.take(80).toList();

      // 지도 마커 갱신
      await _controller.runJavaScript('clearMarkers();');
      for (final ReportSummary it in top) {
        final cat = it.wasteCategory.api; // enum → API 문자열
        final js = "addMarker(${it.latitude}, ${it.longitude}, '$cat');";
        await _controller.runJavaScript(js);
      }

      // 필터 재적용(안전)
      await _applyFilterToWebView();
    } catch (_) {
      // 네트워크/파싱 실패는 조용히 무시 (필요 시 로깅)
    } finally {
      _fetching = false;
    }
  }

  // ───────────────────────── JS/유틸 ─────────────────────────

  Future<void> _moveMapTo(LatLng latLng) async {
    if (!_mapReady) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await _controller.runJavaScript('setCenter(${latLng.lat}, ${latLng.lng});');
  }

  Future<LatLng?> _getViewportCenterViaJs() async {
    try {
      final boundsJson = await _controller.runJavaScriptReturningResult(
        'JSON.stringify(getBounds && getBounds())',
      );
      if (boundsJson == 'null') return null;

      final map = _parseJsonMap(boundsJson.toString());
      if (map == null) return null;

      final south = (map['south'] as num).toDouble();
      final west = (map['west'] as num).toDouble();
      final north = (map['north'] as num).toDouble();
      final east = (map['east'] as num).toDouble();

      return LatLng((south + north) / 2.0, (west + east) / 2.0);
    } catch (_) {
      return null;
    }
  }

  Future<LatLng?> _tryGetGpsLatLng() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    return LatLng(pos.latitude, pos.longitude);
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

  // 하버사인 (m)
  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    return _haversineKm(lat1, lon1, lat2, lon2) * 1000.0;
  }

  /// 뷰포트에서 보낼 반경(m) 계산:
  /// - center→NE(대각선 반쪽) 거리 사용 (화면 반경에 근접)
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
        // 선택/해제
        final next = selected ? null : value;
        await _onCategoryChanged(next);
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
    _centerDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

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
              // 새로고침 후 READY 수신 → _bootstrapInitialGpsFetch() 수행
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

          // 상단 중앙: '현 지도에서 검색' 버튼
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 72, // 제보 버튼 위 여백
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: !_showSearchHere
                  ? const SizedBox.shrink()
                  : Center(
                      child: ElevatedButton.icon(
                        key: const ValueKey('search-here-bottom'),
                        onPressed: _onSearchHerePressed,
                        icon: const Icon(Icons.refresh),
                        label: const Text('현 지도에서 검색'),
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
            ),
          ),

          // 상단: 카테고리 "표시 필터"
          Positioned(
            top: topPadding - 20,
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
