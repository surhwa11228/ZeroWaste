import 'package:flutter/material.dart';
import '../services/board_service.dart';
import '../models/board_models.dart';

class BoardDetailScreen extends StatefulWidget {
  final String boardName;
  final String postId;
  const BoardDetailScreen({
    super.key,
    required this.boardName,
    required this.postId,
  });
  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  final _svc = BoardService.instance;
  late Future<DetailedPostResponse> _future;
  late Future<List<BoardComment>> _cFuture;
  final _input = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _svc.detail(widget.boardName, widget.postId);
    _cFuture = _svc.comments(widget.boardName, widget.postId);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _reloadComments() async {
    setState(() => _cFuture = _svc.comments(widget.boardName, widget.postId));
  }

  Future<void> _submitComment() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _svc.addComment(widget.boardName, widget.postId, content: text);
      if (!mounted) return;
      _input.clear();
      await _reloadComments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('댓글 등록 실패: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시글')),
      body: FutureBuilder<DetailedPostResponse>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _error(
              snap.error.toString(),
              onRetry: () {
                setState(
                  () => _future = _svc.detail(widget.boardName, widget.postId),
                );
              },
            );
          }
          final post = snap.data!;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      post.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${post.nickname} · ${_fmtDate(post.createdAt)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    if (post.imageUrls.isNotEmpty)
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: PageView(
                          children: post.imageUrls
                              .map(
                                (url) => ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(url, fit: BoxFit.cover),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    if (post.imageUrls.isNotEmpty) const SizedBox(height: 12),
                    Text(
                      post.content,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Text('댓글', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    FutureBuilder<List<BoardComment>>(
                      future: _cFuture,
                      builder: (context, csnap) {
                        if (csnap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (csnap.hasError) {
                          return _error(
                            '댓글 로드 실패: ${csnap.error}',
                            onRetry: _reloadComments,
                          );
                        }
                        final comments = csnap.data ?? [];
                        if (comments.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('아직 댓글이 없습니다.'),
                          );
                        }
                        return Column(
                          children: comments
                              .map(
                                (c) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(c.uid),
                                  subtitle: Text(c.content),
                                  trailing: Text(
                                    _fmtDate(c.createdAt),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0x11000000))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: '댓글을 입력하세요',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _sending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(),
                            )
                          : IconButton(
                              onPressed: _submitComment,
                              icon: const Icon(Icons.send),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _error(String msg, {required VoidCallback onRetry}) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const SizedBox(height: 80),
      const Icon(Icons.error_outline, size: 48),
      const SizedBox(height: 12),
      Center(child: Text('문제가 발생했습니다.')),
      const SizedBox(height: 8),
      Center(
        child: Text(
          msg,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('다시 시도'),
        ),
      ),
    ],
  );
}

String _fmtDate(int ts) {
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}
