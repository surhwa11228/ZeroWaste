import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

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

  // 주소 캐시 (lat,lng → address)
  final Map<String, String> _addrCache = {};

  static const Map<WasteCategory, String> _labels = {
    WasteCategory.cigaretteButt: '담배꽁초',
    WasteCategory.generalWaste: '일반쓰레기',
    WasteCategory.foodWaste: '음식물',
    WasteCategory.others: '기타',
  };
  static const Map<WasteCategory, Color> _colors = {
    WasteCategory.cigaretteButt: Color(0xFFE53935),
    WasteCategory.generalWaste: Color(0xFF1E88E5),
    WasteCategory.foodWaste: Color(0xFF43A047),
    WasteCategory.others: Color(0xFF6D4C41),
  };

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
      // 최신순 정렬
      items.sort((a, b) {
        final da = DateTime.fromMillisecondsSinceEpoch(
          a.reportedAt.millisecondsSinceEpoch,
        );
        final db = DateTime.fromMillisecondsSinceEpoch(
          b.reportedAt.millisecondsSinceEpoch,
        );
        return db.compareTo(da);
      });
      setState(() => _items = items);
    } catch (_) {
      setState(() => _error = '제보 내역을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _addrKey(double lat, double lng) =>
      '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';

  Future<void> _ensureAddress(double lat, double lng) async {
    final key = _addrKey(lat, lng);
    if (_addrCache.containsKey(key)) return;
    try {
      final addr = await AddressResolver.reverse(lat: lat, lng: lng);
      if (!mounted) return;
      setState(() {
        _addrCache[key] = addr ?? '주소를 찾을 수 없어요';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addrCache[key] = '주소를 불러오지 못했어요';
      });
    }
  }

  Future<void> _openInKakaoMap({
    required double lat,
    required double lng,
  }) async {
    final appUri = Uri.parse('kakaomap://look?p=$lat,$lng');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri, mode: LaunchMode.externalApplication);
      return;
    }
    final webUri = Uri.parse('https://map.kakao.com/link/map/$lat,$lng');
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  void _showActions(DetailedReportSummary it) {
    final dt = DateTime.fromMillisecondsSinceEpoch(
      it.reportedAt.millisecondsSinceEpoch,
    );
    final wc = WasteCategoryCodec.fromApi(it.wasteCategory.api);
    final label = wc != null
        ? _labels[wc] ?? it.wasteCategory.api
        : it.wasteCategory.api;
    final color = wc != null ? _colors[wc]! : Colors.grey;

    final addr = _addrCache[_addrKey(it.latitude, it.longitude)];
    // 없으면 백그라운드로 로드 시작
    if (addr == null) _ensureAddress(it.latitude, it.longitude);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(radius: 12, backgroundColor: color),
                title: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${_fmtDate(dt)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 6),
              // 제보 위치 (주소)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.place_outlined, size: 18),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      addr ?? '제보 위치 불러오는 중…',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text('카카오맵으로 열기'),
                onTap: () async {
                  Navigator.pop(context);
                  await _openInKakaoMap(lat: it.latitude, lng: it.longitude);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}.${two(dt.month)}.${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : (_error != null)
        ? _ErrorState(message: _error!, onRetry: _load)
        : (_items.isEmpty)
        ? const _EmptyState()
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final it = _items[i];
                final wc = WasteCategoryCodec.fromApi(it.wasteCategory.api);
                final label = wc != null
                    ? _labels[wc] ?? it.wasteCategory.api
                    : it.wasteCategory.api;
                final color = wc != null ? _colors[wc]! : Colors.grey;

                final dt = DateTime.fromMillisecondsSinceEpoch(
                  it.reportedAt.millisecondsSinceEpoch,
                );

                final key = _addrKey(it.latitude, it.longitude);
                final addr = _addrCache[key];
                if (addr == null) {
                  // 스크롤 중 중복 요청을 막기 위해 캐시에 없을 때만 시작
                  _ensureAddress(it.latitude, it.longitude);
                }

                return ListTile(
                  onTap: () => _showActions(it),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withOpacity(.15),
                    child: Icon(Icons.place, color: color, size: 20),
                  ),
                  title: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  // 좌표 대신 "제보 위치(주소) + 날짜"
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        addr ?? '제보 위치 불러오는 중…',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fmtDate(dt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  trailing: it.hasAdditionalInfo
                      ? const Icon(Icons.info, color: Colors.green)
                      : const Icon(Icons.chevron_right),
                  isThreeLine: true,
                );
              },
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 제보'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
            onPressed: _load,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: body,
      ),
    );
  }
}

/// 카카오 로컬 API를 이용한 역지오코딩
class AddressResolver {
  static final _restKey = const String.fromEnvironment(
    'KAKAO_REST_KEY',
    defaultValue: '',
  );

  static Future<String?> reverse({
    required double lat,
    required double lng,
  }) async {
    if (_restKey.isEmpty) return null; // 키 없으면 건너뜀
    final url = Uri.parse(
      'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$lng&y=$lat',
    );
    final res = await http.get(
      url,
      headers: {'Authorization': 'KakaoAK $_restKey'},
    );
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final docs = (data['documents'] as List?) ?? const [];
    if (docs.isEmpty) return null;

    final first = docs.first as Map<String, dynamic>;
    final road = (first['road_address'] as Map?)?['address_name'] as String?;
    final lot = (first['address'] as Map?)?['address_name'] as String?;
    return road ?? lot;
  }
}

// ───────── Empty / Error States ─────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('아직 등록된 제보가 없어요.'),
            const SizedBox(height: 4),
            Text(
              '지도를 열고 첫 제보를 남겨주세요!',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
