import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../config/app_theme.dart';

class InlineAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final VoidCallback? onPlayStarted;
  final VoidCallback? onPlayFinished;
  final ValueNotifier<String?>? activeAudioNotifier;

  const InlineAudioPlayer({
    required this.audioUrl,
    this.onPlayStarted,
    this.onPlayFinished,
    this.activeAudioNotifier,
    super.key,
  });

  @override
  State<InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<InlineAudioPlayer>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isPlaying = false;
  bool _isLoading = false;

  late StreamSubscription<PlayerState> _playerStateSubscription;
  late StreamSubscription<Duration?> _durationSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Pulse animation when playing
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) _onPlayerStateChanged(state);
    });
    _durationSubscription = _audioPlayer.durationStream.listen((_) {
      if (mounted) setState(() {});
    });

    widget.activeAudioNotifier?.addListener(_onActiveAudioChanged);
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      await _audioPlayer.setUrl(widget.audioUrl);
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to load audio',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
            backgroundColor: AppColors.gold,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _onActiveAudioChanged() {
    final active = widget.activeAudioNotifier?.value;
    if (active != widget.audioUrl && _isPlaying) {
      _audioPlayer.pause();
      _audioPlayer.seek(Duration.zero);
    }
  }

  void _onPlayerStateChanged(PlayerState state) {
    setState(() => _isPlaying = state.playing);

    if (state.playing) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }

    if (state.processingState == ProcessingState.completed) {
      setState(() => _isPlaying = false);
      _audioPlayer.pause().then((_) => _audioPlayer.seek(Duration.zero));
      _pulseController.stop();
      _pulseController.reset();
      widget.onPlayFinished?.call();
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        widget.activeAudioNotifier?.value = widget.audioUrl;
        widget.onPlayStarted?.call();
        await _audioPlayer.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Error playing audio',
              style: TextStyle(fontFamily: 'Nunito'),
            ),
            backgroundColor: AppColors.gold,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    widget.activeAudioNotifier?.removeListener(_onActiveAudioChanged);
    _pulseController.dispose();
    _playerStateSubscription.cancel();
    _durationSubscription.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPlaying ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: _isLoading ? null : _togglePlayPause,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _isPlaying ? AppGradients.goldShimmer : null,
            color: _isPlaying
                ? null
                : isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            border: Border.all(
              color: _isPlaying
                  ? Colors.transparent
                  : AppColors.gold.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: _isPlaying ? AppShadows.goldGlow : null,
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                    ),
                  )
                : Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _isPlaying ? Colors.white : AppColors.gold,
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }
}
