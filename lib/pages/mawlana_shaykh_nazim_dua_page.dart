import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:just_audio/just_audio.dart';
import '../models/wordpress_post_model.dart';
import '../service/api_service.dart';
import '../config/app_theme.dart';

class _DuaSegment {
 final Duration startTime;
 final String enHtml;
 final String arHtml;

 const _DuaSegment({
 required this.startTime,
 required this.enHtml,
 required this.arHtml,
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
 // To stream from Cloudflare/WordPress instead, paste the https:// URL here:
 static const String _audioSource = 'assets/audio/mawlana_shaykh_nazim_dua.mp3';

 // Exact start timestamps (in seconds) for each of the 22 Dua paragraphs
 static const List<int> _segmentSeconds = [
 0, 8, 22, 40, 60, 76, 100, 142, 167, 189, 215,
 243, 272, 288, 323, 339, 371, 390, 407, 423, 454, 479,
 ];

 List<_DuaSegment> _segments = [];
 List<GlobalKey> _segmentKeys = [];
 bool _isLoading = true;
 String? _error;
 bool _showArabic = false;

 late AudioPlayer _audioPlayer;
 bool _isPlaying = false;
 bool _isAudioLoading = true;
 Duration _position = Duration.zero;
 Duration _duration = Duration.zero;
 int _activeIndex = -1;
 static const List<double> _speedOptions = [1.0, 1.25, 1.5, 1.75, 2.0, 3.0];
 double _playbackSpeed = 1.0;

 Future<void> _setPlaybackSpeed(double speed) async {
  await _audioPlayer.setSpeed(speed);
  if (mounted) {
   setState(() => _playbackSpeed = speed);
  }
 }

 String _formatSpeed(double speed) {
  return '${speed == speed.roundToDouble() ? speed.toStringAsFixed(0) : speed}x';
 }

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
 setState(() => _isPlaying = state.playing);
 if (state.processingState == ProcessingState.completed) {
 _audioPlayer.pause();
 _audioPlayer.seek(Duration.zero);
 setState(() => _activeIndex = -1);
 }
 });

 _positionSub = _audioPlayer.positionStream.listen((pos) {
 if (!mounted) return;
 final newIndex = _computeActiveIndex(pos);
 final indexChanged = newIndex != _activeIndex;
 setState(() {
 _position = pos;
 if (_isPlaying || pos > Duration.zero) {
 _activeIndex = newIndex;
 }
 });
 if (indexChanged && _isPlaying && newIndex >= 0) {
 _scrollToActiveSegment(newIndex);
 }
 });

 _durationSub = _audioPlayer.durationStream.listen((dur) {
 if (mounted && dur != null) setState(() => _duration = dur);
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
 if (inner.isEmpty) continue;

 final isArabic =
 attrs.contains('arabic-content') || attrs.contains('lang="ar"');
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

 final count = enList.length > arList.length ? enList.length : arList.length;
 return List.generate(count, (i) {
 final sec = i < _segmentSeconds.length ? _segmentSeconds[i] : 0;
 return _DuaSegment(
 startTime: Duration(seconds: sec),
 enHtml: i < enList.length ? enList[i] : '',
 arHtml: i < arList.length ? arList[i] : '',
 );
 });
 }

 @override
 void dispose() {
 _playerStateSub.cancel();
 _positionSub.cancel();
 _durationSub.cancel();
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
 _buildStickyAudioBar(isDark),
 Expanded(child: _buildBody(context, isDark)),
 ],
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
 const Spacer(),
 ShaderMask(
 shaderCallback: (bounds) =>
 AppGradients.goldShimmer.createShader(bounds),
 child: const Text(
 'Mawlana Shaykh Nazim Dua',
 style: TextStyle(
 fontFamily: 'Poppins',
 fontSize: 16,
 fontWeight: FontWeight.w700,
 color: Colors.white,
 ),
 ),
 ),
 const Spacer(),
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
 ),
 child: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 AnimatedContainer(
 duration: const Duration(milliseconds: 250),
 padding: const EdgeInsets.symmetric(
 horizontal: 9,
 vertical: 5,
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
 padding: const EdgeInsets.symmetric(
 horizontal: 9,
 vertical: 5,
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

 Widget _buildStickyAudioBar(bool isDark) {
 final maxSeconds =
 _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 1.0;
 final currentSeconds =
 _position.inSeconds.toDouble().clamp(0.0, maxSeconds);

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
 child: Column(
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
 inactiveTrackColor: AppColors.gold.withValues(alpha: 0.2),
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
 _formatDuration(_position),
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
    color: AppColors.gold.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(
     color: AppColors.gold.withValues(alpha: 0.5),
    ),
   ),
   child: Text(
    _formatSpeed(_playbackSpeed),
    style: const TextStyle(
     fontFamily: 'Nunito',
     fontSize: 13,
     fontWeight: FontWeight.w800,
     color: AppColors.gold,
    ),
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

 return SingleChildScrollView(
 padding: const EdgeInsets.all(16),
 child: Column(
 children: List.generate(_segments.length, (index) {
 final seg = _segments[index];
 final isActive = index == _activeIndex;
 final contentHtml = _showArabic ? seg.arHtml : seg.enHtml;
 if (contentHtml.isEmpty) return const SizedBox.shrink();

 return GestureDetector(
 key: _segmentKeys[index],
 onTap: () async {
 await _audioPlayer.seek(seg.startTime);
 if (!_isPlaying) {
 await _audioPlayer.play();
 }
 },
 child: AnimatedContainer(
 duration: const Duration(milliseconds: 300),
 width: double.infinity,
 margin: const EdgeInsets.only(bottom: 12),
 padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
 decoration: BoxDecoration(
 color: isActive
 ? AppColors.gold.withValues(alpha: isDark ? 0.18 : 0.14)
 : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
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
 fontFamily: _showArabic ? 'Neirizi' : 'Nunito',
 fontSize: FontSize(_showArabic ? 20 : 16),
 fontWeight: _showArabic ? FontWeight.w500 : FontWeight.w400,
 color: isDark ? AppColors.darkText : AppColors.lightText,
 lineHeight: LineHeight(_showArabic ? 2.1 : 1.75),
 direction:
 _showArabic ? TextDirection.rtl : TextDirection.ltr,
 textAlign: _showArabic ? TextAlign.right : TextAlign.left,
 margin: Margins.zero,
 padding: HtmlPaddings.zero,
 ),
 },
 ),
 ),
 );
 }),
 ),
 );
 }
}
