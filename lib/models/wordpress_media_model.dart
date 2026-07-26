class WordpressMedia {
  final int id;
  final String title;
  final String url; // full size URL
  final String mimeType; // image/jpeg, application/pdf, etc.
  final String? caption;
  final String? altText;
  final String? description;
  final MediaSizes? sizes; // thumbnail, medium, large, full
  final int? fileSize;
  final int? width;
  final int? height;
  final String date;

  WordpressMedia({
    required this.id,
    required this.title,
    required this.url,
    required this.mimeType,
    required this.date,
    this.caption,
    this.altText,
    this.description,
    this.sizes,
    this.fileSize,
    this.width,
    this.height,
  });

  // Convenience getters
  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';
  bool get isAudio => mimeType.startsWith('audio/');
  bool get isVideo => mimeType.startsWith('video/');

  // Best URL for a given context
  String thumbnail() => sizes?.thumbnail ?? url;
  String medium() => sizes?.medium ?? url;
  String large() => sizes?.large ?? url;

  factory WordpressMedia.fromJson(Map<String, dynamic> json) {
    final details = json['media_details'] as Map<String, dynamic>?;
    final sizesMap = details?['sizes'] as Map<String, dynamic>?;

    return WordpressMedia(
      id: json['id'],
      title: json['title']?['rendered'] ?? '',
      url: json['source_url'] ?? '',
      mimeType: json['mime_type'] ?? '',
      date: json['date'] ?? '',
      caption: _stripHtml(json['caption']?['rendered']),
      altText: json['alt_text'],
      description: _stripHtml(json['description']?['rendered']),
      fileSize: details?['filesize'],
      width: details?['width'],
      height: details?['height'],
      sizes: sizesMap != null ? MediaSizes.fromJson(sizesMap) : null,
    );
  }

  // Strip HTML tags from caption/description
  static String? _stripHtml(String? html) {
    if (html == null || html.isEmpty) return null;
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

class MediaSizes {
  final String? thumbnail; // 150x150
  final String? medium; // 300px wide
  final String? mediumLarge; // 768px wide
  final String? large; // 1024px wide
  final String? full;

  MediaSizes({
    this.thumbnail,
    this.medium,
    this.mediumLarge,
    this.large,
    this.full,
  });

  factory MediaSizes.fromJson(Map<String, dynamic> json) {
    return MediaSizes(
      thumbnail: json['thumbnail']?['source_url'],
      medium: json['medium']?['source_url'],
      mediumLarge: json['medium_large']?['source_url'],
      large: json['large']?['source_url'],
      full: json['full']?['source_url'],
    );
  }
}
