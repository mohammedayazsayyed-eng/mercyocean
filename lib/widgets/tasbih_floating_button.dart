import 'package:flutter/material.dart';
import 'package:mercyocean/config/app_theme.dart';
import 'package:mercyocean/pages/tasbih_page.dart';
import 'package:mercyocean/widgets/tasbih_beads_icon.dart';

/// Floating round "thumb" button that opens the Tasbih page.
///
/// Styled like a slider thumb — a solid gold disc inside a light ring that
/// lifts it off whatever is behind it — and parked just above the bottom
/// navigation bar rather than overlapping any of its icons.
class TasbihFloatingButton extends StatefulWidget {
  const TasbihFloatingButton({super.key});

  /// Full outside width, ring included.
  static const double diameter = 60;

  /// Thickness of the pale ring drawn around the gold disc.
  static const double ringWidth = 4;

  @override
  State<TasbihFloatingButton> createState() => _TasbihFloatingButtonState();
}

class _TasbihFloatingButtonState extends State<TasbihFloatingButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColor = isDark ? AppColors.darkNavBar : AppColors.lightNavBar;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTap: () {
        _setPressed(false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TasbihPage()),
        );
      },
      // Squashes slightly on press, the way a real thumb control responds.
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed ? 0.92 : 1.0,
        child: Container(
          width: TasbihFloatingButton.diameter,
          height: TasbihFloatingButton.diameter,
          padding: const EdgeInsets.all(TasbihFloatingButton.ringWidth),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ringColor,
            boxShadow: [
              ...AppShadows.goldGlow,
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.goldShimmer,
            ),
            child: Center(
              child: TasbihBeadsIcon(
                size: TasbihFloatingButton.diameter * 0.46,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
