// import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mercyocean/models/quran_model.dart';
import 'package:mercyocean/models/dua_model.dart';
import 'package:mercyocean/models/wordpress_media_model.dart';
import 'package:mercyocean/models/wordpress_post_model.dart';
import 'package:mercyocean/service/api_constant.dart';
import 'package:html/parser.dart' as hp;
import 'package:html/dom.dart' as hp;

// Helper function to check if an ayah has sajdah
// Based on Islamic tradition, there are specific ayahs where sajdah is obligatory or recommended
bool _isSajdahAyah(int surahNumber, int ayahNumber) {
  // Map of surah number to list of ayah numbers with sajdah
  const sajdahAyahs = {
    7: [206], // Al-A'raf: 206
    13: [15], // Ar-Ra'd: 15
    16: [50], // An-Nahl: 50
    17: [109], // Al-Isra: 109
    19: [58], // Maryam: 58
    22: [18, 77], // Al-Hajj: 18, 77
    25: [60], // Al-Furqan: 60
    27: [26], // An-Naml: 26
    32: [15], // As-Sajdah: 15
    38: [24], // Sad: 24
    41: [38], // Fussilat: 38
    53: [62], // An-Najm: 62
    84: [21], // Al-Inshiqaq: 21
    96: [19], // Al-Alaq: 19
  };

  return sajdahAyahs[surahNumber]?.contains(ayahNumber) ?? false;
}

String _proxyImageUrl(String imageUrl) {
  // For web platform, use CORS proxy for images from naqshbandiindia.com
  // This is a development solution - production should enable CORS on the server
  if (imageUrl.contains('naqshbandiindia.com')) {
    // Using cors-anywhere as a development proxy
    // Production: Configure WordPress server with CORS headers instead
    return 'https://cors-anywhere.herokuapp.com/$imageUrl';
  }
  return imageUrl;
}

/// Convert HTML content to use CORS proxy for image URLs
/// Development solution: Use this for local testing
/// Production: Configure server-side CORS headers instead
String addCorsProxyToHtmlContent(String htmlContent) {
  // Replace image sources to use CORS proxy for naqshbandiindia.com images
  // Using string replacement instead of regex to avoid interpolation issues
  return htmlContent.replaceAll(
    'https://www.naqshbandiindia.com/',
    'https://cors-anywhere.herokuapp.com/https://www.naqshbandiindia.com/',
  );
}

// Unified Dio client with memory-based caching for all endpoints
final Dio dio = Dio(
  BaseOptions(
    baseUrl: ApiConstant.baseApiURL,
    connectTimeout: const Duration(seconds: 30), // 30 seconds in milliseconds
    receiveTimeout: const Duration(seconds: 30), // 30 seconds in milliseconds
  ),
);

final Dio _ummahDio = Dio(
  BaseOptions(
    baseUrl: ApiConstant.ummahApiBaseURL,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    queryParameters: {'apikey': ApiConstant.ummahApiKey},
  ),
); //for UmmahAPI requests to increase performance

// Simple in-memory cache for HTTP responses
class _MemoryCache {
  final Map<String, _CacheEntry> _cache = {};

  bool isCached(String key) {
    final entry = _cache[key];
    if (entry == null) return false;

    // Check if cache has expired
    final now = DateTime.now();
    if (entry.expiresAt.isBefore(now)) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  dynamic get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    final now = DateTime.now();
    if (entry.expiresAt.isBefore(now)) {
      _cache.remove(key);
      return null;
    }
    return entry.data;
  }

  void set(String key, dynamic data, Duration duration) {
    _cache[key] = _CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(duration),
    );
  }

  void clear() {
    _cache.clear();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});
}

final _memoryCache = _MemoryCache();

class ApiService {
  /// Fetch pages with caching
  /// Uses in-memory caching for faster repeated loads
  Future<List<WordpressPost>?> getPages(String slugs) async {
    try {
      final cacheKey = 'pages_$slugs';

      // Check memory cache first
      if (_memoryCache.isCached(cacheKey)) {
        final cachedData = _memoryCache.get(cacheKey);
        if (cachedData != null) {
          log('Returning cached pages for slug: $slugs');
          return cachedData as List<WordpressPost>?;
        }
      }

      final response = await dio.get(
        ApiConstant.pageEndPoint,
        queryParameters: {'slug': slugs},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final List<WordpressPost> posts = data
            .map((json) => WordpressPost.fromJson(json))
            .toList();

        // Cache for 1 hour
        _memoryCache.set(cacheKey, posts, const Duration(hours: 1));
        return posts;
      } else {
        throw Exception("Failed to load posts");
      }
    } catch (e) {
      log('Error fetching pages: $e');
      rethrow;
    }
  }

  /// Fetch books/media with caching
  /// Supports searching by text and caches results for 1 hour
  Future<List<WordpressMedia>?> getBooks(String searchtext) async {
    try {
      final cacheKey = 'books_$searchtext';

      // Check memory cache first
      if (_memoryCache.isCached(cacheKey)) {
        final cachedData = _memoryCache.get(cacheKey);
        if (cachedData != null) {
          log('Returning cached books for search: $searchtext');
          return cachedData as List<WordpressMedia>?;
        }
      }

      final response = await dio.get(
        ApiConstant.bookEndPoint,
        queryParameters: {'search': searchtext},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final List<WordpressMedia> media = data
            .map((json) => WordpressMedia.fromJson(json))
            .toList();

        // Cache for 1 hour
        _memoryCache.set(cacheKey, media, const Duration(hours: 1));
        return media;
      } else {
        throw Exception("Failed to load books");
      }
    } catch (e) {
      log('Error fetching books: $e');
      rethrow;
    }
  }

  /// Fetch audio content with caching
  /// Caches results for 1 hour
  Future<List<WordpressMedia>?> getAudio(String searchtext) async {
    try {
      final cacheKey = 'audio_$searchtext';

      // Check memory cache first
      if (_memoryCache.isCached(cacheKey)) {
        final cachedData = _memoryCache.get(cacheKey);
        if (cachedData != null) {
          log('Returning cached audio for search: $searchtext');
          return cachedData as List<WordpressMedia>?;
        }
      }

      final response = await dio.get(
        ApiConstant.audioEndPoint,
        queryParameters: {'search': searchtext},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final List<WordpressMedia> audio = data
            .map((json) => WordpressMedia.fromJson(json))
            .toList();

        // Cache for 1 hour
        _memoryCache.set(cacheKey, audio, const Duration(hours: 1));
        return audio;
      } else {
        throw Exception("Failed to load audio");
      }
    } catch (e) {
      log('Error fetching audio: $e');
      rethrow;
    }
  }

  /// Fetch all Surahs from UmmahAPI
  // Future<List<Surah>> getAllSurahs() async {
  //   try {
  //     const cacheKey = 'quran_surahs_all';

  //     // Check memory cache first
  //     if (_memoryCache.isCached(cacheKey)) {
  //       log('Returning cached surahs');
  //       return _memoryCache.get(cacheKey) as List<Surah>;
  //     }

  //     // final response = await Dio().get(
  //     //   '${ApiConstant.ummahApiBaseURL}/quran/surahs',
  //     //   queryParameters: {'apikey': ApiConstant.ummahApiKey},
  //     // );
  //     final response = await _ummahDio.get('/quran/surahs');

  //     if (response.statusCode == 200) {
  //       final SurahListResponse surahResponse =
  //           SurahListResponse.fromUmmahApiJson(response.data);
  //       final List<Surah> surahs = surahResponse.data ?? [];

  //       // Cache for 24 hours
  //       _memoryCache.set(cacheKey, surahs, const Duration(hours: 24));
  //       return surahs;
  //     } else {
  //       throw Exception("Failed to load surahs");
  //     }
  //   } catch (e) {
  //     log('Error fetching surahs: $e');
  //     rethrow;
  //   }
  // }

  Future<List<Surah>> getAllSurahs() async {
    try {
      const cacheKey = 'quran_surahs_all';

      // Check memory cache first
      if (_memoryCache.isCached(cacheKey)) {
        log('Returning memory cached surahs');
        return _memoryCache.get(cacheKey) as List<Surah>;
      }

      // Check persistent cache
      final prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString(cacheKey);
      final int? cachedTime = prefs.getInt('${cacheKey}_time');

      if (cachedJson != null && cachedTime != null) {
        final int now = DateTime.now().millisecondsSinceEpoch;
        final bool isExpired =
            (now - cachedTime) > const Duration(hours: 24).inMilliseconds;

        if (!isExpired) {
          log('Returning persistent cached surahs');
          final List<dynamic> decoded = jsonDecode(cachedJson) as List<dynamic>;
          final List<Surah> surahs = decoded
              .map((e) => Surah.fromUmmahApiJson(e as Map<String, dynamic>))
              .toList();
          _memoryCache.set(cacheKey, surahs, const Duration(hours: 24));
          return surahs;
        }
      }

      // Fetch from API
      final response = await _ummahDio.get('/quran/surahs');

      if (response.statusCode == 200) {
        final SurahListResponse surahResponse =
            SurahListResponse.fromUmmahApiJson(response.data);
        final List<Surah> surahs = surahResponse.data ?? [];

        // Save to both caches
        _memoryCache.set(cacheKey, surahs, const Duration(hours: 24));
        await prefs.setString(
          cacheKey,
          jsonEncode(surahs.map((s) => s.toJson()).toList()),
        );
        await prefs.setInt(
          '${cacheKey}_time',
          DateTime.now().millisecondsSinceEpoch,
        );

        return surahs;
      } else {
        throw Exception("Failed to load surahs");
      }
    } catch (e) {
      log('Error fetching surahs: $e');
      rethrow;
    }
  }

  /// Fetch detailed surah with ayahs (verses) from UmmahAPI
  /// Uses English translation for better readability
  Future<SurahDetailResponse> getSurahDetail(int surahNumber) async {
    try {
      final cacheKey = 'quran_surah_$surahNumber';

      // Check memory cache first
      if (_memoryCache.isCached(cacheKey)) {
        log('Returning cached surah detail: $surahNumber');
        return _memoryCache.get(cacheKey) as SurahDetailResponse;
      }

      // final response = await Dio().get(
      //   '${ApiConstant.ummahApiBaseURL}/quran/surah/$surahNumber',
      //   queryParameters: {'apikey': ApiConstant.ummahApiKey},
      // );
      final response = await _ummahDio.get('/quran/surah/$surahNumber');

      if (response.statusCode == 200) {
        final SurahDetailResponse surahDetail =
            SurahDetailResponse.fromUmmahApiJson(response.data);

        // Cache for 24 hours
        _memoryCache.set(cacheKey, surahDetail, const Duration(hours: 24));
        return surahDetail;
      } else {
        throw Exception("Failed to load surah detail");
      }
    } catch (e) {
      log('Error fetching surah detail: $e');
      rethrow;
    }
  }

  /// Get surah with specific translation
  /// UmmahAPI returns all translations by default, so this now just calls getSurahDetail
  Future<SurahDetailResponse> getSurahWithEdition(
    int surahNumber,
    String edition,
  ) async {
    // UmmahAPI includes all translations in the main endpoint
    // So we just use getSurahDetail which already has translations
    return getSurahDetail(surahNumber);
  }

  /// Fetch surah with both Arabic text and English translation from UmmahAPI
  /// UmmahAPI already provides translations with the main endpoint
  Future<SurahDetailResponse> getSurahWithTranslation(int surahNumber) async {
    try {
      final cacheKey = 'quran_surah_${surahNumber}_with_translation';

      if (_memoryCache.isCached(cacheKey)) {
        log('Returning cached surah with translation: $surahNumber');
        return _memoryCache.get(cacheKey) as SurahDetailResponse;
      }

      // UmmahAPI returns surah with translations directly
      // final response = await Dio().get(
      //   '${ApiConstant.ummahApiBaseURL}/quran/surah/$surahNumber',
      //   queryParameters: {'apikey': ApiConstant.ummahApiKey},
      // );
      final response = await _ummahDio.get('/quran/surah/$surahNumber');

      if (response.statusCode != 200) {
        throw Exception("Failed to load surah with translation");
      }

      final surahDetail = SurahDetailResponse.fromUmmahApiJson(response.data);

      _memoryCache.set(cacheKey, surahDetail, const Duration(hours: 24));
      return surahDetail;
    } catch (e) {
      log('Error fetching surah with translation: $e');
      rethrow;
    }
  }

  /// Fetch audio recitation for a specific surah from UmmahAPI
  Future<SurahAudioResponse> getSurahAudio(
    int surahNumber, {
    String reciter = 'ar.alafasy',
  }) async {
    try {
      final cacheKey = 'quran_surah_audio_${surahNumber}_$reciter';

      if (_memoryCache.isCached(cacheKey)) {
        log('Returning cached surah audio: $surahNumber - $reciter');
        return _memoryCache.get(cacheKey) as SurahAudioResponse;
      }

      // // final response = await Dio().get(
      //   '${ApiConstant.ummahApiBaseURL}/quran/audio/$surahNumber',
      //   queryParameters: {'apikey': ApiConstant.ummahApiKey},
      // );
      final response = await _ummahDio.get('/quran/audio/$surahNumber');

      if (response.statusCode == 200) {
        final SurahAudioResponse audioResponse = SurahAudioResponse.fromJson(
          response.data,
        );

        // Cache for 24 hours
        _memoryCache.set(cacheKey, audioResponse, const Duration(hours: 24));
        return audioResponse;
      } else {
        throw Exception("Failed to load surah audio");
      }
    } catch (e) {
      log('Error fetching surah audio: $e');
      rethrow;
    }
  }

  /// Get audio URL for playing a surah
  /// Returns the audio URL for streaming
  Future<String?> getSurahAudioUrl(
    int surahNumber, {
    String reciter = 'ar.alafasy',
  }) async {
    try {
      final audioResponse = await getSurahAudio(surahNumber, reciter: reciter);
      return audioResponse.audioUrl;
    } catch (e) {
      log('Error getting surah audio URL: $e');
      return null;
    }
  }

  /// Fetch all duas from UmmahAPI
  // Future<List<Dua>> getAllDuas() async {
  //   try {
  //     const cacheKey = 'all_duas';

  //     if (_memoryCache.isCached(cacheKey)) {
  //       final cachedData = _memoryCache.get(cacheKey);
  //       if (cachedData != null) {
  //         log('Returning cached duas');
  //         return cachedData as List<Dua>;
  //       }
  //     }

  //     // Step 1: fetch all category IDs
  //     // final catResponse = await Dio().get(
  //     //   '${ApiConstant.ummahApiBaseURL}/duas/categories',
  //     // );
  //     final catResponse = await _ummahDio.get('/duas/categories');

  //     if (catResponse.statusCode != 200) {
  //       throw Exception('Failed to load dua categories');
  //     }

  //     final List<dynamic> categories =
  //         catResponse.data['data']['categories'] as List<dynamic>;

  //     // Step 2: fetch duas for each category and flatten
  //     final List<Dua> allDuas = [];

  //     for (final cat in categories) {
  //       final String categoryId = cat['id'] as String;
  //       try {
  //         // final duaResponse = await Dio().get(
  //         //   '${ApiConstant.ummahApiBaseURL}/duas/category/$categoryId',
  //         // );
  //         final duaResponse = await _ummahDio.get('/duas/category/$categoryId');
  //         if (duaResponse.statusCode == 200) {
  //           final List<dynamic> items =
  //               duaResponse.data['data']['duas'] as List<dynamic>;
  //           for (final item in items) {
  //             try {
  //               allDuas.add(Dua.fromUmmahApiJson(item as Map<String, dynamic>));
  //             } catch (e) {
  //               log('Error parsing dua: $e');
  //             }
  //           }
  //         }
  //       } catch (e) {
  //         log('Error fetching category $categoryId: $e');
  //         continue;
  //       }
  //     }

  //     _memoryCache.set(cacheKey, allDuas, const Duration(hours: 24));
  //     return allDuas;
  //   } catch (e) {
  //     log('Error fetching duas: $e');
  //     rethrow;
  //   }
  // }

  Future<List<Dua>> getAllDuas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('all_duas');
    await prefs.remove('all_duas_time'); //temporary
    try {
      const cacheKey = 'all_duas';

      // Check memory cache first
      if (_memoryCache.isCached(cacheKey)) {
        log('Returning memory cached duas');
        return _memoryCache.get(cacheKey) as List<Dua>;
      }

      // Check persistent cache
      final prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString(cacheKey);
      final int? cachedTime = prefs.getInt('${cacheKey}_time');

      if (cachedJson != null && cachedTime != null) {
        final int now = DateTime.now().millisecondsSinceEpoch;
        final bool isExpired =
            (now - cachedTime) > const Duration(hours: 24).inMilliseconds;

        if (!isExpired) {
          log('Returning persistent cached duas');
          final List<dynamic> decoded = jsonDecode(cachedJson) as List<dynamic>;
          final List<Dua> duas = decoded
              .map((e) => Dua.fromUmmahApiJson(e as Map<String, dynamic>))
              .toList();
          _memoryCache.set(cacheKey, duas, const Duration(hours: 24));
          return duas;
        }
      }

      // Fetch from API
      final catResponse = await _ummahDio.get('/duas/categories');

      if (catResponse.statusCode != 200) {
        throw Exception('Failed to load dua categories');
      }

      final List<dynamic> categories =
          catResponse.data['data']['categories'] as List<dynamic>;

      final List<Future<Response>> futures = categories.map((cat) {
        final String categoryId = cat['id'] as String;
        return _ummahDio.get('/duas/category/$categoryId');
      }).toList();

      final List<Response> responses = await Future.wait(
        futures,
        eagerError: false,
      );

      final List<Dua> allDuas = [];
      for (final response in responses) {
        if (response.statusCode == 200) {
          try {
            final List<dynamic> items =
                response.data['data']['duas'] as List<dynamic>;
            for (final item in items) {
              try {
                allDuas.add(Dua.fromUmmahApiJson(item as Map<String, dynamic>));
              } catch (e) {
                log('Error parsing dua: $e');
              }
            }
          } catch (e) {
            log('Error processing category response: $e');
          }
        }
      }

      // Save to both caches
      _memoryCache.set(cacheKey, allDuas, const Duration(hours: 24));
      await prefs.setString(
        cacheKey,
        jsonEncode(allDuas.map((d) => d.toJson()).toList()),
      );
      await prefs.setInt(
        '${cacheKey}_time',
        DateTime.now().millisecondsSinceEpoch,
      );

      return allDuas;
    } catch (e) {
      log('Error fetching duas: $e');
      rethrow;
    }
  }

  /// Fetch duas by category from UmmahAPI
  Future<List<Dua>> getDuasByCategory(String category) async {
    try {
      final cacheKey = 'duas_$category';

      // Check memory cache first
      if (_memoryCache.isCached(cacheKey)) {
        final cachedData = _memoryCache.get(cacheKey);
        if (cachedData != null) {
          log('Returning cached duas for category: $category');
          return cachedData as List<Dua>;
        }
      }

      // final response = await Dio().get(
      //   '${ApiConstant.ummahApiBaseURL}/duas/category/$category',
      //   queryParameters: {'apikey': ApiConstant.ummahApiKey},
      // );
      final response = await _ummahDio.get('/duas/category/$category');

      if (response.statusCode == 200) {
        final List<Dua> duas = [];

        try {
          // Handle different response formats
          if (response.data is List) {
            for (var item in response.data as List<dynamic>) {
              try {
                duas.add(Dua.fromUmmahApiJson(item));
              } catch (e) {
                log('Error parsing dua item: $e');
                continue;
              }
            }
          } else if (response.data is Map) {
            final duasData = response.data["data"] as List<dynamic>?;
            if (duasData != null) {
              for (var item in duasData) {
                try {
                  duas.add(Dua.fromUmmahApiJson(item));
                } catch (e) {
                  log('Error parsing dua item: $e');
                  continue;
                }
              }
            }
          }
        } catch (e) {
          log('Error processing duas: $e');
          rethrow;
        }

        // Cache for 24 hours
        _memoryCache.set(cacheKey, duas, const Duration(hours: 24));
        return duas;
      } else {
        throw Exception("Failed to load duas for category: $category");
      }
    } catch (e) {
      log('Error fetching duas by category: $e');
      rethrow;
    }
  }

  Future<List<Dua>?> getRabbanaDua(String slugs) async {
    try {
      final cacheKey = 'rabbana_dua_$slugs';

      // Check memory cache first
      if (_memoryCache.isCached(cacheKey)) {
        final cachedData = _memoryCache.get(cacheKey);
        if (cachedData != null) {
          log('Returning cached Rabbana duas for slug: $slugs');
          return cachedData as List<Dua>?;
        }
      }

      final result = await getPages(slugs);
      if (result != null && result.isNotEmpty) {
        final List<Dua> duas = result.expand((post) {
          // 1. Parse the HTML content string from the WP Page
          final document = hp.parse(post.content);
          final List<hp.Element> itemElements =
              document.body?.querySelectorAll('.dua_item').toList() ?? [];
          if (itemElements.isEmpty) {
            return [
              Dua(
                id: post.id,
                title: post.title,
                description: post.excerpt,
                duaText: post.content, // Fallback to raw content
              ),
            ];
          }
          // 3. Map each discovered dua item into an independent Dua object
          return itemElements.map((item) {
            String? textOf(String selector) {
              final text = item.querySelector(selector)?.text.trim();
              return (text == null || text.isEmpty) ? null : text;
            }

            return Dua(
              id: post.id,
              title: textOf('.dua_title') ?? '',
              description: textOf('.description') ?? '',
              duaText: textOf('.dua_arabic'),
              transliteration: textOf('.dua_traslitration'),
              duaTranslation: textOf('.dua_traslation'),
              category: textOf('.category'),
              occasion: textOf('.occasion'),
            );
          });
        }).toList();

        // Cache for 1 hour
        _memoryCache.set(cacheKey, duas, const Duration(hours: 1));
        return duas;
      } else {
        return [];
      }
    } catch (e) {
      log('Error fetching pages: $e');
      rethrow;
    }
  }
}
