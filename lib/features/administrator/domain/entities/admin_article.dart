import 'package:equatable/equatable.dart';

/// Educational & announcement article entity for CMS governance.
class AdminArticle extends Equatable {
  const AdminArticle({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.authorName,
    required this.category,
    this.status = 'Published',
    this.viewsCount = 0,
    this.likesCount = 0,
    this.publishedAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String summary;
  final String content;
  final String authorName;
  final String category;
  final String status; // 'Published', 'Draft', 'Archived'
  final int viewsCount;
  final int likesCount;
  final DateTime? publishedAt;
  final DateTime createdAt;

  AdminArticle copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? authorName,
    String? category,
    String? status,
    int? viewsCount,
    int? likesCount,
    DateTime? publishedAt,
    DateTime? createdAt,
  }) {
    return AdminArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      authorName: authorName ?? this.authorName,
      category: category ?? this.category,
      status: status ?? this.status,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        summary,
        content,
        authorName,
        category,
        status,
        viewsCount,
        likesCount,
        publishedAt,
        createdAt,
      ];
}
