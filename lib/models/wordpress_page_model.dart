// import 'dart:convert';

class WordpressPage {
  final int id;
  final String title;
  final String content; // raw HTML
  final String excerpt;
  final String? featuredImage;

  WordpressPage({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    this.featuredImage,
  });

  factory WordpressPage.fromJson(Map<String, dynamic> json) {
    return WordpressPage(
      id: json['id'],
      title: json['title']['rendered'] ?? '',
      content: json['content']['rendered'] ?? '',
      excerpt: json['excerpt']['rendered'] ?? '',
      featuredImage: json['featured_media_src_url'],
    );
  }
}
