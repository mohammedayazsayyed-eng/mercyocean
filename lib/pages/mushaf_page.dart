import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mercyocean/service/mushaf_bookmark_service.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

class MushafScreen extends StatefulWidget {
  final int initialPage;
  final int? highlightSurah;
  final int? highlightAyah;

  const MushafScreen({
    super.key,
    this.initialPage = 1,
    this.highlightSurah,
    this.highlightAyah,
  });

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  late PageController _pageController;
  late ValueNotifier<List<HighlightVerse>> _activeHighlightsNotifier;
  late ValueNotifier<String> _hizbTextNotifier;

  Timer? _highlightTimer;
  int _selectedSurah = 1;

  bool _selectionMode = false;
  final List<AyahRef> _selectedAyahs = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
    _activeHighlightsNotifier = ValueNotifier([]);

    final initialPageData = getPageData(widget.initialPage);
    final initialSurah = initialPageData.isNotEmpty
        ? initialPageData[0]['surah'] as int
        : 1;
    _selectedSurah = initialSurah;

    _hizbTextNotifier = ValueNotifier(
      '${getSurahName(initialSurah)} ${getSurahNameArabic(initialSurah)}',
    );
    if (widget.highlightSurah != null && widget.highlightAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerTemporaryHighlight(
          widget.highlightSurah!,
          widget.highlightAyah!,
          widget.initialPage,
        );
      });
    }
  }

  Color get _selectionColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.lightBlueAccent.withOpacity(0.5)
      : Colors.lightBlueAccent.withOpacity(0.4);

  void _enterSelectionMode() {
    setState(() {
      _selectionMode = true;
      _selectedAyahs.clear();
    });
  }

  void _cancelSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedAyahs.clear();
    });
    _activeHighlightsNotifier.value = [];
  }

  bool _isSelected(int surahNumber, int verseNumber) => _selectedAyahs.any(
    (a) => a.surahNumber == surahNumber && a.ayahNumber == verseNumber,
  );

  /// Long-press a line while in selection mode to add/remove it from the
  /// current bookmark selection.
  void _toggleAyahSelection(int surahNumber, int verseNumber, int page) {
    if (_isSelected(surahNumber, verseNumber)) {
      _selectedAyahs.removeWhere(
        (a) => a.surahNumber == surahNumber && a.ayahNumber == verseNumber,
      );
      _activeHighlightsNotifier.value = _activeHighlightsNotifier.value
          .where(
            (h) => !(h.surah == surahNumber && h.verseNumber == verseNumber),
          )
          .toList();
    } else {
      _selectedAyahs.add(
        AyahRef(surahNumber: surahNumber, ayahNumber: verseNumber, page: page),
      );
      _activeHighlightsNotifier.value = [
        ..._activeHighlightsNotifier.value,
        HighlightVerse(
          surah: surahNumber,
          verseNumber: verseNumber,
          page: page,
          color: _selectionColor,
        ),
      ];
    }
    setState(() {});
  }

  Future<String?> _promptBookmarkName() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Bookmark'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Optional name, e.g. Surah Yasin',
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
  }

  Future<void> _saveSelectionAsBookmark() async {
    if (_selectedAyahs.isEmpty) return;

    final label = await _promptBookmarkName();
    if (label == null) return;

    final ayahs = List<AyahRef>.from(_selectedAyahs)
      ..sort((a, b) => a.ayahNumber.compareTo(b.ayahNumber));
    await MushafBookmarkService.addBookmark(ayahs, label: label);

    final count = ayahs.length;
    _cancelSelectionMode();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bookmarked $count line${count == 1 ? '' : 's'}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _triggerTemporaryHighlight(int surah, int ayah, int page) {
    final highlightColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.amber.withOpacity(0.5)
        : Colors.amber.withOpacity(0.4);

    final newHighlight = HighlightVerse(
      surah: surah,
      verseNumber: ayah,
      page: page,
      color: highlightColor,
    );
    _activeHighlightsNotifier.value = [
      ..._activeHighlightsNotifier.value,
      newHighlight,
    ];

    _highlightTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _activeHighlightsNotifier.value = _activeHighlightsNotifier.value
            .where((h) => !(h.surah == surah && h.verseNumber == ayah))
            .toList();
      }
    });
  }

  void _goToSurah(int surahNumber) {
    final targetPage = getPageNumber(surahNumber, 1);
    _pageController.animateToPage(
      targetPage - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );

    setState(() {
      _selectedSurah = surahNumber;
    });
    _hizbTextNotifier.value =
        '${getSurahName(surahNumber)} ${getSurahNameArabic(surahNumber)}';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _activeHighlightsNotifier.dispose();
    _hizbTextNotifier.dispose();
    _highlightTimer?.cancel();
    super.dispose();
  }

  Future<void> _showAyahDetails(
    BuildContext context,
    int surahNumber,
    int verseNumber,
    int pageNumber,
  ) {
    final String surahAr = getSurahNameArabic(surahNumber);
    final int juz = getJuzNumber(surahNumber, verseNumber);
    final String revelation = getPlaceOfRevelation(surahNumber);
    final int qtr = getQuarterNumber(surahNumber, verseNumber);

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Surah   $surahAr',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Neirizi',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomSheetCard(
                    context,
                    'Ayat',
                    '$verseNumber',
                    Icons.menu_book,
                  ),
                  _buildBottomSheetCard(
                    context,
                    'Page No',
                    '$pageNumber',
                    Icons.auto_stories,
                  ),
                  _buildBottomSheetCard(
                    context,
                    'Juz',
                    '$juz',
                    Icons.pie_chart,
                  ),
                  _buildBottomSheetCard(
                    context,
                    'Revelation',
                    revelation,
                    Icons.location_on,
                  ),
                  _buildBottomSheetCard(
                    context,
                    'الربع',
                    '$qtr',
                    Icons.data_usage,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      width: 65,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight + 16,
        title: ValueListenableBuilder<String>(
          valueListenable: _hizbTextNotifier,
          builder: (context, hizbText, child) {
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedSurah,
                  isExpanded: true,
                  dropdownColor: Theme.of(context).cardColor,
                  iconEnabledColor: Theme.of(context).colorScheme.primary,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Neirizi',
                    fontSize: 16,
                  ),
                  items: List.generate(114, (index) {
                    final surahNumber = index + 1;
                    return DropdownMenuItem<int>(
                      value: surahNumber,
                      child: Text(
                        '$surahNumber. ${getSurahNameEnglish(surahNumber)} ${getSurahNameArabic(surahNumber)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Neirizi',
                          fontSize: 16,
                        ),
                      ),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      _goToSurah(value);
                    }
                  },
                  hint: Text(hizbText),
                ),
              ),
            );
          },
        ),
        centerTitle: true,
        backgroundColor: _selectionMode
            ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
            : null,
        actions: _selectionMode
            ? [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: Text(
                      '${_selectedAyahs.length} selected',
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  tooltip: 'Save bookmark',
                  onPressed: _selectedAyahs.isEmpty
                      ? null
                      : _saveSelectionAsBookmark,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel selection',
                  onPressed: _cancelSelectionMode,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined),
                  tooltip: 'Select lines to bookmark',
                  onPressed: _enterSelectionMode,
                ),
              ],
      ),
      body: SafeArea(
        child: SelectionContainer.disabled(
          child: ValueListenableBuilder<List<HighlightVerse>>(
            valueListenable: _activeHighlightsNotifier,
            builder: (context, highlights, child) {
              return QuranPageView(
                isDarkMode: isDarkMode,
                isTajweed: true,
                pageController: _pageController,
                highlights: highlights,
                ayahStyle: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
                onPageChanged: (pageNumber) {
                  final pageData = getPageData(pageNumber);
                  final currentSurah = pageData.isNotEmpty
                      ? pageData[0]['surah'] as int
                      : _selectedSurah;
                  setState(() {
                    _selectedSurah = currentSurah;
                  });
                  if (pageData.isNotEmpty) {
                    _hizbTextNotifier.value =
                        '${getSurahName(currentSurah)} ${getSurahNameArabic(currentSurah)}';
                  }
                },
                onLongPress: (surahNumber, verseNumber, details) async {
                  final currentPage = _pageController.hasClients
                      ? _pageController.page!.toInt() + 1
                      : widget.initialPage;

                  if (_selectionMode) {
                    _toggleAyahSelection(surahNumber, verseNumber, currentPage);
                    return;
                  }

                  _activeHighlightsNotifier.value = [
                    ..._activeHighlightsNotifier.value,
                    HighlightVerse(
                      surah: surahNumber,
                      verseNumber: verseNumber,
                      page: currentPage,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.amber.withOpacity(0.5)
                          : Colors.amber.withOpacity(0.4),
                    ),
                  ];

                  await _showAyahDetails(
                    context,
                    surahNumber,
                    verseNumber,
                    currentPage,
                  );

                  // Remove the highlight once the details sheet is closed
                  _activeHighlightsNotifier.value = _activeHighlightsNotifier
                      .value
                      .where(
                        (e) =>
                            e.surah != surahNumber ||
                            e.verseNumber != verseNumber,
                      )
                      .toList();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
