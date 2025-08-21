import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../services/report_facade.dart';
import '../utils/waste_category_enum.dart';

/// 제보 작성 화면
/// - MapScreen에서 넘긴 중심 좌표(lat, lng)를 받아온다
/// - 여기서 카테고리를 선택하고, 제출 시
///   GPS + 지도좌표 + 카테고리를 API로 전송
/// - 성공 시 pop 하면서 { ok:true, lat, lng, category(api) } 반환
class ReportCreateScreen extends StatefulWidget {
  const ReportCreateScreen({super.key});

  @override
  State<ReportCreateScreen> createState() => _ReportCreateScreenState();
}

class _ReportCreateScreenState extends State<ReportCreateScreen> {
  WasteCategory? _selected;
  bool _submitting = false;
  String? _error;

  // 라벨 & 아이콘 매핑(서비스 느낌)
  static const Map<WasteCategory, (String, IconData)> _meta = {
    WasteCategory.cigaretteButt: ('담배꽁초', Icons.smoking_rooms),
    WasteCategory.generalWaste: ('일반쓰레기', Icons.delete_outline),
    WasteCategory.foodWaste: ('음식물', Icons.restaurant),
    WasteCategory.others: ('기타', Icons.more_horiz),
  };

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final lat = (args?['lat'] as num?)?.toDouble();
    final lng = (args?['lng'] as num?)?.toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('제보 작성')),
      body: SafeArea(
        child: (lat == null || lng == null)
            ? const Center(child: Text('필수 인자(지도 좌표)가 없습니다.'))
            : GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    // 위치 카드
                    _LocationCard(lat: lat, lng: lng),

                    const SizedBox(height: 16),

                    // 카테고리 섹션
                    const Text(
                      '카테고리를 선택해주세요',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CategoryGrid(
                      selected: _selected,
                      onSelected: (w) {
                        setState(() {
                          // 같은 항목 다시 누르면 선택 해제 (토글)
                          _selected = (_selected == w) ? null : w;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // 안내 섹션 (서비스 톤)
                    _InfoStrip(
                      text: '제보 시 현재 기기의 GPS 위치와 지도상의 위치(중앙 핀)가 함께 전송됩니다.',
                      icon: Icons.info_outline,
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 제출 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : () => _submit(lat, lng),
                        icon: const Icon(Icons.send),
                        label: Text(_submitting ? '제출 중...' : '제보하기'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _submit(double lat, double lng) async {
    if (_selected == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('카테고리를 선택해주세요.')));
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      // 위치 권한
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('위치 권한이 필요합니다. 설정에서 허용해주세요.');
      }

      // 현재 GPS
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // API 호출
      final created = await ReportFacade.instance.submit(
        gpsLatitude: pos.latitude,
        gpsLongitude: pos.longitude,
        selectedLat: lat,
        selectedLng: lng,
        category: _selected!, // enum
      );

      if (!mounted) return;

      // 성공 안내
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('제보가 등록되었습니다')));

      // 지도화면에서 마커를 추가할 수 있도록 결과 반환
      Navigator.pop(context, {
        'ok': true,
        'lat': lat,
        'lng': lng,
        'category': _selected!.api, // "CIGARETTE_BUTT" 등
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

/// ───────────────────────────────────────────────────────────────
/// 위젯들
/// ───────────────────────────────────────────────────────────────

class _LocationCard extends StatefulWidget {
  final double lat;
  final double lng;
  const _LocationCard({required this.lat, required this.lng});

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard> {
  String? _address; // 사람 친화 주소
  String? _addrError; // 주소 조회 에러
  bool _loading = true;

  WebViewController? _miniMapCtrl;
  bool _kakaoKeyMissing = false;

  @override
  void initState() {
    super.initState();
    _resolveAddress();
    _initMiniMap();
  }

  Future<void> _resolveAddress() async {
    setState(() {
      _loading = true;
      _addrError = null;
      _address = null;
    });
    try {
      final placemarks = await placemarkFromCoordinates(
        widget.lat,
        widget.lng,
        localeIdentifier: 'ko_KR',
      );
      if (placemarks.isEmpty) {
        setState(() {
          _addrError = '주소를 찾지 못했습니다.';
          _loading = false;
        });
        return;
      }
      final p = placemarks.first;
      final parts = <String>[
        if ((p.street ?? '').trim().isNotEmpty) p.street!,
        if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!,
        if ((p.locality ?? '').trim().isNotEmpty) p.locality!,
        if ((p.administrativeArea ?? '').trim().isNotEmpty)
          p.administrativeArea!,
      ];
      setState(() {
        _address = parts.isEmpty ? '주소 정보 없음' : parts.join(' ');
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _addrError = '주소 조회에 실패했습니다.';
        _loading = false;
      });
    }
  }

  void _initMiniMap() {
    final kakaoKey = const String.fromEnvironment(
      'KAKAO_JS_KEY',
      defaultValue: '',
    );
    if (kakaoKey.isEmpty) {
      // 키가 없으면 지도를 생략 (주소만 표시)
      _kakaoKeyMissing = true;
      debugPrint('[Kakao] KAKAO_JS_KEY 가 설정되지 않았습니다.');
      return;
    }

    final html = _buildMiniMapHtml(
      lat: widget.lat,
      lng: widget.lng,
      kakaoJsKey: kakaoKey,
    );

    _miniMapCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(html, baseUrl: 'about:blank');
  }

  String _buildMiniMapHtml({
    required double lat,
    required double lng,
    required String kakaoJsKey,
  }) {
    // 드래그/줌 비활성화 + 단일 마커만
    return '''
<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<style>
  html, body { margin:0; padding:0; height:100%; }
  #map { width:100%; height:100%; }
</style>
<script src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=$kakaoJsKey"></script>
</head>
<body>
  <div id="map"></div>
  <script>
    (function() {
      var container = document.getElementById('map');
      var center = new kakao.maps.LatLng($lat, $lng);
      var map = new kakao.maps.Map(container, {
        center: center,
        level: 3
      });
      // 인터랙션 제거(인라인 미니맵)
      map.setDraggable(false);
      map.setZoomable(false);

      var marker = new kakao.maps.Marker({ position: center });
      marker.setMap(map);
    })();
  </script>
</body>
</html>
''';
  }

  Future<void> _openInMaps() async {
    final appUri = Uri.parse('kakaomap://look?p=${widget.lat},${widget.lng}');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
      return;
    }
    final webUri = Uri.parse(
      'https://map.kakao.com/link/map/${widget.lat},${widget.lng}',
    );
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타이틀
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  '선택한 지도 위치',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 주소 (좌표는 삭제)
            if (_loading)
              const Text('주소 확인 중...', style: TextStyle(fontSize: 12))
            else if (_addrError != null)
              Text(
                _addrError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              )
            else
              Text(
                _address ?? '',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  height: 1.25,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 10),

            // 인라인 카카오 미니맵 (키 없으면 생략)
            if (!_kakaoKeyMissing && _miniMapCtrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 180, // 카드 안에서 적절한 고정 높이
                  width: double.infinity,
                  child: WebViewWidget(controller: _miniMapCtrl!),
                ),
              ),

            const SizedBox(height: 8),

            // 액션: 지도 앱 열기 (복사/새로고침 제거)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _openInMaps,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('지도 앱으로 열기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final WasteCategory? selected;
  final ValueChanged<WasteCategory> onSelected;
  const _CategoryGrid({required this.selected, required this.onSelected});

  static const Map<WasteCategory, (String, IconData)> _meta =
      _ReportCreateScreenState._meta;

  @override
  Widget build(BuildContext context) {
    // 2열 그리드 느낌(화면 폭에 따라 Wrap)
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: WasteCategory.values.map((wc) {
        final (label, icon) = _meta[wc]!;
        final isSel = selected == wc;
        return _CategoryTile(
          label: label,
          icon: icon,
          selected: isSel,
          onTap: () => onSelected(wc),
        );
      }).toList(),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? Colors.green : Colors.grey.shade400;
    final textColor = selected ? Colors.green : Colors.black87;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minWidth: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: textColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check, size: 16, color: Colors.green),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _InfoStrip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
