import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../config/app_theme.dart';
import '../service/api_service.dart';

class DalailSectionPage extends StatefulWidget {
  final String title;
  final String slug;

  const DalailSectionPage({super.key, required this.title, required this.slug});

  @override
  State<DalailSectionPage> createState() => _DalailSectionPageState();
}

// These sections have no Arabic content, so the EN/AR toggle is hidden for them.
const Set<String> _slugsWithoutArabic = {
  'method-to-read-dalail-al-khayrat',
  'app-asma-ul-husna',
  'app-asma-an-nabi',
};

class _DalailSectionPageState extends State<DalailSectionPage> {
  final ApiService _apiService = ApiService();
  late Future<String?> _contentFuture;
  bool _showArabic = false;

  bool get _hasArabicToggle => !_slugsWithoutArabic.contains(widget.slug);

  @override
  void initState() {
    super.initState();
    _contentFuture = _fetchContent();
  }

  Future<String?> _fetchContent() async {
    final pages = await _apiService.getPages(widget.slug);
    if (pages == null || pages.isEmpty) return null;
    return pages[0].content;
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
            shaderCallback: (bounds) =>
                AppGradients.goldShimmer.createShader(bounds),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),

          if (!_hasArabicToggle)
            const SizedBox(width: 42)
          else
            GestureDetector(
              onTap: () => setState(() => _showArabic = !_showArabic),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
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
                    // EN button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: !_showArabic
                            ? AppColors.gold
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: !_showArabic
                            ? null
                            : Border.all(
                                color: AppColors.gold.withValues(alpha: 0.4),
                                width: 1,
                              ),
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
                    // AR button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _showArabic
                            ? AppColors.gold
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: _showArabic
                            ? null
                            : Border.all(
                                color: AppColors.gold.withValues(alpha: 0.4),
                                width: 1,
                              ),
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

  Widget _buildBody(bool isDark) {
    return FutureBuilder<String?>(
      future: _contentFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.gold,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load content',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _contentFuture = _fetchContent();
                    }),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        final content = Html(
          data: snapshot.data!
              .replaceAll(
                // Matches the whole <style> ... </style> block and deletes it
                RegExp(r'<style\b[^>]*>[\s\S]*?</style>', caseSensitive: false),
                '',
              )
              .replaceAllMapped(
                // Matches <strong> whose text begins with a digit, e.g. "1. Step"
                RegExp(
                  r'<strong\b([^>]*)>(\s*\d[^<]*)</strong>',
                  caseSensitive: false,
                ),
                // Injects a green inline color so numbered steps stand out
                (m) =>
                    '<strong${m[1]} style="color: ${isDark ? '#4ADE80' : '#0E7C3A'};">${m[2]}</strong>',
              ),
          style: {
            'body': Style(
              fontFamily: 'Nunito',
              fontSize: FontSize(18),
              color: isDark ? AppColors.darkText : AppColors.lightText,
              lineHeight: LineHeight(1.7),
              margin: Margins.zero,
              padding: HtmlPaddings.zero,
              textAlign: TextAlign.justify,
            ),
            'p': Style(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontSize: FontSize(18),
              margin: Margins.only(bottom: 12),
              display: _showArabic ? Display.none : Display.block,
              direction: TextDirection.ltr,
              textAlign: TextAlign.justify,
            ),
            '*[lang="ar"]': Style(
              fontFamily: 'Neirizi',
              fontSize: FontSize(20),
              lineHeight: LineHeight(2.0),
              textAlign: TextAlign.justify,
              direction: TextDirection.rtl,
              margin: Margins.zero,
              // Hide Arabic paragraphs when English is active
              display: _showArabic ? Display.block : Display.none,
            ),

            'div': Style(
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
            'p.arabic-content': Style(
              fontFamily: 'Neirizi',
              fontSize: FontSize(22),
              fontWeight: FontWeight(500),
              lineHeight: LineHeight(2.0),
              direction: TextDirection.rtl,
              display: _showArabic ? Display.block : Display.none,
              textAlign: TextAlign.justify,
              margin: Margins.zero,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
            'h1': Style(
              fontFamily: 'Poppins',
              color: AppColors.gold,
              fontSize: FontSize(20),
              fontWeight: FontWeight.w700,
            ),
            'h2': Style(
              fontFamily: 'Poppins',
              color: AppColors.gold,
              fontSize: FontSize(22),
              fontWeight: FontWeight.w700,
            ),
            'h3': Style(
              fontFamily: 'Poppins',
              color: AppColors.gold,
              fontSize: FontSize(20),
              fontWeight: FontWeight.w700,
            ),
            'h4': Style(
              fontFamily: 'Poppins',
              color: AppColors.gold,
              fontSize: FontSize(18),
              fontWeight: FontWeight.w700,
            ),
            'img': Style(
              width: Width(100, Unit.percent),
              display: Display.block,
            ),
          },
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: content,
        );
      },
    );
  }
}
