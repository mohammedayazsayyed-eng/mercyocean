import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../service/api_service.dart';
import '../config/app_theme.dart';
import '../config/app_state.dart';
import '../models/wordpress_post_model.dart';

class Shaykhnazim extends StatefulWidget {
  const Shaykhnazim({super.key});

  @override
  State<Shaykhnazim> createState() => _ShaykhnazimState();
}

class _ShaykhnazimState extends State<Shaykhnazim> {
  List<WordpressPost> _posts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getData();
  }

  Future<void> _getData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      // print('📡 Fetching shaykh-nazim...');
      final result = await ApiService().getPages('shaykh-nazim-qsa');
      // print('📦 Result length: ${result?.length}');
      if (mounted) {
        setState(() {
          _posts = result ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      // print('❌ Error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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

  // ── App Bar ─────────────────────────────────────────────────
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
            onTap: () => navIndexNotifier.value = 2,
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/icons/shaykh-nazim.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppGradients.goldShimmer.createShader(bounds),
                child: const Text(
                  'Shaykh Nazim',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────
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

  // ── Content ──────────────────────────────────────────────────
  Widget _buildContent(WordpressPost post, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: isDark
            ? AppShadows.cardShadowDark
            : AppShadows.cardShadowLight,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            child: Html(
              data: post.content,
              extensions: [
                TagExtension(
                  tagsToExtend: {'img'},
                  builder: (context) {
                    final src = context.attributes['src'] ?? '';
                    final isValid =
                        src.startsWith('http://') || src.startsWith('https://');
                    if (!isValid) return const SizedBox.shrink();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        src,
                        fit: BoxFit.fill,
                        alignment: Alignment.center,
                        errorBuilder: (_, _, err) => const SizedBox.shrink(),
                      ),
                    );
                  },
                ),
              ],
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
                  fontFamily: 'Nunito',
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontSize: FontSize(15),
                  lineHeight: LineHeight(1.7),
                  margin: Margins.only(bottom: 12),
                  textAlign: TextAlign.justify,
                ),
                'a': Style(
                  color: AppColors.gold,
                  textDecoration: TextDecoration.underline,
                ),
                'strong': Style(
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                  fontWeight: FontWeight.w700,
                ),
                'blockquote': Style(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.08),
                  padding: HtmlPaddings.symmetric(horizontal: 16, vertical: 12),
                  border: const Border(
                    left: BorderSide(color: AppColors.gold, width: 3),
                  ),
                ),
                'img': Style(
                  width: Width(300, Unit.percent),
                  height: Height(300),
                  display: Display.block,
                  alignment: Alignment.center,
                ),
              },
            ),
          );
        },
      ),
    );
  }

  // ── Error State ──────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.gold, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Could not load content',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _getData();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────
  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Text(
        'No content found.',
        style: TextStyle(
          fontFamily: 'Nunito',
          color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
        ),
      ),
    );
  }
}
