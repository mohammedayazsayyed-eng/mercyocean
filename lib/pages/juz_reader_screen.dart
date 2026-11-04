import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:just_audio/just_audio.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';
import 'juz_data.dart';

class JuzReaderScreen extends StatefulWidget {
  final int juz;

  const JuzReaderScreen({super.key, this.juz = 1});

  @override
  State<JuzReaderScreen> createState() => _JuzReaderScreenState();
}

class _JuzReaderScreenState extends State<JuzReaderScreen> {
  late int _juz;
  late List<JuzSegment> _segments;
  int _segmentIndex = 0;

  // A fresh controller is created every time the visible surah changes.
  ItemScrollController _itemScrollController = ItemScrollController();
  List<HighlightVerse> _highlights = [];

  // Used to keep the selected surah chip in view.
  final ScrollController _chipScrollController = ScrollController();
  late List<GlobalKey> _chipKeys;

  // --- Auto-Play State ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool _isPlaying = false;
  int _playingSurah = 0;
  int _playingAyah = 0;

  JuzSegment get _segment => _segments[_segmentIndex];

  @override
  void initState() {
    super.initState();
    _juz = widget.juz;
    _segments = juzSegments(_juz);
    _chipKeys = List.generate(_segments.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToSegmentStart());

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onAyahAudioCompleted();
      }
    });
  }

  String _ayahAudioUrl(int surahNumber, int verseNumber) {
    final surahPart = surahNumber.toString().padLeft(3, '0');
    final ayahPart = verseNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/Alafasy_128kbps/$surahPart$ayahPart.mp3';
  }

  // ---------------------------------------------------------------------------
  // Navigation inside the Juz
  // ---------------------------------------------------------------------------

  // Opens a surah portion without touching the audio (used by auto-advance).
  void _openSegment(int index) {
    setState(() {
      _segmentIndex = index;
      _itemScrollController = ItemScrollController();
      _highlights = [];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealChip(index);
      _jumpToSegmentStart();
    });
  }

  // When a Juz starts in the middle of a surah (e.g. The Cave 75-110), jump
  // straight to the first verse of the Juz so the surah banner and the hidden
  // verses above it are scrolled out of sight.
  void _jumpToSegmentStart([int attempt = 0]) {
    if (!mounted || _segment.startAyah == 1) return;
    if (_itemScrollController.isAttached) {
      _itemScrollController.jumpTo(index: _segment.startAyah);
    } else if (attempt < 5) {
      Future.delayed(
        const Duration(milliseconds: 60),
        () => _jumpToSegmentStart(attempt + 1),
      );
    }
  }

  // Called when the user taps a chip or a "Next" button.
  Future<void> _selectSegment(int index) async {
    await _stopPlay();
    if (!mounted) return;
    _openSegment(index);
  }

  Future<void> _changeJuz(int juzNo) async {
    await _stopPlay();
    if (!mounted) return;
    setState(() {
      _juz = juzNo;
      _segments = juzSegments(juzNo);
      _segmentIndex = 0;
      _chipKeys = List.generate(_segments.length, (_) => GlobalKey());
      _itemScrollController = ItemScrollController();
      _highlights = [];
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chipScrollController.hasClients) {
        _chipScrollController.jumpTo(0);
      }
      _jumpToSegmentStart();
    });
  }

  void _revealChip(int index) {
    if (index >= _chipKeys.length) return;
    final chipContext = _chipKeys[index].currentContext;
    if (chipContext != null) {
      Scrollable.ensureVisible(
        chipContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Highlight + audio
  // ---------------------------------------------------------------------------

  void _highlightAyah(int surah, int ayah) {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: ayah,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        alignment: 0.25,
      );
    }

    final highlightColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.amber.withValues(alpha: 0.5)
        : const Color(0xFF8D6E63).withValues(alpha: 0.3);

    setState(() {
      _highlights = [
        HighlightVerse(
          surah: surah,
          verseNumber: ayah,
          page: 0,
          color: highlightColor,
        ),
      ];
    });
  }

  Future<void> _togglePlay(int surah, int ayah) async {
    if (_isPlaying && _playingSurah == surah && _playingAyah == ayah) {
      await _stopPlay();
      return;
    }
    await _playAyah(surah, ayah);
  }

  Future<void> _playAyah(int surah, int ayah) async {
    _playingSurah = surah;
    _playingAyah = ayah;
    setState(() => _isPlaying = true);
    _highlightAyah(surah, ayah);

    try {
      await _audioPlayer.setUrl(_ayahAudioUrl(surah, ayah));
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        setState(() => _isPlaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to play ayah audio')),
        );
      }
    }
  }

  // Moves on to the next ayah; at the end of a surah portion it continues
  // with the next surah of the same Juz.
  Future<void> _onAyahAudioCompleted() async {
    if (!mounted || !_isPlaying) return;

    final seg = _segment;
    final nextAyah = _playingAyah + 1;

    if (_playingSurah == seg.surah && nextAyah <= seg.endAyah) {
      await _playAyah(_playingSurah, nextAyah);
      return;
    }

    if (_segmentIndex < _segments.length - 1) {
      final nextIndex = _segmentIndex + 1;
      final nextSeg = _segments[nextIndex];
      _openSegment(nextIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isPlaying) {
          _playAyah(nextSeg.surah, nextSeg.startAyah);
        }
      });
      return;
    }

    await _stopPlay();
  }

  Future<void> _stopPlay() async {
    await _audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _playingSurah = 0;
      _playingAyah = 0;
      _highlights = [];
    });
  }

  Future<void> _copyAyah(int surahNumber, int verseNumber) async {
    String text = getVerse(surahNumber, verseNumber, verseEndSymbol: true);
    text +=
        '\n\nSurah ${getSurahNameEnglish(surahNumber)} ($surahNumber:$verseNumber)';
    text += '\n\nMercy Ocean App\nNaqshabndi Sufi Order';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ayah copied')));
    }
  }

  Future<void> _shareAyah(int surahNumber, int verseNumber) async {
    final text = getVerse(surahNumber, verseNumber, verseEndSymbol: true);
    final surahName = getSurahNameEnglish(surahNumber);
    await SharePlus.instance.share(
      ShareParams(
        text:
            '$text\n\nSurah $surahName ($surahNumber:$verseNumber)\n\nMercy Ocean App\nNaqshabndi Sufi Order',
      ),
    );
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  void _showSurahSheet(Color primaryColor) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.35,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Surahs in Juz $_juz',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _segments.length,
                    itemBuilder: (context, i) {
                      final s = _segments[i];
                      final selected = i == _segmentIndex;
                      return ListTile(
                        selected: selected,
                        selectedColor: primaryColor,
                        selectedTileColor: primaryColor.withValues(alpha: 0.08),
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: primaryColor.withValues(alpha: 0.12),
                          child: Text(
                            '${s.surah}',
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        title: Text(
                          getSurahNameEnglish(s.surah),
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                        subtitle: Text(
                          s.isFullSurah
                              ? 'Full surah (${s.endAyah} ayahs)'
                              : 'Ayah ${s.startAyah} to ${s.endAyah}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                          ),
                        ),
                        trailing: Text(
                          getSurahNameArabic(s.surah),
                          style: TextStyle(
                            fontFamily: 'Neirizi',
                            fontSize: 18,
                            color: primaryColor,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          if (i != _segmentIndex) _selectSegment(i);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSegmentBar(Color primaryColor) {
    return SingleChildScrollView(
      controller: _chipScrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          for (int i = 0; i < _segments.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: _chipKeys[i],
                showCheckmark: false,
                selected: i == _segmentIndex,
                selectedColor: primaryColor,
                backgroundColor: primaryColor.withValues(alpha: 0.08),
                label: Text(
                  _segments[i].isFullSurah
                      ? getSurahNameEnglish(_segments[i].surah)
                      : '${getSurahNameEnglish(_segments[i].surah)} '
                            '${_segments[i].startAyah}-${_segments[i].endAyah}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: i == _segmentIndex ? Colors.white : primaryColor,
                  ),
                ),
                onSelected: (_) => _selectSegment(i),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seg = _segment;

    return Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _juz,
            isExpanded: true,
            dropdownColor: Theme.of(context).cardColor,
            iconEnabledColor: primaryColor,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              fontSize: 18,
            ),
            items: List.generate(kTotalJuz, (index) {
              final juzNo = index + 1;
              return DropdownMenuItem(
                value: juzNo,
                child: Text(
                  'Juz $juzNo',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    fontSize: 16,
                  ),
                ),
              );
            }),
            onChanged: (value) {
              if (value != null && value != _juz) {
                _changeJuz(value);
              }
            },
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.format_list_bulleted, color: primaryColor),
            tooltip: 'Surahs in this Juz',
            onPressed: () => _showSurahSheet(primaryColor),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isIndoPakNotifier,
            builder: (context, isIndoPak, child) {
              return IconButton(
                icon: Icon(Icons.text_format, color: primaryColor),
                tooltip: isIndoPak ? 'Switch to Uthmani' : 'Switch to IndoPak',
                onPressed: () {
                  toggleFontScript(!isIndoPak);
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSegmentBar(primaryColor),
            Expanded(
              child: QuranSurahListView(
                key: ValueKey('juz$_juz-seg$_segmentIndex'),
                surahNumber: seg.surah,
                highlights: _highlights,
                itemScrollController: _itemScrollController,
                fontSize: 25,
                initialScrollIndex: seg.startAyah == 1 ? 0 : seg.startAyah,
                isTajweed: true,
                isDarkMode: isDark,
                ayahBuilder:
                    (
                      context,
                      surahNumber,
                      verseNumber,
                      pageNumber,
                      othmanicText,
                      isHighlighted,
                      highlightColor,
                    ) {
                      // Only show the ayahs that belong to this Juz.
                      if (verseNumber < seg.startAyah ||
                          verseNumber > seg.endAyah) {
                        return const SizedBox.shrink();
                      }

                      final bool isCurrentlyPlaying =
                          _isPlaying &&
                          _playingSurah == surahNumber &&
                          _playingAyah == verseNumber;

                      final Widget card = AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? highlightColor.withValues(alpha: 0.15)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isHighlighted
                                ? highlightColor
                                : primaryColor.withValues(alpha: 0.1),
                            width: isHighlighted ? 1.5 : 1,
                          ),
                          boxShadow: [
                            if (!isDark && !isHighlighted)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.05),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'آية $verseNumber',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () => _togglePlay(
                                          surahNumber,
                                          verseNumber,
                                        ),
                                        child: Icon(
                                          isCurrentlyPlaying
                                              ? Icons.pause_circle_filled
                                              : Icons.play_circle_outline,
                                          size: 26,
                                          color: isCurrentlyPlaying
                                              ? const Color(0xFFD4AF37)
                                              : primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      InkWell(
                                        onTap: () =>
                                            _copyAyah(surahNumber, verseNumber),
                                        child: Icon(
                                          Icons.copy,
                                          size: 18,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      InkWell(
                                        onTap: () => _shareAyah(
                                          surahNumber,
                                          verseNumber,
                                        ),
                                        child: Icon(
                                          Icons.share_outlined,
                                          size: 18,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: isIndoPakNotifier,
                              builder: (context, isIndoPak, child) {
                                // Normalize hidden no-break spaces / newlines
                                final String indoPakVerse =
                                    getVerse(surahNumber, verseNumber)
                                        .replaceAll(
                                          RegExp(
                                            r'[\u00A0\u202F\u2007\u2060\uFEFF\r\n]+',
                                          ),
                                          ' ',
                                        )
                                        .trim();

                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: isIndoPak
                                      ? SizedBox(
                                          width: double.infinity,
                                          child: RichText(
                                            textAlign: TextAlign.start,
                                            textDirection: TextDirection.rtl,
                                            softWrap: true,
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontFamily: 'IndoPak',
                                                fontSize: 24,
                                                height: 2.0,
                                                color: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.color,
                                              ),
                                              children: [
                                                TextSpan(text: indoPakVerse),
                                                TextSpan(
                                                  text: ' ﴿$verseNumber﴾',
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      : othmanicText,
                                );
                              },
                            ),
                          ],
                        ),
                      );

                      // After the last ayah of this surah portion, show a
                      // button that jumps to the next surah (or the next Juz).
                      if (verseNumber != seg.endAyah) return card;

                      final bool hasNextSegment =
                          _segmentIndex < _segments.length - 1;
                      final bool hasNextJuz = _juz < kTotalJuz;
                      if (!hasNextSegment && !hasNextJuz) return card;

                      final String nextLabel = hasNextSegment
                          ? 'Next: ${getSurahNameEnglish(_segments[_segmentIndex + 1].surah)}'
                          : 'Next: Juz ${_juz + 1}';

                      return Column(
                        children: [
                          card,
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                if (hasNextSegment) {
                                  _selectSegment(_segmentIndex + 1);
                                } else {
                                  _changeJuz(_juz + 1);
                                }
                              },
                              icon: Icon(
                                Icons.arrow_forward,
                                color: primaryColor,
                              ),
                              label: Text(
                                nextLabel,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
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
