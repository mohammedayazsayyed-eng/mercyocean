import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../config/app_theme.dart';

class SurahYasinShaykhAdilPage extends StatefulWidget {
  const SurahYasinShaykhAdilPage({super.key});

  @override
  State<SurahYasinShaykhAdilPage> createState() =>
      _SurahYasinShaykhAdilPageState();
}

class _SurahYasinShaykhAdilPageState extends State<SurahYasinShaykhAdilPage> {
  static const String _audioAsset = 'assets/audio/surah_yasin_shaykh_adil.mp3';
  static const List<double> _speedOptions = [1.0, 1.25, 1.5, 1.75, 2.0, 3.0];

  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = true;
  Duration _position = Duration.zero;
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
  }

  Future<void> _initAudio() async {
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
      if (state.processingState == ProcessingState.completed) {
        _audioPlayer.pause();
        _audioPlayer.seek(Duration.zero);
      }
    });

    _positionSub = _audioPlayer.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _durationSub = _audioPlayer.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });

    try {
      await _audioPlayer.setAsset(_audioAsset);
    } catch (e) {
      debugPrint('Surah Yasin audio error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setSpeed(double speed) async {
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
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxSec =
        _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0;
    final curSec = _position.inSeconds.toDouble().clamp(0.0, maxSec);

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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            AppGradients.goldShimmer.createShader(bounds),
                        child: const Text(
                          'Surah Yasin Sharif',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'يس',
                          style: TextStyle(
                            fontFamily: 'Neirizi',
                            fontSize: 42,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Surah Yasin Recitation',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Mawlana Shaykh Muhammad Adil QS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () async {
                                      if (_isPlaying) {
                                        await _audioPlayer.pause();
                                      } else {
                                        await _audioPlayer.play();
                                      }
                                    },
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: _isPlaying
                                      ? AppGradients.goldShimmer
                                      : null,
                                  color: _isPlaying
                                      ? null
                                      : AppColors.gold.withValues(alpha: 0.14),
                                  border: Border.all(
                                    color: AppColors.gold.withValues(alpha: 0.6),
                                    width: 1.3,
                                  ),
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.gold,
                                          ),
                                        )
                                      : Icon(
                                          _isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: _isPlaying
                                              ? Colors.white
                                              : AppColors.gold,
                                          size: 28,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                children: [
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6),
                                      activeTrackColor: AppColors.gold,
                                      inactiveTrackColor:
                                          AppColors.gold.withValues(alpha: 0.2),
                                      thumbColor: AppColors.gold,
                                    ),
                                    child: Slider(
                                      min: 0,
                                      max: maxSec,
                                      value: curSec,
                                      onChanged: (v) => _audioPlayer
                                          .seek(Duration(seconds: v.toInt())),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDuration(_position),
                                          style: const TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 11),
                                        ),
                                        Text(
                                          _formatDuration(_duration),
                                          style: const TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<double>(
                              initialValue: _playbackSpeed,
                              onSelected: _setSpeed,
                              itemBuilder: (context) => _speedOptions
                                  .map(
                                    (s) => PopupMenuItem<double>(
                                      value: s,
                                      child: Row(
                                        children: [
                                          if (_playbackSpeed == s)
                                            const Icon(Icons.check,
                                                color: AppColors.gold, size: 18)
                                          else
                                            const SizedBox(width: 18),
                                          const SizedBox(width: 8),
                                          Text(_formatSpeed(s)),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _playbackSpeed != 1.0
                                      ? AppColors.gold
                                      : AppColors.gold.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        AppColors.gold.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  _formatSpeed(_playbackSpeed),
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _playbackSpeed != 1.0
                                        ? Colors.white
                                        : AppColors.gold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}