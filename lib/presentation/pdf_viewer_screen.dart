import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mercyocean/config/app_theme.dart';
import 'package:mercyocean/models/wordpress_media_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class PdfViewerScreen extends StatefulWidget {
  final WordpressMedia media;

  const PdfViewerScreen({super.key, required this.media});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();

  bool _isLoading = true;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _localPath;
  String? _error;

  bool _showBookmarks = false;
  final List<_Bookmark> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'pdf_${widget.media.id}.pdf';
      final file = File('${dir.path}/$fileName');

      if (await file.exists()) {
        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
        return;
      }

      setState(() => _isDownloading = true);
      final request = http.Request('GET', Uri.parse(widget.media.url));
      final response = await request.send();
      final total = response.contentLength ?? 0;
      int downloaded = 0;

      final sink = file.openWrite();
      await response.stream.listen((chunk) {
        sink.add(chunk);
        downloaded += chunk.length;
        if (total > 0) {
          setState(() => _downloadProgress = downloaded / total);
        }
      }).asFuture();
      await sink.close();

      setState(() {
        _localPath = file.path;
        _isLoading = false;
        _isDownloading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isDownloading = false;
      });
    }
  }

  void _addBookmark() {
    final page = _controller.pageNumber;
    if (_bookmarks.any((b) => b.page == page)) return;

    setState(() {
      _bookmarks.add(
        _Bookmark(page: page, label: 'Page $page', addedAt: DateTime.now()),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bookmarked page $page'),
        backgroundColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _jumpToBookmark(_Bookmark bookmark) {
    _controller.jumpToPage(bookmark.page);
    setState(() => _showBookmarks = false);
  }

  void _removeBookmark(_Bookmark bookmark) {
    setState(() => _bookmarks.remove(bookmark));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _buildAppBar(isDark),
      body: Stack(
        children: [
          _buildViewer(isDark),
          if (_showBookmarks) _buildBookmarkPanel(isDark),
          if (_isDownloading) _buildDownloadProgress(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      title: Text(
        widget.media.title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark_add_outlined),
          color: AppColors.gold,
          onPressed: _addBookmark,
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.bookmarks_outlined),
              color: AppColors.gold,
              onPressed: () =>
                  setState(() => _showBookmarks = !_showBookmarks),
            ),
            if (_bookmarks.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
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
      ],
    );
  }

  Widget _buildViewer(bool isDark) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.gold));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.gold, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load PDF',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() { _error = null; _isLoading = true; });
                _loadPdf();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_localPath == null) return const SizedBox.shrink();

    return SfPdfViewer.file(
      File(_localPath!),
      controller: _controller,
      canShowScrollHead: true,
      canShowScrollStatus: true,
    );
  }

  Widget _buildBookmarkPanel(bool isDark) {
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

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
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppColors.darkDivider
                        : AppColors.lightDivider,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmarks_rounded,
                      color: AppColors.gold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Bookmarks',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showBookmarks = false),
                    child:
                        Icon(Icons.close_rounded, color: textColor, size: 18),
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
                              color: isDark
                                  ? AppColors.darkIconInactive
                                  : AppColors.lightIconInactive,
                              size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'No bookmarks yet.\nTap + to add one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkSubText
                                  : AppColors.lightSubText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _bookmarks.length,
                      separatorBuilder: (_, i) => Divider(
                        color: isDark
                            ? AppColors.darkDivider
                            : AppColors.lightDivider,
                        height: 1,
                      ),
                      itemBuilder: (context, i) {
                        final bm = _bookmarks[i];
                        return ListTile(
                          leading: const Icon(Icons.bookmark_rounded,
                              color: AppColors.gold, size: 20),
                          title: Text(
                            bm.label,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            'Added ${_formatDate(bm.addedAt)}',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkSubText
                                  : AppColors.lightSubText,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            color: isDark
                                ? AppColors.darkIconInactive
                                : AppColors.lightIconInactive,
                            onPressed: () => _removeBookmark(bm),
                          ),
                          onTap: () => _jumpToBookmark(bm),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadProgress() {
    return Positioned(
      bottom: 24,
      left: 32,
      right: 32,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.goldGlow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.download_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Downloading... ${(_downloadProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _Bookmark {
  final int page;
  final String label;
  final DateTime addedAt;
  _Bookmark({required this.page, required this.label, required this.addedAt});
}
