import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/app_theme.dart';

class GenericFeaturePage extends StatelessWidget {
  final String title;
  final String description;
  final dynamic icon; // IconData or Widget (SVG)
  final String? assetPath; // SVG asset path
  final LinearGradient gradient;

  const GenericFeaturePage({
    super.key,
    required this.title,
    required this.description,
    required this.gradient,
    this.icon,
    this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

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
              // ── App Bar ──────────────────────────
              _buildAppBar(context, isDark),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),

                      // ── Icon Container ────────────────
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: AppShadows.cardShadowDark,
                        ),
                        child: Center(child: _buildIcon()),
                      ),

                      const SizedBox(height: 28),

                      // ── Title ─────────────────────────
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppGradients.goldShimmer.createShader(bounds),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Gold divider ──────────────────
                      Container(
                        width: 48,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: AppGradients.goldShimmer,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Description ───────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isDark
                              ? AppShadows.cardShadowDark
                              : AppShadows.cardShadowLight,
                        ),
                        child: Text(
                          description,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(
                            height: 1.8,
                            color: isDark
                                ? AppColors.darkSubText
                                : AppColors.lightSubText,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Coming Soon badge ─────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppGradients.goldShimmer,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppShadows.goldGlow,
                        ),
                        child: const Text(
                          'Coming Soon',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
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
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 42), // balance the back button
        ],
      ),
    );
  }

  Widget _buildIcon() {
    // SVG asset path
    if (assetPath != null && assetPath!.endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath!,
        width: 54,
        height: 54,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      );
    }
    // Widget passed directly
    if (icon is Widget) {
      return icon as Widget;
    }
    // IconData
    if (icon is IconData) {
      return Icon(icon as IconData, size: 54, color: Colors.white);
    }
    return const SizedBox();
  }
}
