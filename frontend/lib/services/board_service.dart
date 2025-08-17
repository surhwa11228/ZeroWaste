import 'dart:ffi';
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
  String _base(String boardName) => '/board/$boardName';
  String _detail(String boardName, String postId) =>
      '${_base(boardName)}/$postId';
  String _comments(String boardName, String postId) =>
      '${_base(boardName)}/$postId/comments';

  /// 목록: /api/board?page=&size=&q=&tag=
  Future<PagedResult<BoardSummary>> list({
    required String boardName,
    String? category,
    Long? startAfter,
  }) async {
    final res = await _dio.get(
      _base(boardName),
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
        if (startAfter != null) 'startAfter': startAfter,
      },
    );

    // 서버 페이징 응답 형태에 맞춰 파싱 (예시: content/totalElements/number/size)
    //200
    final body = res.data as Map<String, dynamic>;
    final List<Map<String, dynamic>> raw = ((body['data'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final items = raw
        .map((e) => BoardSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    // 커서 페이징: 다음 요청용 커서(필요 시 사용)
    final Long? nextStartAfter = raw.isNotEmpty
        ? (raw.last as Map)['createAt']
        : null;

    // 서버가 page/size/total 메타를 안 주므로 적당히 채워 반환
    // 프로젝트에서 커서 전용 모델이 있다면 그걸 쓰는 걸 추천!
    return PagedResult<BoardSummary>(
      items: items,
      page: 0, // 의미 없음(커서 방식)
      size: items.length, // 이번 페이지 크기
      total: items.length, // 총합을 모르면 일단 현재 페이지 크기로
      // nextCursor: nextStartAfter, // ← PagedResult에 필드가 있다면 사용
    );
  }

  /// 상세: /api/board/{postId}
  Future<BoardPost> detail(String boardName, String id) async {
    final res = await _dio.get(_detail(boardName, id));
    return BoardPost.fromJson(Map<String, dynamic>.from(res.data));
  }

  /// 작성(멀티파트): /api/board
  /// - field "post": JSON 문자열
  /// - field "images": 파일 배열 (images, images[0] 등 서버 규약에 맞춰 below)
  Future<int> create(
    String boardName,
    BoardPostCreate draft, {
    List<File>? images,
  }) async {
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
    final res = await _dio.post(_base(boardName), data: form);
    // 서버가 생성된 id를 body나 Location 헤더로 주는 패턴에 맞춰 반환
    if (res.data is Map && (res.data['postId'] != null))
      return res.data['postId'];
    // Location: /api/board/{postId}
    final loc = res.headers['location']?.first;
    if (loc != null) {
      final idStr = loc.split('/').last;
      final postId = int.tryParse(idStr);
      if (postId != null) return postId;
    }
    return 0; // 필요 시 throw로 바꿔도 OK
  }

  /// 삭제: /api/board/{postId}
  Future<void> delete(String boardName, String postId) async {
    await _dio.delete(_detail(boardName, postId));
  }

  /// 댓글 목록: /api/board/{postId}/comments
  Future<List<BoardComment>> comments(String boardName, String postId) async {
    final res = await _dio.get(_comments(boardName, postId));
    final list =
        (res.data as List?) ?? (res.data['items'] as List?) ?? const [];
    return list
        .map((e) => BoardComment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// 댓글 작성: /api/board/{postId}/comments
  Future<int> addComment(
    String boardName,
    String postId,
    String content,
  ) async {
    final res = await _dio.post(
      _comments(boardName, postId),
      data: {'content': content},
    );
    if (res.data is Map && res.data['postId'] != null)
      return res.data['postId'];
    return 0;
  }

  /// 댓글 삭제: /api/board/{postId}/comments/{commentId}
  Future<void> deleteComment(
    String boardName,
    String postId,
    int commentId,
  ) async {
    await _dio.delete('${_comments(boardName, postId)}/$commentId');
  }
}
