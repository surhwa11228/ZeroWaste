class BoardSummary {
  final String id;
  final String title;
  final DateTime createdAt;
  final String authorId;
  final String authorName;

  BoardSummary({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
  });

  factory BoardSummary.fromJson(Map<String, dynamic> json) {
    return BoardSummary(
      id: json['postId'] as String,
      title: json['title'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      authorId: json['uid'] as String,
      authorName: json['nickname'] as String,
    );
  }
}

class BoardPost {
  final String id;
  final String title;
  final String content;
  final String author;
  final String? imageUrl;
  final List<String> images;
  final DateTime createdAt;

  BoardPost({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
    this.imageUrl,
    this.images = const [],
  });

  factory BoardPost.fromJson(Map<String, dynamic> json) => BoardPost(
    id: json['postId'] as String,
    title: json['title'],
    content: json['content'],
    author: json['author'],
    imageUrl: json['imageUrl'],
    images:
        (json['images'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class BoardPostCreate {
  final String title;
  final String content;
  final List<String>? tags;

  BoardPostCreate({required this.title, required this.content, this.tags});

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    if (tags != null) 'tags': tags,
  };
}

class BoardComment {
  final int id;
  final String content;
  final String author;
  final DateTime createdAt;

  BoardComment({
    required this.id,
    required this.content,
    required this.author,
    required this.createdAt,
  });

  factory BoardComment.fromJson(Map<String, dynamic> json) => BoardComment(
    id: json['id'],
    content: json['content'],
    author: json['author'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class PagedResult<T> {
  final List<T> items;
  final int page;
  final int size;
  final int total;

  PagedResult({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });
}
