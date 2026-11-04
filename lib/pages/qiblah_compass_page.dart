import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../config/app_theme.dart';

// ── Outer page: handles location & qibla calculation only ─────
class QiblahCompassPage extends StatefulWidget {
  const QiblahCompassPage({super.key});

  @override
  State<QiblahCompassPage> createState() => _QiblahCompassPageState();
}

class _QiblahCompassPageState extends State<QiblahCompassPage> {
  static const double _meccaLat = 21.4225;
  static const double _meccaLng = 39.8262;

  Position? _position;
  double _qiblaDirection = 0.0;
  bool _isLoadingLocation = true;
  String? _locationError;
  bool _hasCompass = true;

  @override
  void initState() {
    super.initState();
    _hasCompass = FlutterCompass.events != null;
    _getLocation();
  }

  Future<void> _getLocation() async {
    if (mounted) {
      setState(() {
        _isLoadingLocation = true;
        _locationError = null;
      });
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationError =
              'Location services are disabled.\nPlease enable GPS and try again.';
        });
      }
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationError =
              'Location permission denied.\nPlease allow location access in settings.';
        });
      }
      return;
    }

    // Fast path: last known position gives instant Qibla
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() {
          _position = lastKnown;
          _qiblaDirection = _calculateQibla(
            lastKnown.latitude,
            lastKnown.longitude,
          );
          _isLoadingLocation = false;
        });
      }
    } catch (_) {}

    // Accurate fix in background
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _position = position;
          _qiblaDirection = _calculateQibla(
            position.latitude,
            position.longitude,
          );
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted && _position == null) {
        setState(() {
          _isLoadingLocation = false;
          _locationError = 'Could not get location. Please try again.';
        });
      }
    }
  }

  double _calculateQibla(double lat, double lng) {
    final lat1 = lat * math.pi / 180;
    final lng1 = lng * math.pi / 180;
    const lat2 = _meccaLat * math.pi / 180;
    const lng2 = _meccaLng * math.pi / 180;
    final dLng = lng2 - lng1;
    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return ((math.atan2(y, x) * 180 / math.pi) + 360) % 360;
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
              Expanded(child: _buildBody(isDark)),
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
            shaderCallback: (b) => AppGradients.goldShimmer.createShader(b),
            child: const Text(
              'Qiblah Compass',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoadingLocation) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (_locationError != null) return _buildError(isDark);
    if (!_hasCompass) return _buildNoCompass(isDark);
    return _CompassDisplay(
      qiblaDirection: _qiblaDirection,
      isDark: isDark,
      position: _position,
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off_rounded,
              color: AppColors.gold,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _locationError!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                height: 1.6,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _getLocation,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCompass(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'This device does not have a compass sensor.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
          ),
        ),
      ),
    );
  }
}

// ── Inner widget: owns the compass stream lifecycle ────────────
// Cancels its subscription in deactivate() so no setState fires
// during the widget tree teardown that triggers _dependents.isEmpty.
class _CompassDisplay extends StatefulWidget {
  final double qiblaDirection;
  final bool isDark;
  final Position? position;

  const _CompassDisplay({
    required this.qiblaDirection,
    required this.isDark,
    required this.position,
  });

  @override
  State<_CompassDisplay> createState() => _CompassDisplayState();
}

class _CompassDisplayState extends State<_CompassDisplay> {
  double _heading = 0.0;
  StreamSubscription<CompassEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FlutterCompass.events?.listen((event) {
      if (!mounted || event.heading == null) return;
      setState(() => _heading = event.heading!);
    });
  }

  // Cancel here — before Flutter starts tearing down the element tree.
  // This prevents any setState from firing between deactivate and unmount,
  // which is what causes the _dependents.isEmpty assertion.
  @override
  void deactivate() {
    _sub?.cancel();
    _sub = null;
    super.deactivate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  double get _diff => (widget.qiblaDirection - _heading + 360) % 360;
  bool get _isAligned => _diff < 5 || _diff > 355;
  double get _needleAngle => (widget.qiblaDirection - _heading) * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            _buildInfoCard(),
            const SizedBox(height: 36),
            _buildDial(),
            const SizedBox(height: 28),
            _buildBadge(),
            const SizedBox(height: 16),
            if (widget.position != null)
              Text(
                '${widget.position!.latitude.toStringAsFixed(4)}°, '
                '${widget.position!.longitude.toStringAsFixed(4)}°',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: widget.isDark
                      ? AppColors.darkSubText
                      : AppColors.lightSubText,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: _isAligned ? 0.8 : 0.2),
          width: _isAligned ? 1.5 : 1,
        ),
        boxShadow: widget.isDark
            ? AppShadows.cardShadowDark
            : AppShadows.cardShadowLight,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _stat('Qiblah', '${widget.qiblaDirection.toStringAsFixed(1)}°'),
          _divider(),
          _stat('Heading', '${_heading.abs().toStringAsFixed(1)}°'),
          _divider(),
          _stat(
            'Offset',
            '${_diff.toStringAsFixed(1)}°',
            highlight: _isAligned,
          ),
        ],
      ),
    );
  }

  Widget _buildDial() {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Static compass face
            CustomPaint(
              size: const Size(280, 280),
              painter: _CompassFacePainter(isDark: widget.isDark),
            ),
            // Mecca icon at North position
            const Align(
              alignment: Alignment(0, -0.70),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🕋', style: TextStyle(fontSize: 22)),
                  Text(
                    'Mecca',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
            // Rotating needle
            Transform.rotate(
              angle: _needleAngle,
              child: CustomPaint(
                size: const Size(280, 280),
                painter: const _NeedlePainter(),
              ),
            ),
            // Centre jewel
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.goldLight, AppColors.goldDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: AppShadows.goldGlow,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _isAligned
          ? Container(
              key: const ValueKey('aligned'),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.gold, width: 1),
              ),
              child: const Text(
                '✦  Facing Qiblah  ✦',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            )
          : Text(
              key: const ValueKey('rotate'),
              'Rotate device to face Qiblah',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: widget.isDark
                    ? AppColors.darkSubText
                    : AppColors.lightSubText,
              ),
            ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 36,
    color: AppColors.gold.withValues(alpha: 0.25),
  );

  Widget _stat(String label, String value, {bool highlight = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            color: widget.isDark
                ? AppColors.darkSubText
                : AppColors.lightSubText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: highlight
                ? AppColors.gold
                : (widget.isDark ? AppColors.darkText : AppColors.lightText),
          ),
        ),
      ],
    );
  }
}

// ── Compass face painter ───────────────────────────────────────
class _CompassFacePainter extends CustomPainter {
  final bool isDark;
  const _CompassFacePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.drawCircle(
      c,
      r - 4,
      Paint()..color = isDark ? AppColors.darkSurface : AppColors.lightSurface,
    );

    canvas.drawCircle(
      c,
      r - 3,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            AppColors.goldLight,
            AppColors.goldDark,
            AppColors.goldLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: c, radius: r))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    canvas.drawCircle(
      c,
      r - 12,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    for (int deg = 0; deg < 360; deg += 5) {
      final isCardinal = deg % 90 == 0;
      final isHalf = deg % 45 == 0;
      final isMajor = deg % 10 == 0;
      final len = isCardinal ? 20.0 : (isHalf ? 13.0 : (isMajor ? 9.0 : 5.0));
      final strokeW = isCardinal ? 2.5 : (isHalf ? 1.8 : (isMajor ? 1.2 : 0.8));
      final tickColor = isCardinal
          ? AppColors.gold
          : (isDark
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.25));
      final angle = deg * math.pi / 180;
      final outerR = r - 14;
      final innerR = r - 14 - len;
      canvas.drawLine(
        Offset(
          c.dx + outerR * math.sin(angle),
          c.dy - outerR * math.cos(angle),
        ),
        Offset(
          c.dx + innerR * math.sin(angle),
          c.dy - innerR * math.cos(angle),
        ),
        Paint()
          ..color = tickColor
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    // E / S / W labels only — N replaced by Mecca widget overlay
    final cardinals = ['E', 'S', 'W'];
    final angles = [math.pi / 2, math.pi, 3 * math.pi / 2];
    final labelR = r - 42;

    for (int i = 0; i < 3; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: cardinals[i],
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          c.dx + labelR * math.sin(angles[i]) - tp.width / 2,
          c.dy - labelR * math.cos(angles[i]) - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_CompassFacePainter old) => old.isDark != isDark;
}

// ── Needle painter ─────────────────────────────────────────────
class _NeedlePainter extends CustomPainter {
  const _NeedlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final tipY = c.dy - size.height * 0.36;
    final tailY = c.dy + size.height * 0.22;

    final goldPath = Path()
      ..moveTo(c.dx, tipY)
      ..lineTo(c.dx - 9, c.dy)
      ..lineTo(c.dx, c.dy - 5)
      ..lineTo(c.dx + 9, c.dy)
      ..close();

    canvas.drawPath(
      goldPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.goldLight, AppColors.goldDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(c.dx - 9, tipY, 18, c.dy - tipY))
        ..style = PaintingStyle.fill,
    );

    final tailPath = Path()
      ..moveTo(c.dx, tailY)
      ..lineTo(c.dx - 7, c.dy)
      ..lineTo(c.dx, c.dy + 5)
      ..lineTo(c.dx + 7, c.dy)
      ..close();

    canvas.drawPath(
      tailPath,
      Paint()..color = Colors.grey.withValues(alpha: 0.45),
    );

    const kaabaSize = 11.0;
    final kaabaRect = Rect.fromCenter(
      center: Offset(c.dx, tipY + kaabaSize / 2 + 2),
      width: kaabaSize,
      height: kaabaSize,
    );
    canvas.drawRect(kaabaRect, Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawRect(
      kaabaRect,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_NeedlePainter old) => false;
}
