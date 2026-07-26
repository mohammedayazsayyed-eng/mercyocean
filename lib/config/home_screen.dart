import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mercyocean/pages/golden_chain_page.dart';
import 'package:mercyocean/pages/weekly_dhikr_page.dart';
import 'package:mercyocean/pages/salat_page.dart';
import 'package:mercyocean/pages/dalail_khairat_page.dart';
import 'package:mercyocean/pages/hizbul_azam_page.dart';
import 'package:mercyocean/pages/daily_awrad_page.dart';
import 'package:mercyocean/pages/monthly_awrad_page.dart';
import 'package:mercyocean/pages/quran_page.dart';
import 'package:mercyocean/pages/books_page.dart';
import 'package:mercyocean/pages/qiblah_compass_page.dart';
import 'package:mercyocean/pages/nasheeds_page.dart';
import 'package:mercyocean/pages/duas_page.dart';
import 'app_theme.dart';
import 'package:mercyocean/config/app_state.dart';

// ── Menu item model ──────────────────────────────────────────
class MenuItem {
  final String label;
  final IconData? icon;
  final String? asset;
  final Widget? route; // For named routes
  const MenuItem({required this.label, this.icon, this.asset, this.route})
    : assert(
        icon != null || asset != null,
        'MenuItem must have either an icon or an asset',
      );
}

// ── Home Screen ──────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //int _selectedNavIndex = 2; // Home is centre
  // All 11 menu items matching the design
  final List<MenuItem> _menuItems = const [
    MenuItem(
      label: 'Golden Chain',
      asset: 'assets/images/icons/golden_chain.svg',
      // route: PdfViewerScreen(media: WordpressMedia)
    ),

    MenuItem(
      label: 'Weekly Dhikr',
      //icon: Icons.sync_outlined,
      asset: 'assets/images/icons/monthly_wird.svg',
      // route: '/weekly-dhikr',
    ),
    MenuItem(
      label: 'Salah',
      asset: 'assets/images/icons/salat.svg',
      // route: '/salat',
    ),
    MenuItem(
      label: 'Dalail Ul Khairat',
      asset: 'assets/images/icons/dalail_ul_khairat.svg',
    ),
    MenuItem(
      label: 'Hizbu-l-Azam',
      asset: 'assets/images/icons/wird_protection.svg',
    ),
    MenuItem(label: 'Daily Awrad', icon: Icons.calendar_today_outlined),
    MenuItem(label: 'Hijri Calender', icon: Icons.calendar_month_outlined),
    MenuItem(label: 'Quran', asset: 'assets/images/icons/quran.svg'),
    MenuItem(label: 'Books', asset: 'assets/images/icons/books.svg'),
    MenuItem(label: 'Qiblah Compass', icon: Icons.explore_outlined),
    MenuItem(label: 'Nasheeds', asset: 'assets/images/icons/nasheed.svg'),
    MenuItem(label: 'Duas', asset: 'assets/images/icons/dua.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = navIndexNotifier.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // ── Background gradient ────────────────────────────
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppGradients.darkBackground
              : AppGradients.lightBackground,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(),
                child: _buildAppBar(context, isDark),
              ),
              Expanded(child: _buildGrid(context, isDark, textTheme)),
            ],
          ),
        ),
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arabic Bismillah
          ShaderMask(
            shaderCallback: (bounds) =>
                AppGradients.goldShimmer.createShader(bounds),
            child: Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              style: TextStyle(
                fontFamily: 'Neirizi',
                fontSize: 26,
                //color: Colors.white,
                // ShaderMask needs white base
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          // Moon icon (theme toggle)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => toggleTheme(),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (context, mode, _) {
                  final isDark = mode == ThemeMode.dark;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => RotationTransition(
                      turns: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Icon(
                      isDark ? Icons.nights_stay : Icons.nights_stay_outlined,
                      key: ValueKey(isDark),
                      color: AppColors.gold,
                      size: 22,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Menu Grid ─────────────────────────────────────────
  Widget _buildGrid(BuildContext context, bool isDark, TextTheme textTheme) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.88,
      ),
      itemCount: _menuItems.length,
      itemBuilder: (context, index) =>
          _buildMenuCard(context, index, isDark, textTheme),
    );
  }

  Widget buildIcon(MenuItem item, double size, Color iconColor) {
    // 👉 SVG or PNG
    if (item.asset != null) {
      if (item.asset!.endsWith('.svg')) {
        return SvgPicture.asset(
          item.asset!,
          height: size,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        );
      } else {
        return Image.asset(item.asset!, height: size, color: iconColor);
      }
    }
    return Icon(item.icon, size: size, color: iconColor);
  }

  // ── Single Menu Card ──────────────────────────────────
  Widget _buildMenuCard(
    BuildContext context,
    int index,
    bool isDark,
    TextTheme textTheme,
  ) {
    final item = _menuItems[index];
    final iconColor = isDark
        ? AppColors.darkCardIconColors[index %
              AppColors.darkCardIconColors.length]
        : AppColors.lightCardIconColors[index %
              AppColors.lightCardIconColors.length];

    return GestureDetector(
      onTap: () => _handleNavigation(context, index),

      // Navigate to the feature screen
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: AppGradients.cardGradient(index: index, isDark: isDark),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          boxShadow: isDark
              ? AppShadows.cardShadowDark
              : AppShadows.cardShadowLight,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            //Icon(item.icon, color: iconColor, size: 34),
            buildIcon(item, 40, iconColor),
            const SizedBox(height: 10),
            // Label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  color: iconColor,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    final pages = <Widget>[
      const GoldenChainPage(), // 0 — Golden Chain
      const WeeklyDhikrPage(), // 1 — Weekly Dhikr
      const SalatPage(), // 2 — Salat
      const DalailKhairatPage(), // 3 — Dalail Ul Khairat
      const HizbulAzamPage(), // 4 — Hizbu-l-Azam
      const DailyAwradPage(), // 5 — Daily Awrad
      const MonthlyAwradPage(), // 6 — Monthly Awrad
      const QuranPage(), // 7 — Quran
      const BooksPage(), // 8 — Books
      const QiblahCompassPage(), // 9 — Qiblah Compass
      const NasheedsPage(), // 10 — Nasheeds
      const DuasPage(), // 11 — Duas
    ];

    Navigator.push(context, MaterialPageRoute(builder: (_) => pages[index]));
  }
}
