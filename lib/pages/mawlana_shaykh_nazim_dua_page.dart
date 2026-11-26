import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:just_audio/just_audio.dart';
import '../models/wordpress_post_model.dart';
import '../service/api_service.dart';
import '../config/app_theme.dart';

enum _DuaDisplayMode { transliteration, arabic, translation }

class _DuaSegment {
  final Duration startTime;
  final String enHtml;
  final String arHtml;
  final String trHtml;

  const _DuaSegment({
    required this.startTime,
    required this.enHtml,
    required this.arHtml,
    required this.trHtml,
  });
}

class MawlanaShaykhNazimDuaPage extends StatefulWidget {
  const MawlanaShaykhNazimDuaPage({super.key});

  @override
  State<MawlanaShaykhNazimDuaPage> createState() =>
      _MawlanaShaykhNazimDuaPageState();
}

class _MawlanaShaykhNazimDuaPageState extends State<MawlanaShaykhNazimDuaPage> {
  // Uses local offline MP3 by default.
  // To stream from WordPress/Cloudflare instead, paste the https:// URL here:
  static const String _audioSource = 'assets/audio/mawlana_shaykh_nazim_dua.mp3';

  // Estimated/placeholder start timestamps (in seconds) for each of the 22 Dua paragraphs — tune as desired
  static const List<int> _segmentSeconds = [
    0, 8, 22, 40, 60, 76, 100, 142, 167, 189, 215,
    243, 272, 288, 323, 339, 371, 390, 407, 423, 454, 479,
  ];

  // English translations for each of the 22 Dua segments
  static const List<String> _segmentTranslations = [
    'Glory be to my Lord, the Most High, the Supreme, the Bestower. In the name of Allah, the Most Gracious, the Most Merciful.',
    'O our Lord, to You belongs all praise—a praise everlasting with Your eternity. Glory be to You; we cannot count the praise due to You; You are as You have praised Yourself.',
    'O Allah, send blessings upon our Master Muhammad—the opener of what was closed, the seal of what came before, the helper of truth by truth, and the guide to Your straight path—and upon his family according to his true worth and immense standing.',
    'O Allah, O Most Merciful of the merciful, O Allah, O Most Merciful of the merciful, O Allah, O Most Merciful of the merciful, O Security of the fearful, O Hope of those who ask.',
    'O our Lord and Lord of everything, our Lord, accept from us; truly You are the All-Hearing, the All-Knowing. Turn to us in mercy, O our Master; truly You are the Ever-Relenting, the Most Merciful. Guide us and grant us success toward the truth and toward a straight path.',
    'By the blessing of completing the Mighty Qurʾan, and by the blessing of reciting the Mawlid of our noble Prophet, and by the sanctity of the One whom You sent as a mercy to all worlds, pardon us, O Most Generous, and forgive our sins through Your grace, munificence, and generosity, O Most Generous of the generous and O Most Merciful of the merciful, Āmīn.',
    'O Allah, we ask You by the rank of Your noble Prophet and by the rank of the Mighty Qurʾan to grant us complete faith, true certainty, a humble heart, a tongue in constant remembrance, abundant, lawful, and wholesome provision, radiant light, righteous children, accepted righteous deeds, and trade that will never fail. O Light of light, O Knower of what is in the chests, bring us out, O Allah, from darkness into light.',
    'And we ask You, O our Lord, for sincere repentance, repentance before death, ease at the moment of death, forgiveness and mercy after death, pardon at the reckoning, attainment of Paradise, and salvation from the Fire—by Your mercy, O Almighty, O Oft-Forgiving, O Generous, O Concealer of faults.',
    'O Allah, convey and deliver the reward of what we have read and the nobility of what we have recited, after acceptance from us, as a gift reaching the presence of Your Beloved, our Master Muhammad, master of the first and the last—whom You sent as a mercy to all worlds and an intercessor for sinners.',
    'Then to the souls of his noble family and Companions—may Allah the Most High be pleased with them all. Then to the souls of his brothers among the prophets and messengers—may Allah\'s blessings and peace be upon our Prophet and upon them all—and to the souls of those who served their sacred laws. Then to the souls of the four mujtahid Imams, beacons of the religion.',
    'And to the souls of our shaykhs in the exalted Naqshbandi Tariqa, and to the souls of all our masters and the masters of the Khwājagān—especially to the soul of the Imam of the Tariqa and Ghawth of creation, Khwājah Bahāʾ ad-Dīn an-Naqshband Muḥammad al-Uwaysī al-Bukhārī, and the presence of our master, Sulṭān al-Awliyāʾ ʿAbdullāh ad-Dāghistānī.',
    'And to the souls of our fathers, mothers, sons, daughters, brothers, sisters, grandfathers, grandmothers, paternal uncles, paternal aunts, maternal uncles, and maternal aunts, and all our martyrs, strangers/travelers, and the oppressed among the sayyids and nobles. And single out, O Allah, Your late servant Darwīsh Pāshā—may Allah\'s vast mercy be upon him.',
    'And encompass in Your generosity all the deceased among believing men and women and Muslim men and women from east to west, one and all, and to the souls of Ahl al-ʿAbāʾ, our household, and the truthful (Ṣiddīqiyyūn).',
    'O Allah, forgive my sins and my parents, and have mercy upon them as they raised me when I was small, and upon all believing men and women and Muslim men and women, living and deceased, and link us and them with goodness. My Lord, forgive and have mercy, for You are the Best of the merciful. Forgive us and our brothers and sisters who preceded us in faith, and place no rancor in our hearts toward those who believe; our Lord, truly You are Most Compassionate, Most Merciful.',
    'O Allah, strengthen Islam and the Muslims, and exalt the word of truth and the monotheists through the appearance of Allah\'s Khalīfah, al-Mahdī. O Allah, grant him a mighty victory and open for him a near conquest. O Allah, appoint for us from Yourself a protector, and appoint for us from Yourself a supporting authority.',
    'O Allah, we seek refuge in You from worry and grief, from incapacity and laziness, from cowardice and miserliness, from being overwhelmed by debt and subjugated by men, from the trial of al-Masīḥ ad-Dajjāl, and from severe trials, reaching misery, evil decree, and the gloating of enemies—by the sanctity of the One whom You sent as a mercy to all worlds.',
    'O Allah, send blessings and peace upon Muhammad and the family of Muhammad—a prayer by which You save us from all terrors and afflictions, fulfill for us all needs, purify us from all evil deeds, raise us to the highest ranks, and bring us to the furthest goals of all good things in life and after death.',
    'O Allah, mend the affairs of the Ummah of Muhammad, forgive the Ummah of Muhammad, have mercy upon the Ummah of Muhammad, and protect the Ummah of Muhammad (ﷺ).',
    'O Most Merciful of the merciful, have mercy upon us; O Most Merciful of the merciful, pardon us; O Most Merciful of the merciful, O Forgiver of sins, Eternal Bestower of grace, Reviver of bones, Concealer of shortcomings, and Opener of hearts.',
    'O Allah, give us rain that brings relief—wholesome, easy to swallow, abundant, pouring down, widespread, enveloping, and enduring. O Allah, give us rain and do not make us among those who despair. O Allah, make crops grow for us, make milk flow abundantly for us, water us from the blessings of the sky, and bring forth for us from the blessings of the earth. O Helper, help us; O Helper, help us; O Helper, help us—answer our supplication and humble pleading.',
    'And He is the One who sends down the rain after they have despaired and spreads His mercy, and He is the Protecting Friend, Worthy of All Praise. Truly to Allah we belong and truly to Him we return; judgment belongs to Allah, the Most High, the Great. Sufficient for us is Allah, and how excellent a Trustee He is. May Allah send blessings and peace upon our Messenger Muhammad, his family, and all his Companions.',
    'Glory be to your Lord, Lord of Might, above what they describe, and peace be upon the messengers, and praise be to Allah, Lord of all worlds. Our Lord, accept from us, pardon us, forgive us, have mercy upon us, turn to us in mercy, guide us, water us, and mend our affairs and the affairs of the Muslims—by the sanctity of the One upon whom You revealed Sūrah al-Fātiḥah.',
  ];

  List<_DuaSegment> _segments = [];
  List<GlobalKey> _segmentKeys = [];
  bool _isLoading = true;
  String? _error;
  _DuaDisplayMode _displayMode = _DuaDisplayMode.transliteration;

  late AudioPlayer _audioPlayer;
  final ValueNotifier<Duration> _positionNotifier =
      ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<int> _activeIndexNotifier = ValueNotifier<int>(-1);

  bool _isPlaying = false;
  bool _isAudioLoading = true;
  Duration _duration = Duration.zero;
  int _lastScrolledIndex = -1;

  static const List<double> _speedOptions = [1.0, 1.25, 1.5, 1.75, 2.0, 3.0];
  double _playbackSpeed = 1.0;

  late StreamSubscription<PlayerState> _playerStateSub;
  late StreamSubscription<Duration> _positionSub;
  late StreamSubscription<Duration?> _durationSub;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
    _getData();
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
    if (mounted) {
      setState(() => _playbackSpeed = speed);
    }
  }

  String _formatSpeed(double speed) {
    return '${speed == speed.roundToDouble() ? speed.toStringAsFixed(0) : speed}x';
  }

  Future<void> _initAudio() async {
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      final playingNow = state.playing;
      if (playingNow != _isPlaying) {
        setState(() => _isPlaying = playingNow);
      }
      if (state.processingState == ProcessingState.completed) {
        _audioPlayer.pause();
        _audioPlayer.seek(Duration.zero);
        _activeIndexNotifier.value = -1;
        _lastScrolledIndex = -1;
      }
    });

    _positionSub = _audioPlayer.positionStream.listen((pos) {
      if (!mounted) return;
      _positionNotifier.value = pos;
      final newIndex = _computeActiveIndex(pos);
      if (_isPlaying || pos > Duration.zero) {
        if (_activeIndexNotifier.value != newIndex) {
          _activeIndexNotifier.value = newIndex;
        }
        if (_isPlaying && newIndex >= 0 && newIndex != _lastScrolledIndex) {
          _lastScrolledIndex = newIndex;
          _scrollToActiveSegment(newIndex);
        }
      }
    });

    _durationSub = _audioPlayer.durationStream.listen((dur) {
      if (mounted && dur != null && dur != _duration) {
        setState(() => _duration = dur);
      }
    });

    try {
      if (_audioSource.startsWith('http')) {
        await _audioPlayer.setUrl(_audioSource);
      } else {
        await _audioPlayer.setAsset(_audioSource);
      }
    } catch (e) {
      debugPrint('Audio load error: $e');
    } finally {
      if (mounted) setState(() => _isAudioLoading = false);
    }
  }

  int _computeActiveIndex(Duration pos) {
    if (_segments.isEmpty) return -1;
    int current = 0;
    for (int i = 0; i < _segments.length; i++) {
      if (pos >= _segments[i].startTime) {
        current = i;
      } else {
        break;
      }
    }
    return current;
  }

  void _scrollToActiveSegment(int index) {
    if (index < 0 || index >= _segmentKeys.length) return;
    final ctx = _segmentKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.25,
      );
    }
  }

  Future<void> _getData() async {
    try {
      final result = await ApiService().getPages('mawlana-shaykh-nazim-dua');
      if (!mounted) return;
      final posts = result ?? [];
      final combinedHtml = posts.map((p) => p.content).join('\n');
      final parsed = _parseSegments(combinedHtml);
      setState(() {
        _segments = parsed;
        _segmentKeys = List.generate(parsed.length, (_) => GlobalKey());
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<_DuaSegment> _parseSegments(String rawHtml) {
    var html = rawHtml.replaceAll(
      RegExp(r'<style\b[^>]*>[\s\S]*?</style>', caseSensitive: false),
      '',
    );
    html = html.replaceAllMapped(
      RegExp(r'<p>\s*(<p\b[^>]*>[\s\S]*?</p>)\s*</p>', caseSensitive: false),
      (m) => m[1]!,
    );

    final matches = RegExp(
      r'<p\b([^>]*)>([\s\S]*?)</p>',
      caseSensitive: false,
    ).allMatches(html);

    final enList = <String>[];
    final arList = <String>[];

    for (final m in matches) {
      final attrs = m.group(1) ?? '';
      final inner = (m.group(2) ?? '').trim();

      final visibleText = inner
          .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(
            RegExp(r'&(?:nbsp|#0*160|#x0*a0);', caseSensitive: false),
            '',
          )
          .replaceAll(
            RegExp(r'(?:&#8203;|&#x200b;|&ZeroWidthSpace;)', caseSensitive: false),
            '',
          )
          .replaceAll(RegExp(r'[\s\u200B\uFEFF]+'), '');
      if (visibleText.isEmpty) continue;

      final isArabic =
          RegExp(r'\barabic-content\b', caseSensitive: false).hasMatch(attrs) ||
          RegExp(
            r'''\blang\s*=\s*["']?ar(?:[-_][^"']*)?["']?''',
            caseSensitive: false,
          ).hasMatch(attrs);

      final styledInner = inner.replaceAllMapped(
        RegExp(r'([\uFDFA\uFDFB])'),
        (s) =>
            '<span style="font-family: \'Neirizi\'; font-size: 20px;">${s[1]}</span>',
      );

      if (isArabic) {
        arList.add(styledInner);
      } else {
        enList.add(styledInner);
      }
    }

    final maxFromLists =
        enList.length > arList.length ? enList.length : arList.length;
    final count = maxFromLists > _segmentTranslations.length
        ? maxFromLists
        : _segmentTranslations.length;

    return List.generate(count, (i) {
      final sec = i < _segmentSeconds.length
          ? _segmentSeconds[i]
          : (i > 0 ? _segmentSeconds.last + (i - _segmentSeconds.length + 1) * 15 : 0);
      final trText =
          i < _segmentTranslations.length ? _segmentTranslations[i] : '';
      return _DuaSegment(
        startTime: Duration(seconds: sec),
        enHtml: i < enList.length ? enList[i] : '',
        arHtml: i < arList.length ? arList[i] : '',
        trHtml: trText,
      );
    });
  }

  @override
  void dispose() {
    _playerStateSub.cancel();
    _positionSub.cancel();
    _durationSub.cancel();
    _positionNotifier.dispose();
    _activeIndexNotifier.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              RepaintBoundary(child: _buildStickyAudioBar(isDark)),
              Expanded(
                child: RepaintBoundary(child: _buildBody(context, isDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(String label, _DuaDisplayMode mode, bool isDark) {
    final selected = _displayMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _displayMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.white
                : (isDark ? AppColors.darkSubText : Colors.black),
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
          const SizedBox(width: 8),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppGradients.goldShimmer.createShader(bounds),
              child: const Text(
                'Dua by Grandshaykh, Shaykh Nazim QSA',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildModeChip('EN', _DuaDisplayMode.transliteration, isDark),
                _buildModeChip('AR', _DuaDisplayMode.arabic, isDark),
                _buildModeChip('TR', _DuaDisplayMode.translation, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyAudioBar(bool isDark) {
    final maxSeconds =
        _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: isDark
            ? AppShadows.cardShadowDark
            : AppShadows.cardShadowLight,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isAudioLoading
                ? null
                : () async {
                    if (_isPlaying) {
                      await _audioPlayer.pause();
                    } else {
                      await _audioPlayer.play();
                    }
                  },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isPlaying ? AppGradients.goldShimmer : null,
                color: _isPlaying
                    ? null
                    : AppColors.gold.withValues(alpha: 0.14),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.6),
                  width: 1.3,
                ),
              ),
              child: Center(
                child: _isAudioLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gold,
                        ),
                      )
                    : Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: _isPlaying ? Colors.white : AppColors.gold,
                        size: 26,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ValueListenableBuilder<Duration>(
              valueListenable: _positionNotifier,
              builder: (context, pos, _) {
                final currentSeconds =
                    pos.inSeconds.toDouble().clamp(0.0, maxSeconds);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: AppColors.gold,
                        inactiveTrackColor:
                            AppColors.gold.withValues(alpha: 0.2),
                        thumbColor: AppColors.gold,
                      ),
                      child: Slider(
                        min: 0,
                        max: maxSeconds,
                        value: currentSeconds,
                        onChanged: (value) {
                          _audioPlayer.seek(Duration(seconds: value.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(pos),
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkSubText
                                  : AppColors.lightSubText,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkSubText
                                  : AppColors.lightSubText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<double>(
            tooltip: 'Playback speed',
            initialValue: _playbackSpeed,
            onSelected: _setPlaybackSpeed,
            itemBuilder: (context) => _speedOptions.map((speed) {
              return PopupMenuItem<double>(
                value: speed,
                child: Row(
                  children: [
                    if (_playbackSpeed == speed)
                      const Icon(
                        Icons.check,
                        color: AppColors.gold,
                        size: 18,
                      )
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text(_formatSpeed(speed)),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: _playbackSpeed != 1.0
                    ? AppColors.gold
                    : AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                _formatSpeed(_playbackSpeed),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _playbackSpeed != 1.0 ? Colors.white : AppColors.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _segmentContentForMode(_DuaSegment seg) {
    return switch (_displayMode) {
      _DuaDisplayMode.transliteration => seg.enHtml,
      _DuaDisplayMode.arabic => seg.arHtml,
      _DuaDisplayMode.translation => seg.trHtml,
    };
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.gold, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Could not load content',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {
                _isLoading = true;
                _error = null;
                _getData();
              }),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    if (_segments.isEmpty) {
      return Center(
        child: Text(
          'No content found.',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
          ),
        ),
      );
    }

    final isArabic = _displayMode == _DuaDisplayMode.arabic;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ValueListenableBuilder<int>(
        valueListenable: _activeIndexNotifier,
        builder: (context, activeIdx, _) {
          return Column(
            children: List.generate(_segments.length, (index) {
              final seg = _segments[index];
              final isActive = index == activeIdx;
              final contentHtml = _segmentContentForMode(seg);
              if (contentHtml.isEmpty) return const SizedBox.shrink();

              return GestureDetector(
                key: _segmentKeys[index],
                onTap: () async {
                  _lastScrolledIndex = index;
                  _activeIndexNotifier.value = index;
                  await _audioPlayer.seek(seg.startTime);
                  if (!_isPlaying) {
                    await _audioPlayer.play();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.gold.withValues(alpha: isDark ? 0.18 : 0.14)
                        : (isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? AppColors.gold
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.06)),
                      width: isActive ? 1.6 : 0.8,
                    ),
                    boxShadow: isActive
                        ? AppShadows.goldGlow
                        : (isDark
                            ? AppShadows.cardShadowDark
                            : AppShadows.cardShadowLight),
                  ),
                  child: Html(
                    data: contentHtml,
                    style: {
                      'body': Style(
                        fontFamily: isArabic ? 'Neirizi' : 'Nunito',
                        fontSize: FontSize(isArabic ? 20 : 16),
                        fontWeight:
                            isArabic ? FontWeight.w500 : FontWeight.w400,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                        lineHeight: LineHeight(isArabic ? 2.1 : 1.75),
                        direction:
                            isArabic ? TextDirection.rtl : TextDirection.ltr,
                        textAlign:
                            isArabic ? TextAlign.right : TextAlign.left,
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                    },
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}