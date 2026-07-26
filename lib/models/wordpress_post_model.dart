// import 'dart:convert';

class WordpressPost {
  final int id;
  final String title;
  final String excerpt;
  final String content;
  final String date;
  final String? featuredImage;
  final String slug;

  WordpressPost({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.date,
    required this.slug,
    this.featuredImage,
  });

  factory WordpressPost.fromJson(Map<String, dynamic> json) {
    return WordpressPost(
      id: json['id'],
      title: json['title']['rendered'] ?? '',
      excerpt: json['excerpt']['rendered'] ?? '',
      content: json['content']['rendered'] ?? '',
      date: json['date'] ?? '',
      slug: json['slug'] ?? '',
      featuredImage: json['featured_media_src_url'],
    );
  }
}
