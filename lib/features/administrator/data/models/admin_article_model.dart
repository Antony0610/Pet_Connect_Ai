import 'package:petconnect_ai/features/administrator/domain/entities/admin_article.dart';

/// Data model for AdminArticle mapping to Supabase tables.
class AdminArticleModel extends AdminArticle {
  const AdminArticleModel({
    required super.id,
    required super.title,
    required super.summary,
    required super.content,
    required super.authorName,
    required super.category,
    super.status = 'Published',
    super.viewsCount = 0,
    super.likesCount = 0,
    super.publishedAt,
    required super.createdAt,
  });

  factory AdminArticleModel.fromJson(Map<String, dynamic> json) {
    return AdminArticleModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Article',
      summary: json['summary'] as String? ?? json['caption'] as String? ?? '',
      content: json['content'] as String? ?? json['body'] as String? ?? '',
      authorName: json['author_name'] as String? ?? json['author'] as String? ?? 'Editorial Staff',
      category: json['category'] as String? ?? 'Pet Care & Health',
      status: json['status'] as String? ?? 'Published',
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory AdminArticleModel.fromEntity(AdminArticle entity) {
    return AdminArticleModel(
      id: entity.id,
      title: entity.title,
      summary: entity.summary,
      content: entity.content,
      authorName: entity.authorName,
      category: entity.category,
      status: entity.status,
      viewsCount: entity.viewsCount,
      likesCount: entity.likesCount,
      publishedAt: entity.publishedAt,
      createdAt: entity.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'title': title,
      'summary': summary,
      'content': content,
      'author_name': authorName,
      'category': category,
      'status': status,
      'views_count': viewsCount,
      'likes_count': likesCount,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
