import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../config/app_theme.dart';

class ViewBooks extends StatefulWidget {
  final String pdfUrl;
  final String pageTitle;

  const ViewBooks({super.key, required this.pdfUrl, required this.pageTitle});

  @override
  State<ViewBooks> createState() => _ViewBooksState();
}

class _ViewBooksState extends State<ViewBooks> {
  final PdfViewerController _pdfController = PdfViewerController();
  final List<_Bookmark> _bookmarks = [];
  bool _showBookmarks = false;

  File? _cachedFile;
  bool _isLoading = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _error;

  final CancelToken _cancelToken = CancelToken();
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    _pdfController.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'book_${widget.pdfUrl.hashCode.abs()}.pdf';
      final file = File('${dir.path}/$fileName');

      if (await file.exists()) {
        if (!mounted) return;
        setState(() { _cachedFile = file; _isLoading = false; });
        return;
      }

      if (!mounted) return;
      setState(() { _isLoading = false; _isDownloading = true; });

      await Dio().download(
        widget.pdfUrl,
        file.path,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _downloadProgress = total > 0 ? received / total : 0.0;
          });
        },
      );

      if (mounted) {
        setState(() {
          _cachedFile = file;
          _isDownloading = false;
          _downloadProgress = 0.0;
        });
      }
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isDownloading = false;
        });
      }
    }
  }

  void _addBookmark() {
    final page = _pdfController.pageNumber;
    final already = _bookmarks.any((b) => b.page == page);

    if (already) {
      _showSnack('Page $page is already bookmarked');
      return;
    }

    setState(() {
      _bookmarks.add(_Bookmark(page: page, addedAt: DateTime.now()));
    });
    _showSnack('Bookmarked page $page');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Nunito')),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleBack() {
    setState(() => _isClosing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
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
                Expanded(child: _buildBody(isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.gold));
    }

    if (_isDownloading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                color: AppColors.gold,
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (b) =>
                    AppGradients.goldShimmer.createShader(b),
                child: const Text(
                  'Downloading for offline use…',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              if (_downloadProgress > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _downloadProgress,
                    color: AppColors.gold,
                    backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                    minHeight: 6,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'It will open instantly next time.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkSubText
                      : AppColors.lightSubText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.gold, size: 48),
              const SizedBox(height: 16),
              Text(
                'Could not load book',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() {
                  _error = null;
                  _isLoading = true;
                  _loadPdf();
                }),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isClosing) return const SizedBox.expand();

    return Stack(
      children: [
        SfPdfViewer.file(
          _cachedFile!,
          controller: _pdfController,
          canShowScrollHead: true,
          canShowScrollStatus: true,
        ),
        if (_showBookmarks) _buildBookmarkPanel(isDark),
      ],
    );
  }

  // ── App Bar ─────────────────────────────────────────────────
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
            onTap: _handleBack,
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

          const SizedBox(width: 12),

          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppGradients.goldShimmer.createShader(bounds),
              child: Text(
                widget.pageTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: _addBookmark,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isDark
                    ? AppShadows.cardShadowDark
                    : AppShadows.cardShadowLight,
              ),
              child: const Icon(
                Icons.bookmark_add_outlined,
                size: 18,
                color: AppColors.gold,
              ),
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            onTap: () => setState(() => _showBookmarks = !_showBookmarks),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isDark
                        ? AppShadows.cardShadowDark
                        : AppShadows.cardShadowLight,
                  ),
                  child: const Icon(
                    Icons.bookmarks_outlined,
                    size: 18,
                    color: AppColors.gold,
                  ),
                ),
                if (_bookmarks.isNotEmpty)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${_bookmarks.length}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bookmark Panel ───────────────────────────────────────────
  Widget _buildBookmarkPanel(bool isDark) {
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubText : AppColors.lightSubText;
    final divColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 260,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: divColor)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmarks_rounded,
                      color: AppColors.gold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'My Bookmarks',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showBookmarks = false),
                    child: Icon(Icons.close_rounded,
                        color: textColor, size: 18),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _bookmarks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border_rounded,
                              color: subColor, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'No bookmarks yet.\nTap + to add one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: subColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _bookmarks.length,
                      separatorBuilder: (_, i) =>
                          Divider(color: divColor, height: 1),
                      itemBuilder: (context, i) {
                        final bm = _bookmarks[i];
                        return ListTile(
                          leading: const Icon(Icons.bookmark_rounded,
                              color: AppColors.gold, size: 20),
                          title: Text(
                            'Page ${bm.page}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            '${bm.addedAt.day}/${bm.addedAt.month}/${bm.addedAt.year}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              color: subColor,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                size: 18, color: subColor),
                            onPressed: () =>
                                setState(() => _bookmarks.removeAt(i)),
                          ),
                          onTap: () {
                            _pdfController.jumpToPage(bm.page);
                            setState(() => _showBookmarks = false);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bookmark {
  final int page;
  final DateTime addedAt;
  _Bookmark({required this.page, required this.addedAt});
}
