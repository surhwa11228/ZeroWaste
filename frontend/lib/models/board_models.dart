class ApiResponse<T> {
  final int? status;
  final String? message;
  final T? data;
  ApiResponse({this.status, this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) convert,
  ) {
    return ApiResponse<T>(
      status: json['status'] as int?,
      message: json['message'] as String?,
      data: convert(json['data']),
    );
  }
}

/// 목록용 요약
class PostResponse {
  final String postId;
  final String title;
  final int createdAt; // epoch millis
  final String uid;
  final String nickname;

  PostResponse({
    required this.postId,
    required this.title,
    required this.createdAt,
    required this.uid,
    required this.nickname,
  });

  factory PostResponse.fromJson(Map<String, dynamic> json) => PostResponse(
    postId: (json['postId'] ?? '').toString(),
    title: (json['title'] ?? '') as String,
    createdAt: (json['createdAt'] ?? 0) as int,
    uid:
        (json['uid'] ?? json['userId'] ?? '')
            as String, // 서버 상세에서 userId 사용 가능성 대비
    nickname: (json['nickname'] ?? '') as String,
  );
}

/// 상세 응답 (본문/카테고리/이미지)
class DetailedPostResponse extends PostResponse {
  final String content;
  final String boardName;
  final String category;
  final List<String> imageUrls;

  DetailedPostResponse({
    required super.postId,
    required super.title,
    required super.createdAt,
    required super.uid,
    required super.nickname,
    required this.content,
    required this.boardName,
    required this.category,
    required this.imageUrls,
  });

  factory DetailedPostResponse.fromJson(Map<String, dynamic> json) =>
      DetailedPostResponse(
        postId: (json['postId'] ?? '').toString(),
        title: (json['title'] ?? '') as String,
        createdAt: (json['createdAt'] ?? 0) as int,
        uid: (json['uid'] ?? json['userId'] ?? '') as String,
        nickname: (json['nickname'] ?? '') as String,
        content: (json['content'] ?? '') as String,
        boardName: (json['boardName'] ?? '') as String,
        category: (json['category'] ?? '') as String,
        imageUrls: ((json['imageUrls'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

/// 작성/수정 응답
class PostResult {
  final String postId;
  final String postUri;
  PostResult({required this.postId, required this.postUri});

  factory PostResult.fromJson(Map<String, dynamic> json) => PostResult(
    postId: (json['postId'] ?? '').toString(),
    postUri: (json['postUri'] ?? '').toString(),
  );
}

/// 댓글(백엔드 Comment 모델과 매핑)
class BoardComment {
  final String id; // commentId가 아닌 id 필드가 저장될 수도 있어서 대비
  final String uid;
  final String content;
  final String? parentId;
  final int createdAt;

  BoardComment({
    required this.id,
    required this.uid,
    required this.content,
    required this.createdAt,
    this.parentId,
  });

  factory BoardComment.fromJson(Map<String, dynamic> json) => BoardComment(
    id: (json['id'] ?? json['commentId'] ?? '').toString(),
    uid: (json['uid'] ?? '') as String,
    content: (json['content'] ?? '') as String,
    parentId: (json['parentId'] as String?),
    createdAt:
        (json['createdAt'] ?? json['createAt'] ?? 0)
            as int, // addComment에서 createAt 사용
  );
}

/// 작성 요청
class PostRequest {
  final String title;
  final String content;
  final String category;
  PostRequest({
    required this.title,
    required this.content,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'category': category,
  };
}

/// 커서 결과(클라이언트 계산용)
class CursorPage<T> {
  final List<T> items;
  final int? nextCursor; // createdAt의 최솟값(내림차순이므로 마지막 아이템의 createdAt)
  CursorPage({required this.items, required this.nextCursor});
}
