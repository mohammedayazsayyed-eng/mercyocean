import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:just_audio/just_audio.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart';

class SurahListReaderScreen extends StatefulWidget {
  final int initialSurah;
  final int? highlightAyah;

  const SurahListReaderScreen({
    super.key,
    this.initialSurah = 1,
    this.highlightAyah,
  });

  @override
  State<SurahListReaderScreen> createState() => _SurahListReaderScreenState();
}

class _SurahListReaderScreenState extends State<SurahListReaderScreen> {
  late int _selectedSurah;
  final ValueNotifier<List<HighlightVerse>> _highlightsNotifier = ValueNotifier(
    [],
  );
  final ItemScrollController _itemScrollController = ItemScrollController();

  // --- Auto-Play State ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSubscription;
  bool _isPlaying = false;
  int _currentPlayingAyah = 0;

  @override
  void initState() {
    super.initState();
    _selectedSurah = widget.initialSurah;

    if (widget.highlightAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _highlightAndScrollToAyah(widget.highlightAyah!);
      });
    }

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

  // Highlights an ayah and scrolls to it
  void _highlightAndScrollToAyah(int ayahNumber) {
    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: ayahNumber,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        alignment: 0.25,
      );
    }

    final highlightColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.amber.withValues(alpha: 0.5)
        : const Color(0xFF8D6E63).withValues(alpha: 0.3);

    _highlightsNotifier.value = [
      HighlightVerse(
        surah: _selectedSurah,
        verseNumber: ayahNumber,
        page: 0,
        color: highlightColor,
      ),
    ];
  }

  // Toggles the ayah audio playback
  Future<void> _togglePlay(int startAyah) async {
    if (_isPlaying && _currentPlayingAyah == startAyah) {
      await _stopPlay();
      return;
    }

    _currentPlayingAyah = startAyah;
    setState(() => _isPlaying = true);
    _highlightAndScrollToAyah(_currentPlayingAyah);

    try {
      await _audioPlayer.setUrl(
        _ayahAudioUrl(_selectedSurah, _currentPlayingAyah),
      );
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

  // Advances to the next Ayah once the current one finishes playing
  Future<void> _onAyahAudioCompleted() async {
    if (!mounted || !_isPlaying) return;

    final maxAyahs = getVerseCount(_selectedSurah);
    final nextAyah = _currentPlayingAyah + 1;

    if (nextAyah > maxAyahs) {
      await _stopPlay();
      return;
    }

    _currentPlayingAyah = nextAyah;
    _highlightAndScrollToAyah(_currentPlayingAyah);
    setState(() {});

    try {
      await _audioPlayer.setUrl(
        _ayahAudioUrl(_selectedSurah, _currentPlayingAyah),
      );
      await _audioPlayer.play();
    } catch (e) {
      await _stopPlay();
    }
  }

  Future<void> _stopPlay() async {
    await _audioPlayer.stop();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _currentPlayingAyah = 0;
    });
    _highlightsNotifier.value = [];
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
    _highlightsNotifier.dispose();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56.0 * MediaQuery.textScaleFactorOf(context) + 40.0,
        title: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedSurah,
              isExpanded: true,
              dropdownColor: Theme.of(context).cardColor,
              iconEnabledColor: primaryColor,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontFamily: 'Neirizi',
                fontSize: 20,
              ),
              items: List.generate(114, (index) {
                int surahNum = index + 1;
                return DropdownMenuItem(
                  value: surahNum,
                  child: Text(
                    '$surahNum. ${getSurahNameEnglish(surahNum)} ${getSurahNameArabic(surahNum)}',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Neirizi',
                      fontSize: 18,
                    ),
                  ),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  // Stop playback when switching surahs
                  _stopPlay();

                  setState(() {
                    _selectedSurah = value;
                    _highlightsNotifier.value = [];
                  });

                  if (_itemScrollController.isAttached) {
                    _itemScrollController.jumpTo(index: 0);
                  }
                }
              },
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: isIndoPakNotifier,
            builder: (context, isIndoPak, child) {
              return IconButton(
                icon: Icon(
                  Icons.text_format, // A nice font icon
                  color: primaryColor,
                ),
                tooltip: isIndoPak ? 'Switch to Uthmani' : 'Switch to IndoPak',
                onPressed: () {
                  // This flips the true/false value every time it's tapped!
                  toggleFontScript(!isIndoPak);
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: QuranSurahListView(
          surahNumber: _selectedSurah,
          highlights: _highlightsNotifier.value,
          itemScrollController: _itemScrollController,
          fontSize: 25,
          initialScrollIndex: widget.highlightAyah ?? 0,
          isTajweed: true,
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
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
                // Check if this specific Ayah is currently "playing"
                final bool isCurrentlyPlaying =
                    _isPlaying && _currentPlayingAyah == verseNumber;

                return AnimatedContainer(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
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
                                // Dynamic Play/Pause Button
                                InkWell(
                                  onTap: () => _togglePlay(verseNumber),
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
                                  onTap: () =>
                                      _shareAyah(surahNumber, verseNumber),
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
                          // Normalize hidden no-break spaces / newlines so text wraps naturally
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
                                      textAlign: TextAlign.start, // was justify
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
              },
        ),
      ),
    );
  }
}
