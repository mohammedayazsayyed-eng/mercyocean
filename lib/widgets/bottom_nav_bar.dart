import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'package:mercyocean/config/app_theme.dart';
import 'package:mercyocean/config/app_state.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  /// Height of the icon row, excluding the device's bottom safe-area inset.
  /// Anything floating above the bar positions itself against this.
  static const double barHeight = 76;

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkNavBar : AppColors.lightNavBar;
    final activeColor = AppColors.gold;
    final inactiveColor = isDark
        ? AppColors.darkIconInactive
        : AppColors.lightIconInactive;

    // Bubble color — subtle gold tint in both modes
    final bubbleColor = isDark
        ? AppColors.gold.withValues(alpha: 0.15)
        : AppColors.gold.withValues(alpha: 0.12);

    final items = [
      {'label': 'Intro', 'icon': Icons.lightbulb_outline},
      {
        'label': 'Shaykh Mehmet',
        'image': 'assets/images/icons/shaykh-mehmet-1.png',
      },
      {'label': 'Home', 'icon': Icons.mosque_outlined},
      {
        'label': 'Shaykh Nazim',
        'image': 'assets/images/icons/shaykh-nazim.png',
      },
      {'label': 'Contact', 'icon': Icons.mail_outline},
    ];
    return ValueListenableBuilder<int>(
      valueListenable: navIndexNotifier,
      builder: (context, selectedIndex, _) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: isDark
                ? AppShadows.navBarShadowDark
                : AppShadows.navBarShadowLight,
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: BottomNavBar.barHeight,
              child: Row(
                children: List.generate(items.length, (i) {
                  final selected = i == selectedIndex;
                  final color = selected ? activeColor : inactiveColor;
                  final hasImage = items[i].containsKey('image');

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => navIndexNotifier.value = i,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Pop-up animation
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            offset: selected
                                ? const Offset(0, -0.3)
                                : Offset.zero,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              scale: selected ? 1.15 : 1.0,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                width: selected ? 52 : 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? bubbleColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(18),
                                  // Kept transparent (rather than dropped) so
                                  // every tab reserves the same 1.5px and the
                                  // icons don't shift when selected.
                                  border: Border.all(
                                    color: Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: hasImage
                                      ? ClipOval(
                                          child: ColorFiltered(
                                            colorFilter: selected
                                                ? const ColorFilter.mode(
                                                    Colors.transparent,
                                                    BlendMode.multiply,
                                                  )
                                                : ColorFilter.mode(
                                                    Colors.grey,
                                                    BlendMode.saturation,
                                                  ),
                                            child: Image.asset(
                                              items[i]['image'] as String,
                                              width: 32,
                                              height: 28,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          items[i]['icon'] as IconData,
                                          color: isDark
                                              ? AppColors.gold
                                              : color,
                                          size: 30,
                                        ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Label. Two-word names ("Shaykh Mehmet") wrap onto
                          // a second line instead of being cut off; the box is
                          // a fixed height so single-word tabs still line their
                          // icons up with the wrapped ones.
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: selected ? 1.0 : 0.6,
                            child: SizedBox(
                              height: 28,
                              child: Center(
                                child: Text(
                                  items[i]['label'] as String,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 12,
                                    height: 1.1,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isDark ? activeColor : color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
