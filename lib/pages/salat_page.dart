import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'package:mercyocean/pages/salat/adhan.dart';
import 'package:mercyocean/pages/salat/asar.dart';
import 'package:mercyocean/pages/salat/fajar.dart';
import 'package:mercyocean/pages/salat/isha.dart';
import 'package:mercyocean/pages/salat/magrib.dart';
import 'package:mercyocean/pages/salat/pre_fajar.dart';
import 'package:mercyocean/pages/salat/zuhar.dart';

class SalatPage extends StatelessWidget {
  const SalatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      {'title': 'Adhan', 'page': const AdhanPage()},
      {'title': 'Salatu l-Magrib', 'page': MagribPage()},
      {'title': 'Salatu l-Isha', 'page': const IshaPage()},
      {'title': 'Qiyamu l-Layl (Pre-Fajar)', 'page': PreFajarPage()},
      {'title': 'Salatu l-Fajar', 'page': const FajarPage()},
      {'title': 'Salatu z-Zuhar', 'page': const ZuharPage()},
      {'title': 'Salatu l-Asar', 'page': const AsarPage()},
    ];

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
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => Divider(
                    color: AppColors.gold.withOpacity(0.2),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    return _buildSalatItem(
                      context,
                      isDark,
                      items[index]['title'] as String,
                      items[index]['page'] as Widget,
                    );
                  },
                ),
              ),
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
              'Salah',
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

  Widget _buildSalatItem(
    BuildContext context,
    bool isDark,
    String title,
    Widget page,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),

              //margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                gradient: AppGradients.goldShimmer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.mosque_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
            ),
          ],
        ),
      ),
    );
  }
}
