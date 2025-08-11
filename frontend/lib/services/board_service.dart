import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../models/board_models.dart';
import 'network.dart';

class BoardService {
  BoardService._();
  static final instance = BoardService._();
  Dio get _dio => Network().dio;

  // 엔드포인트 상수들 — 필요 시 한 곳에서만 바꾸면 됨
  static const _base = '/board';
  static String _detail(int id) => '$_base/$id';
  static String _comments(int id) => '$_base/$id/comments';

  /// 목록: /api/board?page=&size=&q=&tag=
  Future<PagedResult<BoardPost>> list({
    int page = 0,
    int size = 20,
    String? q,
    String? tag,
  }) async {
    final res = await _dio.get(
      _base,
      queryParameters: {
        'page': page,
        'size': size,
        if (q != null && q.isNotEmpty) 'q': q,
        if (tag != null && tag.isNotEmpty) 'tag': tag,
      },
    );

    // 서버 페이징 응답 형태에 맞춰 파싱 (예시: content/totalElements/number/size)
    final data = res.data;
    final List list =
        data['content'] ?? data['items'] ?? res.data as List? ?? [];
    final items = list
        .map((e) => BoardPost.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final total = data['totalElements'] ?? data['total'] ?? items.length;
    final number = data['number'] ?? page;
    final pageSize = data['size'] ?? size;

    return PagedResult(
      items: items.cast<BoardPost>(),
      page: number,
      size: pageSize,
      total: total,
    );
  }

  /// 상세: /api/board/{id}
  Future<BoardPost> detail(int id) async {
    final res = await _dio.get(_detail(id));
    return BoardPost.fromJson(Map<String, dynamic>.from(res.data));
  }

  /// 작성(멀티파트): /api/board
  /// - field "post": JSON 문자열
  /// - field "images": 파일 배열 (images, images[0] 등 서버 규약에 맞춰 below)
  Future<int> create(BoardPostCreate draft, {List<File>? images}) async {
    final fields = <String, dynamic>{};

    // JSON part ("post")
    fields['post'] = MultipartFile.fromString(
      jsonEncode(draft.toJson()),
      contentType: MediaType('application', 'json'),
      filename: 'post.json',
    );

    // 이미지들 (서버가 images 또는 files 등 어떤 키를 기대하는지에 맞춰 변경)
    if (images != null && images.isNotEmpty) {
      final files = await Future.wait(
        images.map((f) async {
          final mime = lookupMimeType(f.path) ?? 'image/jpeg';
          final parts = mime.split('/');
          return MultipartFile.fromFile(
            f.path,
            filename: f.path.split('/').last,
            contentType: MediaType(parts.first, parts.last),
          );
        }),
      );
      // 배열 키 이름은 서버 규약에 맞춰주세요. 아래는 "images" 배열을 가정.
      fields['images'] = files;
    }

    final form = FormData.fromMap(fields);
    final res = await _dio.post(_base, data: form);
    // 서버가 생성된 id를 body나 Location 헤더로 주는 패턴에 맞춰 반환
    if (res.data is Map && (res.data['id'] != null)) return res.data['id'];
    // Location: /api/board/{id}
    final loc = res.headers['location']?.first;
    if (loc != null) {
      final idStr = loc.split('/').last;
      final id = int.tryParse(idStr);
      if (id != null) return id;
    }
    return 0; // 필요 시 throw로 바꿔도 OK
  }

  /// 삭제: /api/board/{id}
  Future<void> delete(int id) async {
    await _dio.delete(_detail(id));
  }

  /// 댓글 목록: /api/board/{id}/comments
  Future<List<BoardComment>> comments(int id) async {
    final res = await _dio.get(_comments(id));
    final list =
        (res.data as List?) ?? (res.data['items'] as List?) ?? const [];
    return list
        .map((e) => BoardComment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 댓글 작성: /api/board/{id}/comments
  Future<int> addComment(int id, String content) async {
    final res = await _dio.post(_comments(id), data: {'content': content});
    if (res.data is Map && res.data['id'] != null) return res.data['id'];
    return 0;
  }

  /// 댓글 삭제: /api/board/{id}/comments/{commentId}
  Future<void> deleteComment(int id, int commentId) async {
    await _dio.delete('${_comments(id)}/$commentId');
  }
}
