class BoardPost {
  final int id;
  final String title;
  final String content;
  final String author;
  final String? imageUrl;
  final List<String> images;
  final DateTime createdAt;
  final int? commentCount;

  BoardPost({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
    this.imageUrl,
    this.images = const [],
    this.commentCount,
  });

  factory BoardPost.fromJson(Map<String, dynamic> json) => BoardPost(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    author: json['author'],
    imageUrl: json['imageUrl'],
    images:
        (json['images'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    createdAt: DateTime.parse(json['createdAt']),
    commentCount: json['commentCount'],
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
