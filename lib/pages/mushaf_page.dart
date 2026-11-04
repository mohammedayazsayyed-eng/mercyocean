import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mercyocean/service/mushaf_bookmark_service.dart';
import '../main.dart';
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
  int _currentPage = 1;

  bool _selectionMode = false;
  final List<AyahRef> _selectedAyahs = [];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
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
    if (isIndoPakNotifier.value) {
      if (_indoPages != null && _indoController?.hasClients == true) {
        _indoController!.animateToPage(
          _indoPageFor(surahNumber, 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
      setState(() {
        _selectedSurah = surahNumber;
      });
      _hizbTextNotifier.value =
          '${getSurahName(surahNumber)} ${getSurahNameArabic(surahNumber)}';
      return;
    }
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

  // ---------------------------------------------------------------------------
  // Script switch (Uthmani Mushaf pages <-> IndoPak reading pages)
  // ---------------------------------------------------------------------------

  void _switchScript(bool toIndoPak) {
    if (_selectionMode) _cancelSelectionMode();

    if (toIndoPak) {
      // Remember the first verse of the Uthmani page the reader is on, so the
      // IndoPak view opens at the same place.
      final data = getPageData(_currentPage);
      if (data.isNotEmpty) {
        _indoSurah = (data[0]['surah'] as num).toInt();
        _indoVerse = (data[0]['start'] as num).toInt();
      }
      _indoController?.dispose();
      _indoController = null;
    } else {
      // Back to the Uthmani page that contains the verse we were reading.
      final page = getPageNumber(_indoSurah, _indoVerse);
      final oldController = _pageController;
      _currentPage = page;
      _pageController = PageController(initialPage: page - 1);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => oldController.dispose(),
      );
    }
    toggleFontScript(toIndoPak);
  }

  void _handlePageChanged(int pageNumber) {
    _currentPage = pageNumber;
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
  }

  void _handleIndoPageChanged(int index) {
    final page = _indoPages![index];
    _indoSurah = page.firstSurah;
    _indoVerse = page.firstVerse;
    setState(() {
      _selectedSurah = page.firstSurah;
    });
    _hizbTextNotifier.value =
        '${getSurahName(page.firstSurah)} ${getSurahNameArabic(page.firstSurah)}';
  }

  static final RegExp _hiddenSpaces = RegExp(
    r'[   ⁠﻿\r\n]+',
  );

  // ---------------------------------------------------------------------------
  // IndoPak reading pages
  //
  // The whole Quran is laid out once, as real "pages": one fixed, large font
  // size, lines running edge to edge like a printed Mushaf, every page filled
  // to the bottom (no scrolling inside a page). The number of pages is
  // whatever it takes at that size, so it differs from the 604 Uthmani pages.
  // ---------------------------------------------------------------------------

  static const double _hPad = 18;
  static const double _vPad = 8;
  static const double _footerH = 30;
  static const double _targetLines = 13; // lines per page at the chosen size
  static const double _lineRatio = 1.9; // line height = font size * this

  List<_IndoPage>? _indoPages;
  String? _indoKey;
  bool _indoBuilding = false;
  PageController? _indoController;
  int _indoSurah = 1;
  int _indoVerse = 1;
  double _indoFont = 24;
  double _indoLineH = 24 * _lineRatio;

  static String _arabicDigits(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => digits[int.parse(c)]).join();
  }

  // Same banner as the Uthmani pages: the package's own surah_banner.png with
  // the surah name drawn by the package's header font.
  // Height = image height (width * 0.9 * ratio) + 8px padding top and bottom.
  static double _bannerHeight(double width) => width * 0.9 * 0.11 + 16;

  Widget _buildIndoPakBanner(int surah, double width) {
    final double headerWidth = width * 0.9;
    final double fontSize = headerWidth * 0.085;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      width: width,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image(
            image: const AssetImage(
              'assets/surah_banner.png',
              package: 'qcf_quran_plus',
            ),
            width: headerWidth,
            fit: BoxFit.contain,
          ),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: '$surah',
              style: QuranTextStyles.surahHeaderStyle(
                fontSize: fontSize,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _indoBadge(int verse, double fs) {
    final double size = fs * 0.95;
    const accent = Color(0xFFB8922A);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withOpacity(0.12),
        border: Border.all(color: accent, width: 1.3),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(2),
          // No custom font here: the IndoPak font has no Arabic-Indic digits.
          child: Text(
            _arabicDigits(verse),
            style: TextStyle(
              fontSize: fs * 0.5,
              fontWeight: FontWeight.bold,
              color: accent,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  // Index of the IndoPak page that contains (surah, verse).
  int _indoPageFor(int surah, int verse) {
    final pages = _indoPages;
    if (pages == null) return 0;
    int found = 0;
    for (int i = 0; i < pages.length; i++) {
      final p = pages[i];
      final bool startsAtOrBefore =
          p.firstSurah < surah || (p.firstSurah == surah && p.firstVerse <= verse);
      if (startsAtOrBefore) {
        found = i;
      } else {
        break;
      }
    }
    return found;
  }

  Future<void> _buildIndoPages(double w, double h) async {
    final key = '${w.round()}x${h.round()}';
    if (_indoBuilding || (_indoKey == key && _indoPages != null)) return;
    _indoBuilding = true;
    final pages = await _paginateIndoPak(w, h);
    if (!mounted) return;
    setState(() {
      _indoPages = pages;
      _indoKey = key;
      _indoBuilding = false;
      _indoController?.dispose();
      _indoController = null;
    });
  }

  // Lays the whole Quran out into pages of exactly w x h.
  Future<List<_IndoPage>> _paginateIndoPak(double w, double h) async {
    final double fs = (h / (_targetLines * _lineRatio))
        .clamp(20.0, 30.0)
        .toDouble();
    final double lineH = fs * _lineRatio;
    final double bannerH = _bannerHeight(w);
    final double bisH = lineH;
    final double badge = fs * 0.95;
    _indoFont = fs;
    _indoLineH = lineH;

    final pages = <_IndoPage>[];
    var cur = _IndoPage();
    double used = 0;

    void newPage() {
      if (cur.items.isNotEmpty) pages.add(cur);
      cur = _IndoPage();
      used = 0;
    }

    void markFirst(int surah, int verse) {
      if (cur.firstSurah == 0) {
        cur.firstSurah = surah;
        cur.firstVerse = verse;
      }
    }

    for (int s = 1; s <= totalSurahCount; s++) {
      // 1) Tokens (words and verse-end markers) of the whole surah.
      final toks = <_IndoTok>[];
      final offsets = <int>[];
      final spans = <InlineSpan>[];
      int off = 0;
      int badgeCount = 0;
      final int verses = getVerseCount(s);
      for (int v = 1; v <= verses; v++) {
        final text = getVerse(s, v).replaceAll(_hiddenSpaces, ' ').trim();
        for (final word in text.split(RegExp(r'\s+'))) {
          if (word.isEmpty) continue;
          toks.add(_IndoTok.word(word, s, v));
          offsets.add(off);
          spans.add(TextSpan(text: '$word '));
          off += word.length + 1;
        }
        toks.add(_IndoTok.badge(v, s));
        offsets.add(off);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox(width: badge, height: badge),
          ),
        );
        off += 1;
        spans.add(const TextSpan(text: ' '));
        off += 1;
        badgeCount++;
      }

      // 2) Let Flutter wrap the whole surah at the page width, then read back
      //    where every line starts.
      final tp = TextPainter(
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'IndoPak',
            fontSize: fs,
            height: _lineRatio,
          ),
          children: spans,
        ),
        textDirection: TextDirection.rtl,
      );
      tp.setPlaceholderDimensions(
        List.filled(
          badgeCount,
          PlaceholderDimensions(
            size: Size(badge, badge),
            alignment: PlaceholderAlignment.middle,
          ),
        ),
      );
      tp.layout(maxWidth: w);
      final metrics = tp.computeLineMetrics();

      final starts = <int>[];
      int o = 0;
      while (o < off) {
        final r = tp.getLineBoundary(TextPosition(offset: o));
        if (starts.isEmpty || r.start != starts.last) starts.add(r.start);
        o = r.end > o ? r.end : o + 1;
      }
      if (starts.isEmpty) starts.add(0);

      final lines = <List<_IndoTok>>[
        for (int i = 0; i < starts.length; i++) <_IndoTok>[],
      ];
      int li = 0;
      for (int i = 0; i < toks.length; i++) {
        while (li + 1 < starts.length && offsets[i] >= starts[li + 1]) {
          li++;
        }
        lines[li].add(toks[i]);
      }

      // 3) Put the banner and lines onto pages.
      final bool hasBismillah = s != 1 && s != 9;
      final double headerH = bannerH + (hasBismillah ? bisH : 0);
      // Al-Fatiha has its own page; every surah header needs room for at
      // least two lines below it.
      if (s == 2 || (used > 0 && used + headerH + 2 * lineH > h)) newPage();

      markFirst(s, 1);
      cur.items.add(_IndoItem.banner(s));
      used += bannerH;
      if (hasBismillah) {
        cur.items.add(_IndoItem.bismillah());
        used += bisH;
      }

      for (int i = 0; i < lines.length; i++) {
        if (lines[i].isEmpty) continue;
        if (used + lineH > h + 0.5) newPage();
        markFirst(lines[i].first.surah, lines[i].first.verse);
        final double fill = (i < metrics.length && w > 0)
            ? (metrics[i].width / w)
            : 1.0;
        final bool isLast = i == lines.length - 1;
        cur.items.add(
          _IndoItem.line(lines[i], justify: !isLast || fill > 0.85),
        );
        used += lineH;
      }

      // Keep the spinner alive while the Quran is being laid out.
      await Future<void>.delayed(Duration.zero);
    }
    if (cur.items.isNotEmpty) pages.add(cur);
    return pages;
  }

  Widget _buildIndoPakBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth - _hPad * 2;
        final double h = constraints.maxHeight - _vPad * 2 - _footerH;
        final String key = '${w.round()}x${h.round()}';

        if (_indoPages == null || _indoKey != key) {
          if (!_indoBuilding) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _buildIndoPages(w, h),
            );
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Preparing IndoPak pages...',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        }

        final pages = _indoPages!;
        _indoController ??= PageController(
          initialPage: _indoPageFor(_indoSurah, _indoVerse),
        );
        return PageView.builder(
          controller: _indoController,
          reverse: true,
          itemCount: pages.length,
          onPageChanged: _handleIndoPageChanged,
          itemBuilder: (context, index) => _buildIndoPage(index, w, h),
        );
      },
    );
  }

  Widget _buildIndoPage(int index, double w, double h) {
    final page = _indoPages![index];
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final double fs = _indoFont;
    final double lineH = _indoLineH;

    final wordStyle = TextStyle(
      fontFamily: 'IndoPak',
      fontSize: fs,
      height: _lineRatio,
      color: textColor,
    );

    final children = <Widget>[];
    for (final item in page.items) {
      if (item.bannerSurah != null) {
        children.add(
          SizedBox(
            width: w,
            height: _bannerHeight(w),
            child: Center(child: _buildIndoPakBanner(item.bannerSurah!, w)),
          ),
        );
      } else if (item.isBismillah) {
        children.add(
          SizedBox(
            width: w,
            height: lineH,
            child: Center(
              child: Text(
                'بِسۡمِ اللّٰهِ الرَّحۡمٰنِ الرَّحِیۡمِ',
                style: wordStyle,
              ),
            ),
          ),
        );
      } else {
        final toks = item.tokens!;
        final rowChildren = <Widget>[];
        for (int i = 0; i < toks.length; i++) {
          final t = toks[i];
          if (!item.justify && i > 0) {
            rowChildren.add(SizedBox(width: fs * 0.3));
          }
          rowChildren.add(
            t.badgeNumber != null
                ? _indoBadge(t.badgeNumber!, fs)
                : Text(t.text!, style: wordStyle),
          );
        }
        children.add(
          SizedBox(
            width: w,
            height: lineH,
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: item.justify
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              children: rowChildren,
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: w,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: _footerH,
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: primaryColor.withOpacity(0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _indoController?.dispose();
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
                ValueListenableBuilder<bool>(
                  valueListenable: isIndoPakNotifier,
                  builder: (context, isIndoPak, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Line bookmarks only work on the Uthmani page layout.
                        if (!isIndoPak)
                          IconButton(
                            icon: const Icon(Icons.bookmark_add_outlined),
                            tooltip: 'Select lines to bookmark',
                            onPressed: _enterSelectionMode,
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.text_format,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: isIndoPak
                              ? 'Switch to Uthmani (Mushaf page)'
                              : 'Switch to IndoPak',
                          onPressed: () => _switchScript(!isIndoPak),
                        ),
                      ],
                    );
                  },
                ),
              ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: isIndoPakNotifier,
          builder: (context, isIndoPak, child) {
            if (isIndoPak) return _buildIndoPakBody();
            return child!;
          },
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
                onPageChanged: _handlePageChanged,
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
      ),
    );
  }
}

/// One word or verse-end marker of the IndoPak text.
class _IndoTok {
  final String? text;
  final int? badgeNumber;
  final int surah;
  final int verse;

  const _IndoTok.word(String word, this.surah, this.verse)
    : text = word,
      badgeNumber = null;

  const _IndoTok.badge(int number, this.surah)
    : text = null,
      badgeNumber = number,
      verse = number;
}

/// Something on an IndoPak page: a surah banner, the Bismillah, or a line.
class _IndoItem {
  final int? bannerSurah;
  final bool isBismillah;
  final List<_IndoTok>? tokens;
  final bool justify;

  _IndoItem.banner(int surah)
    : bannerSurah = surah,
      isBismillah = false,
      tokens = null,
      justify = false;

  _IndoItem.bismillah()
    : bannerSurah = null,
      isBismillah = true,
      tokens = null,
      justify = false;

  _IndoItem.line(List<_IndoTok> line, {required this.justify})
    : bannerSurah = null,
      isBismillah = false,
      tokens = line;
}

class _IndoPage {
  final List<_IndoItem> items = [];
  int firstSurah = 0;
  int firstVerse = 0;
}
