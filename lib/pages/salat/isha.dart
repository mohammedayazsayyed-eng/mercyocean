import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:mercyocean/models/wordpress_post_model.dart';
import 'package:mercyocean/service/api_service.dart';
import 'package:mercyocean/config/app_theme.dart';

class IshaPage extends StatefulWidget {
  const IshaPage({super.key});

  @override
  _IshaPageState createState() => _IshaPageState();
}

class _IshaPageState extends State<IshaPage> {
  List<WordpressPost> _posts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  Future<void> _getData() async {
    try {
      final result = await ApiService().getPages('salatul-isha');
      setState(() {
        _posts = (result ?? []).where((p) => p.slug == 'salatul-isha').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
              'Salatu l-Isha',
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

  Widget _buildBody(BuildContext context, bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (_error != null) return _buildError();
    if (_posts.isEmpty) return _buildEmpty(isDark);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _posts.map((post) => _buildContent(post, isDark)).toList(),
      ),
    );
  }

  Widget _buildContent(WordpressPost post, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        //color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: isDark
            ? AppShadows.cardShadowDark
            : AppShadows.cardShadowLight,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          width: constraints.maxWidth,
          child: Html(
            // ─── HTML Pre-Processing ───────────────────────────────────────
            // WordPress sometimes injects its own <style> blocks inside the
            // post content that override our app's text colors. We remove
            // those blocks first so our theme (dark / light) stays in control.
            //
            // We also recolor any <strong> text that starts with a number
            // (e.g.  <strong>1. Niyyah</strong>  or  <strong>3. Ruku</strong>)
            // so that numbered steps appear in green and are easy to find.
            //   • Dark  mode → bright green  #4ADE80
            //   • Light mode → deep  green   #0E7C3A
            data: post.content
                .replaceAll(
                  // Matches the whole <style> ... </style> block and deletes it
                  RegExp(
                    r'<style\b[^>]*>[\s\S]*?</style>',
                    caseSensitive: false,
                  ),
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
            // ──────────────────────────────────────────────────────────────
            style: {
              'body': Style(
                fontFamily: 'Nunito',
                fontSize: FontSize(15),
                color: isDark ? AppColors.darkText : AppColors.lightText,
                lineHeight: LineHeight(1.7),
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
              'p': Style(
                color: isDark ? AppColors.darkText : AppColors.lightText,
                fontSize: FontSize(15),
                margin: Margins.only(bottom: 12),
                direction: TextDirection.ltr,
                textAlign: TextAlign.justify,
              ),
              'p.has-large-font-size': Style(
                fontFamily: 'Neirizi',
                fontSize: FontSize(25),
                fontWeight: FontWeight(700),
                lineHeight: LineHeight(2.0),
                direction: TextDirection.rtl,
                textAlign: TextAlign.right,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              'div': Style(
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              'h1': Style(
                fontFamily: 'Poppins',
                color: AppColors.gold,
                fontSize: FontSize(26),
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
          ),
        ),
      ),
    );
  }

  Widget _buildError() => Center(
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

  Widget _buildEmpty(bool isDark) => Center(
    child: Text(
      'No content found.',
      style: TextStyle(
        fontFamily: 'Nunito',
        color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
      ),
    ),
  );
}
