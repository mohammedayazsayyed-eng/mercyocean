import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mercyocean/models/wordpress_post_model.dart';
import 'package:mercyocean/service/api_service.dart';
import 'package:mercyocean/config/app_theme.dart';

class MagribPage extends StatefulWidget {
  const MagribPage({super.key});

  @override
  State<MagribPage> createState() => _MagribPageState();
}

class _MagribPageState extends State<MagribPage> {
  static const String _sajdahAudioAsset =
      'assets/audio/surat_as_sajdah_shaykh_muhammad.mp3';
  static const List<double> _speedOptions = [1.0, 1.25, 1.5, 1.75, 2.0, 3.0];

  List<WordpressPost> _posts = [];
  bool _isLoading = true;
  String? _error;
  bool _showArabic = false;

  late AudioPlayer _audioPlayer;
  final ValueNotifier<Duration> _positionNotifier =
      ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<double?> _dragSecondsNotifier =
      ValueNotifier<double?>(null);

  bool _isPlaying = false;
  bool _wasPlayingBeforeSeek = false;
  bool _isAudioLoading = true;
  bool _showSajdahPlayer = false;
  Duration _duration = Duration.zero;
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
      }
    });

    _positionSub = _audioPlayer.positionStream.listen((pos) {
      if (!mounted) return;
      if (_dragSecondsNotifier.value == null) {
        _positionNotifier.value = pos;
      }
    });

    _durationSub = _audioPlayer.durationStream.listen((dur) {
      if (mounted && dur != null && dur != _duration) {
        setState(() => _duration = dur);
      }
    });

    try {
      await _audioPlayer.setAsset(_sajdahAudioAsset);
    } catch (e) {
      debugPrint('Surat As-Sajdah audio error: $e');
    } finally {
      if (mounted) setState(() => _isAudioLoading = false);
    }
  }

  Future<void> _toggleOrPlaySajdahFromTop() async {
    if (!_showSajdahPlayer) {
      setState(() => _showSajdahPlayer = true);
    }
    if (_isAudioLoading) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> _handleSeekStart(double value) async {
    _wasPlayingBeforeSeek = _isPlaying;
    _dragSecondsNotifier.value = value;
    if (_isPlaying) {
      await _audioPlayer.pause();
    }
  }

  void _handleSeekChanged(double value) {
    _dragSecondsNotifier.value = value;
  }

  Future<void> _handleSeekEnd(double value) async {
    final target = Duration(seconds: value.round());
    _positionNotifier.value = target;
    await _audioPlayer.seek(target);
    _dragSecondsNotifier.value = null;
    if (_wasPlayingBeforeSeek && mounted) {
      _wasPlayingBeforeSeek = false;
      await _audioPlayer.play();
    }
  }

  Future<void> _setPlaybackSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
    if (mounted) setState(() => _playbackSpeed = speed);
  }

  String _formatSpeed(double speed) {
    return '${speed == speed.roundToDouble() ? speed.toStringAsFixed(0) : speed}x';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _playerStateSub.cancel();
    _positionSub.cancel();
    _durationSub.cancel();
    _positionNotifier.dispose();
    _dragSecondsNotifier.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _getData() async {
    try {
      final result = await ApiService().getPages('maghrib-salah');
      if (!mounted) return;
      setState(() {
        _posts = result ?? [];
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

  String _formatHtml(String rawHtml, bool isDark) {
    final titleColor = isDark ? '#4ADE80' : '#0E7C3A';

    var html = rawHtml.replaceAll(
      RegExp(r'<style\b[^>]*>[\s\S]*?</style>', caseSensitive: false),
      '',
    );

    html = html.replaceAllMapped(
      RegExp(
        r'<strong\b([^>]*)>(.*?)</strong>',
        caseSensitive: false,
        dotAll: true,
      ),
      (m) => '<strong${m[1]} style="color: $titleColor;">${m[2]}</strong>',
    );
    html = html.replaceAllMapped(
      RegExp(r'<mark\b[^>]*>(.*?)</mark>', caseSensitive: false, dotAll: true),
      (m) => '<span style="color: $titleColor; font-weight: 700;">${m[1]}</span>',
    );

    final enTitleRegex = RegExp(
      r'((?:^|>|<br\s*/?>)\s*)(~?\s*(?:'
      r'[ṢS]al[āa]tu\s+(?:al-Magrib|al-Maghrib|as-sunnah|as-Sunnah|l-far[ḍd]|al-Munjiyah(?:/Tunj[īi]n[āa])?)(?:\s*\([^)]*\))?'
      r'|Kalimat\s+ash-Shah[āa]dah\s*:?'
      r'|Du[ʿ‘’\x27]?[āa][ʾ’\x27]?(?:\s+al-Qun[ūu]t\.?|\s+after\s+the\s+Adhan|\s+recited\s+by\s+the\s+imam)?\s*:?'
      r'|Ihd[āa][’\x27]?\s*:?'
      r'|Adhan\s*:?'
      r'|Iqamat\s+a[sṣ]-[sṣ]al[āa]h\.?'
      r'|Tasb[īi][ḥh]\s*:?'
      r'|Al-Istighf[āa]r\s*:?'
      r'|[ṢS]alaw[āa]t(?:\s*\([^)]*\))?'
      r'|Surah\s+[A-Za-z\-]+(?:\s*\([^)]*\))?'
      r'|Surat\s+Y[āa]-S[īi]n\s*:?'
      r'|Al-F[āa]ti[ḥh]ah(?:\s*\([^)]*\))?\.?'
      r'|The\s+Imam\s+continues[^:<]*:?'
      r'|Lie\s+down[^:<]*:?'
      r'|Get\s+up[^:<]*:?'
      r'))',
      caseSensitive: false,
    );

    html = html.replaceAllMapped(
      enTitleRegex,
      (m) =>
          '${m[1]}<span style="color: $titleColor; font-weight: 700;">${m[2]}</span>',
    );

    const d = r'[\u064B-\u065F\u0670\u0640]*';
    final arTitleRegex = RegExp(
      '((?:^|>|<br\\s*/?>)\\s*)(~?\\s*(?:'
      'ص$dل$dا$dة$d\\s+ا$dل$dم$dغ$dر$dب$d(?:\\s*\\([^)]*\\))?'
      '|ص$dل$dا$dة$d\\s+ا$dل$dس$dن$dة$d(?:\\s*\\([^)]*\\))?'
      '|ص$dل$dا$dة$d\\s+ا$dل$dف$dر$dض$d(?:\\s*\\([^)]*\\))?'
      '|ك$dل$dم$dة$d\\s+ا$dل$dش$dه$dا$dد$dة$d\\s*:?'
      '|د$dع$dا$dء$d(?:\\s+ا$dل$dق$dن$dو$dت$d)?\\s*:?'
      '|ا$dل$dد$dع$dا$dء$d\\s*:?'
      '|إ$dه$dد$dا$dء$d\\s*:?'
      '|ا$dه$dد$dا$dء$d\\s*:?'
      '|إ$dق$dا$dم$dة$d\\s+ا$dل$dص$dل$dا$dة$d'
      '|ا$dل$dت$dس$dب$dي$dح$d\\s*:?'
      '|ت$dس$dب$dي$dح$d\\s*:?'
      '|ا$dل$dا$dس$dت$dغ$dف$dا$dر$d\\s*:?'
      '|ص$dل$dو$dا$dت$d(?:\\s*\\([^)]*\\))?'
      '|س$dو$dر$dة$d\\s+[^<:.\\n(]+(?:\\s*\\([^)]*\\))?\\s*:?'
      '|ا$dل$dف$dا$dت$dح$dة$d(?:\\s*\\([^)]*\\))?'
      '))',
    );

    html = html.replaceAllMapped(
      arTitleRegex,
      (m) =>
          '${m[1]}<span style="color: $titleColor; font-weight: 700;">${m[2]}</span>',
    );

    html = html.replaceAllMapped(
      RegExp(r'([\uFDFA\uFDFB])'),
      (m) =>
          '<span style="font-family: \'Neirizi\'; font-size: 20px;">${m[1]}</span>',
    );

    return html;
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
              if (_showSajdahPlayer || _isPlaying)
                RepaintBoundary(child: _buildStickySajdahBar(isDark)),
              Expanded(
                child: RepaintBoundary(child: _buildBody(context, isDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSajdahTopPill(bool isDark) {
    final active = _isPlaying;
    return GestureDetector(
      onTap: _toggleOrPlaySajdahFromTop,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          gradient: active ? AppGradients.goldShimmer : null,
          color: active
              ? null
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: isDark
              ? AppShadows.cardShadowDark
              : AppShadows.cardShadowLight,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 15,
              color: active ? Colors.white : AppColors.gold,
            ),
            const SizedBox(width: 3),
            Text(
              'Sajdah',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickySajdahBar(bool isDark) {
    final maxSeconds =
        _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: isDark
            ? AppShadows.cardShadowDark
            : AppShadows.cardShadowLight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Surat As-Sajdah • Shaykh Muhammad",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  _wasPlayingBeforeSeek = false;
                  await _audioPlayer.pause();
                  if (mounted) setState(() => _showSajdahPlayer = false);
                },
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onTap: _toggleOrPlaySajdahFromTop,
                child: Container(
                  width: 42,
                  height: 42,
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
                            size: 24,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ValueListenableBuilder<Duration>(
                  valueListenable: _positionNotifier,
                  builder: (context, pos, _) {
                    return ValueListenableBuilder<double?>(
                      valueListenable: _dragSecondsNotifier,
                      builder: (context, dragSec, _) {
                        final displayedDuration = dragSec != null
                            ? Duration(seconds: dragSec.round())
                            : pos;
                        final currentSeconds = (dragSec ??
                                pos.inSeconds.toDouble())
                            .clamp(0.0, maxSeconds);

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
                                onChangeStart: _handleSeekStart,
                                onChanged: _handleSeekChanged,
                                onChangeEnd: _handleSeekEnd,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(displayedDuration),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
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
                      color:
                          _playbackSpeed != 1.0 ? Colors.white : AppColors.gold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
          const SizedBox(width: 10),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  AppGradients.goldShimmer.createShader(bounds),
              child: const Text(
                'Salatu l-Magrib',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildSajdahTopPill(isDark),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showArabic = !_showArabic),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: isDark
                    ? AppShadows.cardShadowDark
                    : AppShadows.cardShadowLight,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: !_showArabic ? AppColors.gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      'EN',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: !_showArabic
                            ? Colors.white
                            : isDark
                                ? AppColors.darkSubText
                                : Colors.black,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _showArabic ? AppColors.gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      'AR',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _showArabic
                            ? Colors.white
                            : isDark
                                ? AppColors.darkSubText
                                : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (_error != null) return _buildError();
    if (_posts.isEmpty) return _buildEmpty(isDark);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _posts.map((post) => _buildContent(post, isDark)).toList(),
      ),
    );
  }

  Widget _buildContent(WordpressPost post, bool isDark) {
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: isDark
            ? AppShadows.cardShadowDark
            : AppShadows.cardShadowLight,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          width: constraints.maxWidth,
          child: Html(
            data: _formatHtml(post.content, isDark),
            style: {
              'body': Style(
                fontFamily: 'Nunito',
                fontSize: FontSize(16),
                color: isDark ? AppColors.darkText : AppColors.lightText,
                lineHeight: LineHeight(1.75),
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
              'p': Style(
                color: isDark ? AppColors.darkText : AppColors.lightText,
                fontSize: FontSize(16),
                lineHeight: LineHeight(1.75),
                padding: HtmlPaddings.only(bottom: 14),
                margin: Margins.only(bottom: 14),
                border: Border(
                  bottom: BorderSide(color: dividerColor, width: 0.8),
                ),
                display: _showArabic ? Display.none : Display.block,
                direction: TextDirection.ltr,
                textAlign: TextAlign.left,
              ),
              'p.arabic-content': Style(
                fontFamily: 'Neirizi',
                fontSize: FontSize(19),
                fontWeight: FontWeight.w500,
                lineHeight: LineHeight(2.1),
                direction: TextDirection.rtl,
                display: _showArabic ? Display.block : Display.none,
                textAlign: TextAlign.right,
                padding: HtmlPaddings.only(bottom: 16),
                margin: Margins.only(bottom: 16),
                border: Border(
                  bottom: BorderSide(color: dividerColor, width: 0.8),
                ),
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              '*[lang="ar"]': Style(
                fontFamily: 'Neirizi',
                fontSize: FontSize(19),
                fontWeight: FontWeight.w500,
                lineHeight: LineHeight(2.1),
                direction: TextDirection.rtl,
                display: _showArabic ? Display.block : Display.none,
                textAlign: TextAlign.right,
                padding: HtmlPaddings.only(bottom: 16),
                margin: Margins.only(bottom: 16),
                border: Border(
                  bottom: BorderSide(color: dividerColor, width: 0.8),
                ),
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              'p.has-large-font-size': Style(
                fontFamily: 'Neirizi',
                fontSize: FontSize(19),
                fontWeight: FontWeight.w500,
                lineHeight: LineHeight(2.1),
                direction: TextDirection.rtl,
                display: _showArabic ? Display.block : Display.none,
                textAlign: TextAlign.right,
                padding: HtmlPaddings.only(bottom: 16),
                margin: Margins.only(bottom: 16),
                border: Border(
                  bottom: BorderSide(color: dividerColor, width: 0.8),
                ),
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              'div': Style(
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              'h1': Style(
                fontFamily: 'Poppins',
                color: AppColors.gold,
                fontSize: FontSize(24),
                fontWeight: FontWeight.w700,
                margin: Margins.only(bottom: 16),
              ),
              'h2': Style(
                fontFamily: 'Poppins',
                color: AppColors.gold,
                fontSize: FontSize(21),
                fontWeight: FontWeight.w700,
              ),
              'h3': Style(
                fontFamily: 'Poppins',
                color: AppColors.gold,
                fontSize: FontSize(19),
                fontWeight: FontWeight.w700,
              ),
              'h4': Style(
                fontFamily: 'Poppins',
                color: AppColors.gold,
                fontSize: FontSize(17),
                fontWeight: FontWeight.w700,
              ),
              'img': Style(
                width: Width(100, Unit.percent),
                display: Display.block,
              ),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildError() => Center(
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

  Widget _buildEmpty(bool isDark) => Center(
    child: Text(
      'No content found.',
      style: TextStyle(
        fontFamily: 'Nunito',
        color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
      ),
    ),
  );
}