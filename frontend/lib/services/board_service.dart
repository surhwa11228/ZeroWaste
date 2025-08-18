import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_project/utils/api_enveloper.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import 'network.dart';
import '../models/board_models.dart';

class BoardService {
  final _network = Network();
  BoardService._() {
    _network.init();
  }
  static final instance = BoardService._();
  Dio get _dio => _network.dio;

  // String _base(String boardName) => '/board/$boardName';
  String _post(String boardName) => '/board/$boardName/post';
  String _detail(String boardName, String postId) =>
      '/board/$boardName/$postId';
  String _update(String boardName, String postId) =>
      '/board/$boardName/update/$postId';
  String _delete(String boardName, String postId) =>
      '/board/$boardName/delete/$postId';
  String _comments(String boardName, String postId) =>
      '/board/$boardName/$postId/comments';
  String _comment(String boardName, String postId) =>
      '/board/$boardName/$postId/comment';

  /// 목록 (ApiResponse<List<PostResponse>>)
  Future<List<PostResponse>> list({
    required String boardName,
    String? category,
    int? startAfter,
  }) async {
    final res = await Network().dio.get(
      '/board/$boardName',
      queryParameters: {if (startAfter != null) 'startAfter': startAfter},
    );
    final data = res.data['data'] as List;
    return data.map((e) => PostResponse.fromJson(e)).toList();
  }

  /// 상세 (ApiResponse<DetailedPostResponse>)
  Future<DetailedPostResponse> detail(String boardName, String postId) async {
    final res = await _dio.get(_detail(boardName, postId));
    final body = res.data as Map<String, dynamic>;
    final api = ApiResponse.fromJson(
      body,
      (data) =>
          DetailedPostResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
    return api.data!;
  }

  /// 작성 (multipart) (ApiResponse<PostResult>)
  Future<PostResult> create({
    required String boardName,
    required PostRequest draft,
    List<File>? images,
  }) async {
    final fields = <String, dynamic>{};

    fields['post'] = MultipartFile.fromString(
      jsonEncode(draft.toJson()),
      contentType: MediaType('application', 'json'),
      filename: 'post.json',
    );

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
      fields['images'] = files; // 컨트롤러의 create는 images 키 사용
    }

    final form = FormData.fromMap(fields);
    final res = await _dio.post(_post(boardName), data: form);

    final data = unwrapDataMapped<PostResult>(res, PostResult.fromJson);
    return data;
  }

  /// 수정 (multipart) (ApiResponse<PostResult>)
  Future<PostResult> update(
    String boardName,
    String postId,
    PostRequest draft, {
    List<File>? images,
  }) async {
    final fields = <String, dynamic>{};

    fields['post'] = MultipartFile.fromString(
      jsonEncode(draft.toJson()),
      contentType: MediaType('application', 'json'),
      filename: 'post.json',
    );

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
      fields['image'] = files; // 컨트롤러의 update는 image 키 사용 (주의!)
    }

    final form = FormData.fromMap(fields);
    final res = await _dio.put(_update(boardName, postId), data: form);

    final body = res.data as Map<String, dynamic>;
    final api = ApiResponse.fromJson(
      body,
      (data) => PostResult.fromJson(Map<String, dynamic>.from(data as Map)),
    );
    return api.data!;
  }

  /// 삭제 (ApiResponse<Void> but 204)
  Future<void> delete(String boardName, String postId) async {
    await _dio.delete(_delete(boardName, postId));
  }

  /// 댓글 목록 (List<Comment>) – 래퍼 없이 바로 리스트 반환
  Future<List<BoardComment>> comments(String boardName, String postId) async {
    final res = await _dio.get(_comments(boardName, postId));
    final list = unwrapDataListMapped<BoardComment>(res, BoardComment.fromJson);
    return list;
    // 서버에서 Comment 클래스로 직렬화 → {id, uid, content, parentId, createdAt}
  }

  /// 댓글 작성 (PostResult) – 래퍼 없이 바로 객체 반환
  Future<PostResult> addComment(
    String boardName,
    String postId, {
    required String content,
    String? parentId,
  }) async {
    final body = {
      // uid는 서버에서 인증/대체로 주입하므로 보낼 필요 없음
      'content': content,
      'parentId': parentId,
    };
    final res = await _dio.post(_comment(boardName, postId), data: body);
    final data = unwrapDataMapped<PostResult>(res, PostResult.fromJson);
    return data;
    ;
  }

  /// 댓글 삭제 (ApiResponse<Void>)
  Future<void> deleteComment(
    String boardName,
    String postId,
    String commentId,
  ) async {
    await _dio.delete(
      '$_comments(boardName, postId)/$commentId',
    ); // not used; 아래로 교체
  }
}
