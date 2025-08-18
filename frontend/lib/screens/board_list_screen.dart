import 'package:flutter/material.dart';
import '../services/board_service.dart';
import '../models/board_models.dart';

/// 게시판 목록 (20개/페이지, 숫자 페이지네이션 + … 점프)
class BoardListScreen extends StatefulWidget {
  final String boardName;
  final String? category;
  const BoardListScreen({
    super.key,
    this.boardName = 'freeBoard',
    this.category,
  });

  @override
  State<BoardListScreen> createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen> {
  static const int _pageSize = 20;
  static const int _maxButtons = 7; // 하단에 표시할 최대 페이지 버튼 수

  final _svc = BoardService.instance;

  // 페이지 → 아이템들 (page는 1부터 시작)
  final Map<int, List<PostResponse>> _pageItems = {};
  // page -> hasMore(이번 페이지 뒤에 더 있는지)
  final Map<int, bool> _pageHasMore = {};
  // (커서 기반) 다음 페이지를 로드하기 위한 커서: page+1 의 시작 커서(createdAt)
  // 예: _pageCursors[1] = null (1페이지는 커서 없음), _pageCursors[2] = 1페이지 마지막 createdAt
  final Map<int, int?> _pageCursors = {1: null};

  int _currentPage = 1;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage(1);
  }

  Future<void> _loadPage(int page) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 중간 페이지 건너뛰어 점프하는 경우, 필요한 커서를 확보하기 위해
      // 앞 페이지부터 순차적으로 로드해 커서를 채워둔다.
      if (page > 1 && !_pageCursors.containsKey(page)) {
        final maxKnown = _maxKnownPage();
        for (int p = maxKnown; p < page; p++) {
          if (!_pageItems.containsKey(p)) {
            await _loadSinglePage(p);
          }
          if (_pageHasMore[p] != true) break; // 더 없으면 중단
        }
        if (!_pageCursors.containsKey(page)) {
          // 여전히 커서가 없다면 해당 페이지는 존재 X
          if (!mounted) return;
          setState(() {
            _loading = false;
            _error = '요청한 페이지가 없습니다.';
          });
          return;
        }
      }

      // 이미 캐시에 있으면 캐시 사용
      if (_pageItems.containsKey(page)) {
        if (!mounted) return;
        setState(() {
          _currentPage = page;
          _loading = false;
        });
        return;
      }

      // 실제 로드
      await _loadSinglePage(page);

      if (!mounted) return;
      setState(() {
        _currentPage = page;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadSinglePage(int page) async {
    final startAfter = _pageCursors[page]; // page 시작 커서
    final items = await _svc.list(
      boardName: widget.boardName,
      category: widget.category,
      startAfter: startAfter,
    );

    // 캐시 기록
    _pageItems[page] = items;

    // 다음 페이지 유무 판단
    final hasMore = items.length == _pageSize;
    _pageHasMore[page] = hasMore;

    // 다음 페이지 커서 준비(현재 페이지 마지막 createdAt)
    if (hasMore) {
      final nextCursor = items.isNotEmpty ? items.last.createdAt : null;
      _pageCursors[page + 1] = nextCursor;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _pageItems.clear();
      _pageHasMore.clear();
      _pageCursors
        ..clear()
        ..[1] = null;
      _currentPage = 1;
      _error = null;
    });
    await _loadPage(1);
  }

  int _minKnownPage() => 1;
  int _maxKnownPage() {
    if (_pageItems.isEmpty) return 1;
    final max = _pageItems.keys.reduce((a, b) => a > b ? a : b);
    // 마지막 로드된 페이지가 hasMore면 "다음 페이지" 버튼도 미리 한 칸 더 보이도록
    return (_pageHasMore[max] == true) ? max + 1 : max;
    // (다음 페이지 눌렀을 때 실제 로딩으로 커서를 채움)
  }

  List<int> _visiblePageButtons() {
    // 가운데에 currentPage를 두고, 최대 _maxButtons개만 보이도록 범위 계산
    final minKnown = _minKnownPage();
    final maxKnown = _maxKnownPage();

    if (maxKnown <= _maxButtons) {
      return [for (int i = minKnown; i <= maxKnown; i++) i];
    }

    int start = _currentPage - (_maxButtons ~/ 2);
    int end = _currentPage + (_maxButtons ~/ 2);

    if (start < minKnown) {
      end += (minKnown - start);
      start = minKnown;
    }
    if (end > maxKnown) {
      start -= (end - maxKnown);
      end = maxKnown;
    }

    start = start.clamp(minKnown, maxKnown);
    end = end.clamp(minKnown, maxKnown);

    return [for (int i = start; i <= end; i++) i];
  }

  @override
  Widget build(BuildContext context) {
    final items = _pageItems[_currentPage] ?? const <PostResponse>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시판'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            if (_error != null)
              MaterialBanner(
                content: Text(_error!, style: const TextStyle(fontSize: 13)),
                leading: const Icon(Icons.error_outline),
                actions: [
                  TextButton(onPressed: _refresh, child: const Text('새로고침')),
                ],
              ),
            Expanded(
              child: _loading && items.isEmpty
                  ? ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: 8,
                      itemBuilder: (_, __) => const _SkeletonTile(),
                    )
                  : (items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Icon(Icons.forum_outlined, size: 48),
                              ),
                              SizedBox(height: 12),
                              Center(child: Text('게시글이 없습니다.')),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final p = items[i];
                              return Card(
                                child: ListTile(
                                  title: Text(
                                    p.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${p.nickname} · ${_fmtDate(p.createdAt)}',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/boardDetail',
                                      arguments: {
                                        'boardName': widget.boardName,
                                        'postId': p.postId,
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          )),
            ),
            // 하단 숫자 페이지네이션 (좌우 버튼 X)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _PaginationBar(
                currentPage: _currentPage,
                isLoading: _loading,
                pages: _visiblePageButtons(),
                minKnownPage: _minKnownPage(),
                maxKnownPage: _maxKnownPage(),
                onTapPage: (p) => _loadPage(p),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(
          context,
          '/boardWrite',
          arguments: widget.boardName,
        ),
        child: const Icon(Icons.edit),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final bool isLoading;
  final List<int> pages; // 보이는 페이지 버튼들
  final int minKnownPage; // 보장된 최소 페이지 (보통 1)
  final int maxKnownPage; // 지금까지 로드/추론한 최대 페이지
  final ValueChanged<int> onTapPage;

  const _PaginationBar({
    required this.currentPage,
    required this.isLoading,
    required this.pages,
    required this.minKnownPage,
    required this.maxKnownPage,
    required this.onTapPage,
  });

  // 숫자 버튼
  Widget _numBtn(BuildContext context, int p, bool selected) {
    if (selected) {
      return FilledButton(
        onPressed: () {}, // 현재 페이지는 동작 없음
        child: Text('$p'),
      );
    }
    return OutlinedButton(
      onPressed: isLoading ? null : () => onTapPage(p),
      child: Text('$p'),
    );
  }

  // 생략(…) 버튼 — 5페이지씩 점프
  Widget _ellipsisBtn(BuildContext context, {required bool left}) {
    final target = left
        ? (currentPage - 5).clamp(minKnownPage, currentPage - 1)
        : (currentPage + 5).clamp(currentPage + 1, maxKnownPage);
    final canJump = left
        ? currentPage - 1 >= minKnownPage
        : currentPage + 1 <= maxKnownPage;
    return TextButton(
      onPressed: (!isLoading && canJump) ? () => onTapPage(target) : null,
      child: const Text('…'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showLeftEllipsis = pages.isNotEmpty && pages.first > minKnownPage;
    final showRightEllipsis = pages.isNotEmpty && pages.last < maxKnownPage;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        if (showLeftEllipsis) _ellipsisBtn(context, left: true),
        ...pages.map((p) => _numBtn(context, p, p == currentPage)),
        if (showRightEllipsis) _ellipsisBtn(context, left: false),
      ],
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();
  @override
  Widget build(BuildContext context) {
    return const ListTile(
      title: _SkeletonBox(width: double.infinity, height: 16),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 8),
        child: _SkeletonBox(width: 160, height: 12),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width, height;
  const _SkeletonBox({required this.width, required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

String _fmtDate(int ts) {
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}
