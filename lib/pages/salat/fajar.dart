import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:mercyocean/models/wordpress_post_model.dart';
import 'package:mercyocean/service/api_service.dart';
import 'package:mercyocean/config/app_theme.dart';

class FajarPage extends StatefulWidget {
  const FajarPage({super.key});

  @override
  State<FajarPage> createState() => _FajarPageState();
}

class _FajarPageState extends State<FajarPage> {
  List<WordpressPost> _posts = [];
  bool _isLoading = true;
  String? _error;
  bool _showArabic = false;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  Future<void> _getData() async {
    try {
      final result = await ApiService().getPages('fajr-salah');
      if (!mounted) return;
      setState(() {
        _posts = result ?? [];
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

  String _formatHtml(String rawHtml, bool isDark) {
    final titleColor = isDark ? '#4ADE80' : '#0E7C3A';

    // 1. Strip injected WordPress <style> blocks
    var html = rawHtml.replaceAll(
      RegExp(r'<style\b[^>]*>[\s\S]*?</style>', caseSensitive: false),
      '',
    );

    // 2. Color existing <strong> titles & <mark> notes
    html = html.replaceAllMapped(
      RegExp(
        r'<strong\b([^>]*)>(.*?)</strong>',
        caseSensitive: false,
        dotAll: true,
      ),
      (m) => '<strong${m[1]} style="color: $titleColor;">${m[2]}</strong>',
    );
    html = html.replaceAllMapped(
      RegExp(r'<mark\b[^>]*>(.*?)</mark>', caseSensitive: false, dotAll: true),
      (m) => '<span style="color: $titleColor; font-weight: 700;">${m[1]}</span>',
    );

    // 3. Highlight English titles at the start of a paragraph or after <br>
    final enTitleRegex = RegExp(
      r'((?:^|>|<br\s*/?>)\s*)(~?\s*(?:'
      r'[ṢS]al[āa]tu\s+(?:as-Sunnah|l-far[ḍd]|al-Munjiyah(?:/Tunj[īi]n[āa])?)(?:\s*\([^)]*\))?'
      r'|Kalimat\s+ash-Shah[āa]dah\s*:?'
      r'|Du[ʿ‘’\x27]?[āa][ʾ’\x27]?(?:\s+al-Qun[ūu]t\.?|\s+recited\s+by\s+the\s+imam)?\s*:?'
      r'|Ihd[āa][’\x27]?\s*:?'
      r'|Iqamat\s+as-Salah\.?'
      r'|Tasb[īi][ḥh]\s*:?'
      r'|Al-Istighf[āa]r\s*:?'
      r'|[ṢS]alaw[āa]t(?:\s*\([^)]*\))?'
      r'|Surah\s+[A-Za-z\-]+(?:\s*\([^)]*\))?'
      r'|Surat\s+Y[āa]-S[īi]n\s*:?'
      r'|Al-F[āa]ti[ḥh]ah(?:\s*\([^)]*\))?\.?'
      r'|The\s+Imam\s+continues[^:<]*:?'
      r'|Lie\s+down[^:<]*:?'
      r'|Get\s+up[^:<]*:?'
      r'))',
      caseSensitive: false,
    );

    html = html.replaceAllMapped(
      enTitleRegex,
      (m) =>
          '${m[1]}<span style="color: $titleColor; font-weight: 700;">${m[2]}</span>',
    );

    // 4. Highlight Arabic titles (handles optional tashkeel/harakat between letters)
    const d = r'[\u064B-\u065F\u0670\u0640]*';
    final arTitleRegex = RegExp(
      '((?:^|>|<br\\s*/?>)\\s*)(~?\\s*(?:'
      'ص${d}ل${d}ا${d}ة${d}\\s+ا${d}ل${d}س${d}ن${d}ة${d}(?:\\s*\\([^)]*\\))?'
      '|ص${d}ل${d}ا${d}ة${d}\\s+ا${d}ل${d}ف${d}ر${d}ض${d}(?:\\s*\\([^)]*\\))?'
      '|ص${d}ل${d}ا${d}ة${d}\\s+ا${d}ل${d}م${d}ن${d}ج${d}ي${d}ة${d}'
      '|ك${d}ل${d}م${d}ة${d}\\s+ا${d}ل${d}ش${d}ه${d}ا${d}د${d}ة${d}\\s*:?'
      '|د${d}ع${d}ا${d}ء${d}(?:\\s+ا${d}ل${d}ق${d}ن${d}و${d}ت${d})?\\s*:?'
      '|ا${d}ل${d}د${d}ع${d}ا${d}ء${d}\\s*:?'
      '|إ${d}ه${d}د${d}ا${d}ء${d}\\s*:?'
      '|ا${d}ه${d}د${d}ا${d}ء${d}\\s*:?'
      '|إ${d}ق${d}ا${d}م${d}ة${d}\\s+ا${d}ل${d}ص${d}ل${d}ا${d}ة${d}'
      '|ا${d}ق${d}ا${d}م${d}ة${d}\\s+ا${d}ل${d}ص${d}ل${d}ا${d}ة${d}'
      '|ا${d}ل${d}ت${d}س${d}ب${d}ي${d}ح${d}\\s*:?'
      '|ت${d}س${d}ب${d}ي${d}ح${d}\\s*:?'
      '|ا${d}ل${d}ا${d}س${d}ت${d}غ${d}ف${d}ا${d}ر${d}\\s*:?'
      '|ص${d}ل${d}و${d}ا${d}ت${d}(?:\\s*\\([^)]*\\))?'
      '|س${d}و${d}ر${d}ة${d}\\s+[^<:.\\n(]+(?:\\s*\\([^)]*\\))?\\s*:?'
      '|ا${d}ل${d}ف${d}ا${d}ت${d}ح${d}ة${d}(?:\\s*\\([^)]*\\))?'
      '))',
    );

    html = html.replaceAllMapped(
      arTitleRegex,
      (m) =>
          '${m[1]}<span style="color: $titleColor; font-weight: 700;">${m[2]}</span>',
    );

    // 5. Render (ﷻ) and (ﷺ) cleanly inline inside English text using Neirizi
    html = html.replaceAllMapped(
      RegExp(r'([\uFDFA\uFDFB])'),
      (m) =>
          '<span style="font-family: \'Neirizi\'; font-size: 20px;">${m[1]}</span>',
    );

    return html;
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
              'Salatu l-Fajar',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
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
                boxShadow: isDark
                    ? AppShadows.cardShadowDark
                    : AppShadows.cardShadowLight,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
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
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
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
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: isDark
            ? AppShadows.cardShadowDark
            : AppShadows.cardShadowLight,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => SizedBox(
          width: constraints.maxWidth,
          child: Html(
            data: _formatHtml(post.content, isDark),
            style: {
              'body': Style(
                fontFamily: 'Nunito',
                fontSize: FontSize(16),
                color: isDark ? AppColors.darkText : AppColors.lightText,
                lineHeight: LineHeight(1.75),
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
              'p': Style(
                color: isDark ? AppColors.darkText : AppColors.lightText,
                fontSize: FontSize(16),
                lineHeight: LineHeight(1.75),
                padding: HtmlPaddings.only(bottom: 14),
                margin: Margins.only(bottom: 14),
                border: Border(
                  bottom: BorderSide(color: dividerColor, width: 0.8),
                ),
                display: _showArabic ? Display.none : Display.block,
                direction: TextDirection.ltr,
                textAlign: TextAlign.left,
              ),
              'p.arabic-content': Style(
                fontFamily: 'Neirizi',
                fontSize: FontSize(19),
                fontWeight: FontWeight.w500,
                lineHeight: LineHeight(2.1),
                direction: TextDirection.rtl,
                display: _showArabic ? Display.block : Display.none,
                textAlign: TextAlign.right,
                padding: HtmlPaddings.only(bottom: 16),
                margin: Margins.only(bottom: 16),
                border: Border(
                  bottom: BorderSide(color: dividerColor, width: 0.8),
                ),
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              '*[lang="ar"]': Style(
                fontFamily: 'Neirizi',
                fontSize: FontSize(19),
                fontWeight: FontWeight.w500,
                lineHeight: LineHeight(2.1),
                direction: TextDirection.rtl,
                display: _showArabic ? Display.block : Display.none,
                textAlign: TextAlign.right,
                padding: HtmlPaddings.only(bottom: 16),
                margin: Margins.only(bottom: 16),
                border: Border(
                  bottom: BorderSide(color: dividerColor, width: 0.8),
                ),
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              'p.has-large-font-size': Style(
                fontFamily: 'Neirizi',
                fontSize: FontSize(19),
                fontWeight: FontWeight.w500,
                lineHeight: LineHeight(2.1),
                direction: TextDirection.rtl,
                display: _showArabic ? Display.block : Display.none,
                textAlign: TextAlign.right,
                padding: HtmlPaddings.only(bottom: 16),
                margin: Margins.only(bottom: 16),
                border: Border(
                  bottom: BorderSide(color: dividerColor, width: 0.8),
                ),
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              'div': Style(
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              'h1': Style(
                fontFamily: 'Poppins',
                color: AppColors.gold,
                fontSize: FontSize(24),
                fontWeight: FontWeight.w700,
                margin: Margins.only(bottom: 16),
              ),
              'h2': Style(
                fontFamily: 'Poppins',
                color: AppColors.gold,
                fontSize: FontSize(21),
                fontWeight: FontWeight.w700,
              ),
              'h3': Style(
                fontFamily: 'Poppins',
                color: AppColors.gold,
                fontSize: FontSize(19),
                fontWeight: FontWeight.w700,
              ),
              'h4': Style(
                fontFamily: 'Poppins',
                color: AppColors.gold,
                fontSize: FontSize(17),
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