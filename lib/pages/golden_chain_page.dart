import 'package:flutter/material.dart';
import '../service/api_service.dart';
import '../config/app_theme.dart';

class GoldenChainPage extends StatefulWidget {
  const GoldenChainPage({super.key});

  @override
  State<GoldenChainPage> createState() => _GoldenChainPageState();
}

class _GoldenChainPageState extends State<GoldenChainPage> {
  bool _isLoading = true;
  String? _error;
  List<String> _chainNames = [];

  @override
  void initState() {
    super.initState();
    _getData();
  }

  Future<void> _getData() async {
    try {
      final result = await ApiService().getPages('naqshbandi-golden-chain_mobile');
      final posts = result ?? [];
      final names = <String>[];
      for (final post in posts) {
        names.addAll(_extractNames(post.content));
      }
      if (mounted) {
        setState(() {
          _chainNames = names;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Extracts plain-text names from <li> tags, falling back to numbered <p> tags.
  List<String> _extractNames(String html) {
    final liRegex = RegExp(r'<li[^>]*>([\s\S]*?)<\/li>', caseSensitive: false);
    final liMatches = liRegex.allMatches(html).toList();
    if (liMatches.isNotEmpty) {
      return liMatches
          .map((m) => _clean(m.group(1) ?? ''))
          .where((s) => s.isNotEmpty)
          .toList();
    }

    final pRegex = RegExp(
      r'<p[^>]*>\s*\d+[.)]\s*([\s\S]*?)\s*<\/p>',
      caseSensitive: false,
    );
    return pRegex
        .allMatches(html)
        .map((m) => _clean(m.group(1) ?? ''))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  String _clean(String raw) => raw
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&amp;', '&')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#8217;', '’')
      .replaceAll('&#8216;', '‘')
      .replaceAll(RegExp(r'^\d+[.)]\s*'), '')
      .trim();

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
              'Golden Chain',
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }
    if (_error != null) return _buildError();
    if (_chainNames.isEmpty) return _buildEmpty(isDark);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: _chainNames.length,
      itemBuilder: (context, index) =>
          _buildChainItem(index, _chainNames[index], isDark),
    );
  }

  Widget _buildChainItem(int index, String name, bool isDark) {
    final isFirst = index == 0;
    final isLast = index == _chainNames.length - 1;
    final lineColor = AppColors.gold.withValues(alpha: isDark ? 0.35 : 0.4);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline spine ───────────────────────────
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top connector — equal flex keeps medallion vertically centred
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : lineColor,
                  ),
                ),

                // Gold numbered medallion
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.goldLight, AppColors.goldDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: isDark ? 0.55 : 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                // Bottom connector — equal flex to top
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : lineColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ── Name card ────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF0F1420), Color(0xFF141A2C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            AppColors.lightSurface,
                            AppColors.goldSurface.withValues(alpha: 0.25),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: isDark ? 0.18 : 0.2),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? AppShadows.cardShadowDark
                      : AppShadows.cardShadowLight,
                ),
                child: Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
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
