import 'package:flutter/material.dart';
import '../models/board_models.dart';
import '../services/board_service.dart';

class BoardListScreen extends StatefulWidget {
  const BoardListScreen({super.key});
  @override
  State<BoardListScreen> createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen> {
  late Future<PagedResult<BoardSummary>> _future;
  final _svc = BoardService.instance;

  @override
  void initState() {
    super.initState();
    _future = _svc.list(boardName: 'freeBoard');
  }

  Future<void> _reload() async {
    final f = _svc.list(boardName: 'freeBoard');
    if (!mounted) return;
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시판'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<PagedResult<BoardSummary>>(
          future: _future,
          builder: (context, snap) {
            // 로딩
            if (snap.connectionState == ConnectionState.waiting) {
              return ListView(
                children: const [
                  SizedBox(height: 200),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            // 에러
            if (snap.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 80),
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  const Center(child: Text('목록을 불러오지 못했습니다.')),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _prettyError(snap.error),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 시도'),
                    ),
                  ),
                ],
              );
            }

            final items = snap.data?.items ?? [];
            // 비어있음
            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  SizedBox(height: 120),
                  Center(child: Icon(Icons.forum_outlined, size: 48)),
                  SizedBox(height: 12),
                  Center(child: Text('게시글이 없습니다.')),
                ],
              );
            }

            // 목록
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = items[i];
                return Card(
                  child: ListTile(
                    title: Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(p.authorName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // 상세 화면으로 이동 (라우트가 있다면 교체)
                      // Navigator.pushNamed(context, '/boardDetail', arguments: p.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('상세 화면은 다음 단계에서 연결됩니다.')),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 글쓰기 화면으로 이동 (라우트가 있다면 교체)
          // Navigator.pushNamed(context, '/boardWrite');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('글쓰기 화면은 다음 단계에서 연결됩니다.')),
          );
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  const _Thumb({this.url});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: const Icon(Icons.photo_outlined),
    );
    if (url == null || url!.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

// 에러 메시지
String _prettyError(Object? e) {
  if (e == null) return '';
  final s = e.toString();
  if (s.contains('SocketException'))
    return '서버에 연결할 수 없습니다.\n네트워크나 API 주소를 확인해 주세요.';
  if (s.contains('HandshakeException'))
    return '보안 연결에 문제가 있습니다.\n서버 인증서/HTTPS 설정을 확인해 주세요.';
  return s;
}
