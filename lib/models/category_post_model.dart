class CategoryPost {
  final int id;
  final String title;
  final String content;
  final String excerpt;
  final String slug;
  final String date;
  final String status;
  final String type;
  final String link;
  final int? featuredMediaId;
  final String? featuredImageUrl;
  final List<int> categories;
  final List<int> tags;
  final Author? author;

  CategoryPost({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.slug,
    required this.date,
    required this.status,
    required this.type,
    required this.link,
    required this.categories,
    required this.tags,
    this.featuredMediaId,
    this.featuredImageUrl,
    this.author,
  });

  factory CategoryPost.fromJson(Map<String, dynamic> json) {
    return CategoryPost(
      id: json['id'] ?? 0,
      title: json['title']?['rendered'] ?? '',
      content: json['content']?['rendered'] ?? '',
      excerpt: json['excerpt']?['rendered'] ?? '',
      slug: json['slug'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      link: json['link'] ?? '',
      featuredMediaId: json['featured_media'],
      featuredImageUrl: json['featured_media_src_url'],
      categories: List<int>.from(json['categories'] ?? []),
      tags: List<int>.from(json['tags'] ?? []),
      author: json['_embedded']?['author'] != null
          ? Author.fromJson(json['_embedded']['author'][0])
          : null,
    );
  }

  // Formatted date — e.g. "24 Apr 2026"
  String get formattedDate {
    try {
      final dt = DateTime.parse(date);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return date;
    }
  }

  // Strip HTML tags from excerpt
  String get cleanExcerpt {
    return excerpt
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}

// ── Author model ──────────────────────────────────────────────
class Author {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? description;
  final String? link;

  Author({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.description,
    this.link,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    // Avatar — use largest available size
    final avatars = json['avatar_urls'] as Map<String, dynamic>?;
    final avatarUrl = avatars?['96'] ?? avatars?['48'] ?? avatars?['24'];

    return Author(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      avatarUrl: avatarUrl,
      description: json['description'] ?? '',
      link: json['link'] ?? '',
    );
  }
}

// ── Category model ────────────────────────────────────────────
class Category {
  final int id;
  final String name;
  final String slug;
  final String description;
  final int count;
  final int? parent;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.count,
    this.parent,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      count: json['count'] ?? 0,
      parent: json['parent'],
    );
  }
}

// ── Paginated response wrapper ────────────────────────────────
class CategoryPostResponse {
  final List<CategoryPost> posts;
  final int totalPosts;
  final int totalPages;
  final int currentPage;

  CategoryPostResponse({
    required this.posts,
    required this.totalPosts,
    required this.totalPages,
    required this.currentPage,
  });

  bool get hasMorePages => currentPage < totalPages;
}
