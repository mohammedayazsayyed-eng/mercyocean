// import 'dart:io';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

// import '../config/app_theme.dart';
// import '../service/api_service.dart';

// class DalailKhairatPage extends StatefulWidget {
//   const DalailKhairatPage({super.key});

//   @override
//   State<DalailKhairatPage> createState() => _DalailKhairatPageState();
// }

// class _DalailKhairatPageState extends State<DalailKhairatPage> {
//   final PdfViewerController _pdfController = PdfViewerController();

//   File? _cachedFile;
//   String? _networkUrl;
//   bool _isLoading = true;
//   bool _isDownloading = false;
//   double _downloadProgress = 0.0;
//   String? _error;
//   int _currentPage = 1;
//   int _totalPages = 0;

//   final List<_Bookmark> _bookmarks = [];
//   bool _showBookmarks = false;
//   bool _isClosing = false;

//   static const _prefKey = 'dalail_pdf_url';
//   static const _cacheFileName = 'dalail_khairat.pdf';

//   @override
//   void initState() {
//     super.initState();
//     _loadPdf();
//   }

//   @override
//   void dispose() {
//     _pdfController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadPdf() async {
//     if (mounted) setState(() { _isLoading = true; _error = null; });

//     final cacheFile = await _cacheFile();
//     if (await cacheFile.exists()) {
//       if (mounted) setState(() { _cachedFile = cacheFile; _isLoading = false; });
//       _refreshInBackground(cacheFile);
//       return;
//     }

//     final url = await _resolveUrl();
//     if (url == null) return;

//     if (mounted) setState(() { _isLoading = false; _isDownloading = true; });
//     await _downloadAndCache(url, cacheFile);
//   }

//   Future<File> _cacheFile() async {
//     final dir = await getApplicationDocumentsDirectory();
//     return File('${dir.path}/$_cacheFileName');
//   }

//   Future<String?> _resolveUrl() async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getString(_prefKey);
//     if (saved != null) return saved;

//     try {
//       final media = await ApiService().getBooks("Dala'il al-Khayrat");
//       if (media != null && media.isNotEmpty) {
//         final url = media[0].url;
//         await prefs.setString(_prefKey, url);
//         return url;
//       }
//       if (mounted) setState(() { _error = 'No PDF found'; _isLoading = false; });
//       return null;
//     } catch (e) {
//       if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
//       return null;
//     }
//   }

//   Future<void> _downloadAndCache(String url, File cacheFile) async {
//     try {
//       await Dio().download(
//         url,
//         cacheFile.path,
//         onReceiveProgress: (received, total) {
//           if (!mounted) return;
//           setState(() {
//             _downloadProgress = total > 0 ? received / total : 0.0;
//           });
//         },
//       );
//       if (mounted) {
//         setState(() {
//           _cachedFile = cacheFile;
//           _isDownloading = false;
//           _downloadProgress = 0.0;
//         });
//       }
//     } catch (_) {
//       if (mounted) {
//         setState(() { _networkUrl = url; _isDownloading = false; });
//       }
//     }
//   }

//   Future<void> _refreshInBackground(File cacheFile) async {
//     try {
//       final media = await ApiService().getBooks("Dala'il al-Khayrat");
//       if (media == null || media.isEmpty) return;
//       final newUrl = media[0].url;
//       final prefs = await SharedPreferences.getInstance();
//       final savedUrl = prefs.getString(_prefKey);
//       if (newUrl == savedUrl) return;
//       await prefs.setString(_prefKey, newUrl);
//       await _downloadAndCache(newUrl, cacheFile);
//     } catch (_) {}
//   }

//   Future<void> _retry() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_prefKey);
//     final cacheFile = await _cacheFile();
//     if (await cacheFile.exists()) await cacheFile.delete();
//     _loadPdf();
//   }

//   void _addBookmark() {
//     final already = _bookmarks.any((b) => b.page == _currentPage);
//     if (already) {
//       _showSnack('Page $_currentPage is already bookmarked');
//       return;
//     }
//     setState(() {
//       _bookmarks.add(_Bookmark(page: _currentPage, addedAt: DateTime.now()));
//     });
//     _showSnack('Bookmarked page $_currentPage');
//   }

//   void _showSnack(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(fontFamily: 'Nunito')),
//         backgroundColor: AppColors.gold,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   void _handleBack() {
//     setState(() => _isClosing = true);
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) Navigator.pop(context);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return PopScope(
//       canPop: false,
//       onPopInvokedWithResult: (didPop, _) {
//         if (!didPop) _handleBack();
//       },
//       child: Scaffold(
//         body: Container(
//           decoration: BoxDecoration(
//             gradient: isDark
//                 ? AppGradients.darkBackground
//                 : AppGradients.lightBackground,
//           ),
//           child: SafeArea(
//             child: Column(
//               children: [
//                 _buildAppBar(context, isDark),
//                 Expanded(child: _buildBody(isDark)),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAppBar(BuildContext context, bool isDark) {
//     return Container(
//       decoration: BoxDecoration(
//         color: isDark ? AppColors.darkNavBar : AppColors.lightNavBar,
//         borderRadius: const BorderRadius.only(
//           bottomLeft: Radius.circular(24),
//           bottomRight: Radius.circular(24),
//         ),
//         boxShadow: isDark
//             ? AppShadows.navBarShadowDark
//             : AppShadows.navBarShadowLight,
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: Row(
//         children: [
//           GestureDetector(
//             onTap: _handleBack,
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: isDark
//                     ? AppShadows.cardShadowDark
//                     : AppShadows.cardShadowLight,
//               ),
//               child: Icon(
//                 Icons.arrow_back_ios_new_rounded,
//                 size: 18,
//                 color: isDark ? AppColors.darkText : AppColors.lightText,
//               ),
//             ),
//           ),

//           const SizedBox(width: 12),

//           Expanded(
//             child: ShaderMask(
//               shaderCallback: (bounds) =>
//                   AppGradients.goldShimmer.createShader(bounds),
//               child: const Text(
//                 'Dalail Ul Khairat',
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   fontFamily: 'Poppins',
//                   fontSize: 18,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),

//           const SizedBox(width: 8),

//           GestureDetector(
//             onTap: _addBookmark,
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: isDark
//                     ? AppShadows.cardShadowDark
//                     : AppShadows.cardShadowLight,
//               ),
//               child: const Icon(
//                 Icons.bookmark_add_outlined,
//                 size: 18,
//                 color: AppColors.gold,
//               ),
//             ),
//           ),

//           const SizedBox(width: 8),

//           GestureDetector(
//             onTap: () => setState(() => _showBookmarks = !_showBookmarks),
//             child: Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: isDark
//                         ? AppColors.darkSurface
//                         : AppColors.lightSurface,
//                     borderRadius: BorderRadius.circular(12),
//                     boxShadow: isDark
//                         ? AppShadows.cardShadowDark
//                         : AppShadows.cardShadowLight,
//                   ),
//                   child: const Icon(
//                     Icons.bookmarks_outlined,
//                     size: 18,
//                     color: AppColors.gold,
//                   ),
//                 ),
//                 if (_bookmarks.isNotEmpty)
//                   Positioned(
//                     top: -4,
//                     right: -4,
//                     child: Container(
//                       width: 16,
//                       height: 16,
//                       decoration: const BoxDecoration(
//                         color: AppColors.gold,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Center(
//                         child: Text(
//                           '${_bookmarks.length}',
//                           style: const TextStyle(
//                             fontSize: 9,
//                             fontWeight: FontWeight.w700,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBody(bool isDark) {
//     if (_isLoading) {
//       return const Center(
//           child: CircularProgressIndicator(color: AppColors.gold));
//     }

//     if (_isDownloading) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 40),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(
//                 value: _downloadProgress > 0 ? _downloadProgress : null,
//                 color: AppColors.gold,
//                 strokeWidth: 3,
//               ),
//               const SizedBox(height: 20),
//               ShaderMask(
//                 shaderCallback: (b) =>
//                     AppGradients.goldShimmer.createShader(b),
//                 child: const Text(
//                   'Downloading for offline use…',
//                   style: TextStyle(
//                     fontFamily: 'Nunito',
//                     fontSize: 14,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//               if (_downloadProgress > 0) ...[
//                 const SizedBox(height: 12),
//                 Text(
//                   '${(_downloadProgress * 100).toStringAsFixed(0)}%',
//                   style: const TextStyle(
//                     fontFamily: 'Nunito',
//                     fontSize: 22,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.gold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(4),
//                   child: LinearProgressIndicator(
//                     value: _downloadProgress,
//                     color: AppColors.gold,
//                     backgroundColor: AppColors.gold.withValues(alpha: 0.15),
//                     minHeight: 6,
//                   ),
//                 ),
//               ],
//               const SizedBox(height: 12),
//               Text(
//                 'Please wait…',
//                 style: TextStyle(
//                   fontFamily: 'Nunito',
//                   fontSize: 12,
//                   color: isDark
//                       ? AppColors.darkSubText
//                       : AppColors.lightSubText,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     if (_error != null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(32),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error_outline, color: AppColors.gold, size: 48),
//               const SizedBox(height: 16),
//               Text(
//                 _error!,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontFamily: 'Nunito',
//                   fontSize: 14,
//                   color: isDark ? AppColors.darkText : AppColors.lightText,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               ElevatedButton(
//                   onPressed: _retry, child: const Text('Try Again')),
//             ],
//           ),
//         ),
//       );
//     }

//     if (_isClosing) return const SizedBox.expand();

//     if (_cachedFile != null || _networkUrl != null) {
//       return _buildPdfViewer(isDark);
//     }

//     return const SizedBox.shrink();
//   }

//   Widget _buildBookmarkPanel(bool isDark) {
//     final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
//     final textColor = isDark ? AppColors.darkText : AppColors.lightText;
//     final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;
//     final divColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

//     return Positioned(
//       top: 0,
//       right: 0,
//       bottom: 0,
//       width: 260,
//       child: Container(
//         decoration: BoxDecoration(
//           color: bgColor,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.2),
//               blurRadius: 16,
//               offset: const Offset(-4, 0),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 border: Border(bottom: BorderSide(color: divColor)),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.bookmarks_rounded,
//                       color: AppColors.gold, size: 18),
//                   const SizedBox(width: 8),
//                   Text(
//                     'My Bookmarks',
//                     style: TextStyle(
//                       fontFamily: 'Nunito',
//                       fontWeight: FontWeight.w700,
//                       color: textColor,
//                     ),
//                   ),
//                   const Spacer(),
//                   GestureDetector(
//                     onTap: () => setState(() => _showBookmarks = false),
//                     child: Icon(Icons.close_rounded,
//                         color: textColor, size: 18),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: _bookmarks.isEmpty
//                   ? Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.bookmark_border_rounded,
//                               color: subColor, size: 40),
//                           const SizedBox(height: 12),
//                           Text(
//                             'No bookmarks yet.\nTap + to add one.',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               fontFamily: 'Nunito',
//                               fontSize: 13,
//                               color: subColor,
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   : ListView.separated(
//                       padding: const EdgeInsets.symmetric(vertical: 8),
//                       itemCount: _bookmarks.length,
//                       separatorBuilder: (_, i) =>
//                           Divider(color: divColor, height: 1),
//                       itemBuilder: (context, i) {
//                         final bm = _bookmarks[i];
//                         return ListTile(
//                           leading: const Icon(Icons.bookmark_rounded,
//                               color: AppColors.gold, size: 20),
//                           title: Text(
//                             'Page ${bm.page}',
//                             style: TextStyle(
//                               fontFamily: 'Nunito',
//                               fontSize: 13,
//                               fontWeight: FontWeight.w600,
//                               color: textColor,
//                             ),
//                           ),
//                           subtitle: Text(
//                             '${bm.addedAt.day}/${bm.addedAt.month}/${bm.addedAt.year}',
//                             style: TextStyle(
//                               fontFamily: 'Nunito',
//                               fontSize: 11,
//                               color: subColor,
//                             ),
//                           ),
//                           trailing: IconButton(
//                             icon: Icon(Icons.delete_outline_rounded,
//                                 size: 18, color: subColor),
//                             onPressed: () =>
//                                 setState(() => _bookmarks.removeAt(i)),
//                           ),
//                           onTap: () {
//                             _pdfController.jumpToPage(bm.page);
//                             setState(() => _showBookmarks = false);
//                           },
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPdfViewer(bool isDark) {
//     final viewer = _cachedFile != null
//         ? SfPdfViewer.file(
//             _cachedFile!,
//             controller: _pdfController,
//             canShowScrollHead: true,
//             canShowScrollStatus: true,
//             onDocumentLoaded: (details) {
//               if (!mounted) return;
//               setState(() => _totalPages = _pdfController.pageCount);
//             },
//             onPageChanged: (details) {
//               if (!mounted) return;
//               setState(() => _currentPage = details.newPageNumber);
//             },
//           )
//         : SfPdfViewer.network(
//             _networkUrl!,
//             controller: _pdfController,
//             canShowScrollHead: true,
//             canShowScrollStatus: true,
//             onDocumentLoaded: (details) {
//               if (!mounted) return;
//               setState(() => _totalPages = _pdfController.pageCount);
//             },
//             onPageChanged: (details) {
//               if (!mounted) return;
//               setState(() => _currentPage = details.newPageNumber);
//             },
//           );

//     return Stack(
//       children: [
//         Column(
//           children: [
//             Expanded(child: viewer),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
//                 boxShadow: isDark
//                     ? AppShadows.cardShadowDark
//                     : AppShadows.cardShadowLight,
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   IconButton(
//                     onPressed: _currentPage > 1
//                         ? () => _pdfController.previousPage()
//                         : null,
//                     icon: Icon(
//                       Icons.chevron_left_rounded,
//                       color: _currentPage > 1
//                           ? AppColors.gold
//                           : AppColors.gold.withValues(alpha: 0.3),
//                       size: 28,
//                     ),
//                     padding: EdgeInsets.zero,
//                     constraints: const BoxConstraints(),
//                   ),
//                   Text(
//                     _totalPages > 0
//                         ? '$_currentPage / $_totalPages'
//                         : '$_currentPage',
//                     style: TextStyle(
//                       fontFamily: 'Nunito',
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                       color: isDark ? AppColors.darkText : AppColors.lightText,
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: _totalPages == 0 || _currentPage < _totalPages
//                         ? () => _pdfController.nextPage()
//                         : null,
//                     icon: Icon(
//                       Icons.chevron_right_rounded,
//                       color: (_totalPages == 0 || _currentPage < _totalPages)
//                           ? AppColors.gold
//                           : AppColors.gold.withValues(alpha: 0.3),
//                       size: 28,
//                     ),
//                     padding: EdgeInsets.zero,
//                     constraints: const BoxConstraints(),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         if (_showBookmarks) _buildBookmarkPanel(isDark),
//       ],
//     );
//   }
// }

// class _Bookmark {
//   final int page;
//   final DateTime addedAt;
//   _Bookmark({required this.page, required this.addedAt});
// }

import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'dalail_section_page.dart';

class DalailKhairatPage extends StatelessWidget {
  const DalailKhairatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      {'title': 'How to Read', 'slug': 'method-to-read-dalail-al-khayrat'},

      {
        'title': 'Opening dua',
        'slug': 'app-openning-dua-for-dalail-al-khayrat',
      },

      {'title': 'Asma ul-Husna', 'slug': 'app-asma-ul-husna'},
      {'title': 'Asma an-Nabi', 'slug': 'app-asma-an-nabi'},
      {'title': 'Monday (first Part)', 'slug': 'app-first-part-monday'},
      {
        'title': 'Monday (Last Part)',
        'slug': 'app-monday-last-part-dalail-al-khayrat',
      },
      {'title': 'Tuesday', 'slug': 'app-tuesday-dalail-al-khayrat'},
      {'title': 'Wednesday', 'slug': 'app-wednesday-dalail-al-khayrat'},
      {'title': 'Thursday', 'slug': 'app-thursday-dalail-al-khayrat'},
      {'title': 'Friday', 'slug': 'app-friday-dalail-al-khayrat'},

      {'title': 'Saturday', 'slug': 'app-saturday-dalail-al-khayrat'},
      {'title': 'Sunday', 'slug': 'app-sunday-dalail-al-khayrat'},
      {'title': 'Completion Dua', 'slug': 'app-dua-of-completion'},
    ];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppGradients.darkBackground
              : AppGradients.lightBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, isDark),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => Divider(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    return _buildItem(
                      context,
                      isDark,
                      items[index]['title']!,
                      items[index]['slug']!,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNavBar : AppColors.lightNavBar,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: isDark
            ? AppShadows.navBarShadowDark
            : AppShadows.navBarShadowLight,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isDark
                    ? AppShadows.cardShadowDark
                    : AppShadows.cardShadowLight,
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),
          const Spacer(),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppGradients.goldShimmer.createShader(bounds),
            child: const Text(
              'Dalail al-Khayrat',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    bool isDark,
    String title,
    String slug,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DalailSectionPage(title: title, slug: slug),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppGradients.goldShimmer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
            ),
          ],
        ),
      ),
    );
  }
}
