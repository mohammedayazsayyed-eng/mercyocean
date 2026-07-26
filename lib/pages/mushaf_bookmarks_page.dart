import 'package:flutter/material.dart';
import 'package:mercyocean/pages/mushaf_page.dart';
import 'package:mercyocean/service/mushaf_bookmark_service.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

class MushafBookmarksScreen extends StatefulWidget {
  const MushafBookmarksScreen({super.key});

  @override
  State<MushafBookmarksScreen> createState() => _MushafBookmarksScreenState();
}

class _MushafBookmarksScreenState extends State<MushafBookmarksScreen> {
  List<MushafBookmark> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    List<MushafBookmark> bookmarks = [];
    try {
      bookmarks = await MushafBookmarkService.getBookmarks();
    } catch (_) {
      bookmarks = [];
    }
    if (mounted) {
      setState(() {
        _bookmarks = bookmarks;
        _isLoading = false;
      });
    }
  }

  Future<void> _openBookmark(MushafBookmark bookmark) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MushafScreen(
          initialPage: bookmark.firstPage,
          highlightSurah: bookmark.ayahs.first.surahNumber,
          highlightAyah: bookmark.ayahs.first.ayahNumber,
        ),
      ),
    );
    _loadBookmarks();
  }

  Future<void> _removeBookmark(MushafBookmark bookmark) async {
    await MushafBookmarkService.removeBookmark(bookmark.id);
    _loadBookmarks();
  }

  Future<void> _renameBookmark(MushafBookmark bookmark) async {
    final controller = TextEditingController(text: bookmark.label ?? '');

    final newLabel = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Bookmark'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Surah Yasin, evening reading',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newLabel != null) {
      await MushafBookmarkService.renameBookmark(bookmark.id, newLabel);
      _loadBookmarks();
    }
  }

  String _defaultTitle(MushafBookmark bookmark) {
    final surahName = getSurahNameEnglish(bookmark.firstSurah);
    if (bookmark.ayahs.length == 1) {
      return '$surahName, Ayah ${bookmark.ayahs.first.ayahNumber}';
    }
    return '$surahName, ${bookmark.ayahs.length} Ayahs';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
    return isToday ? 'Today, $time' : '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Bookmarks',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No bookmarks yet.\nLong-press lines in the Mushaf while in selection mode to bookmark them.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = _bookmarks[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () => _openBookmark(bookmark),
                    leading: Icon(Icons.bookmark, color: primaryColor),
                    title: Text(
                      bookmark.label?.isNotEmpty == true
                          ? bookmark.label!
                          : _defaultTitle(bookmark),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    subtitle: Text(
                      'Page ${bookmark.firstPage} • ${_formatDate(bookmark.savedAt)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Rename bookmark',
                          onPressed: () => _renameBookmark(bookmark),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          tooltip: 'Remove bookmark',
                          onPressed: () => _removeBookmark(bookmark),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
