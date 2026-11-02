import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../service/api_service.dart';
import '../config/app_theme.dart';
import '../config/app_state.dart';
import '../models/wordpress_post_model.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
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
      final result = await ApiService().getPages('introduction');
      if (mounted) {
        setState(() {
          _posts = result ?? [];
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
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
          ShaderMask(
            shaderCallback: (bounds) =>
                AppGradients.goldShimmer.createShader(bounds),
            child: const Text(
              'Introduction',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 22),
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

    if (_error != null) {
      return _buildError();
    }

    if (_posts.isEmpty) {
      return _buildEmpty(isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _posts.length,
      itemBuilder: (context, index) =>
          _buildContent(_posts[index], isDark, showImage: index == 0),
    );
  }

  // ── Content ──────────────────────────────────────────────────
  Widget _buildContent(
    WordpressPost post,
    bool isDark, {
    bool showImage = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        //color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: isDark
            ? AppShadows.cardShadowDark
            : AppShadows.cardShadowLight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showImage)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 30),
                child: SizedBox(
                  width: 250,
                  height: 250,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(
                            0,
                            3,
                          ), // Changes position of shadow (dx, dy)
                        ),
                      ],
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/images/icons/intro_page_2.jpeg',
                        ),
                        fit: BoxFit.cover,
                      ),
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground,
                    ),
                    // child: Image.asset(
                    //   'assets/images/icons/new_intro.jpeg',

                    //   //width: 100,
                    //   //height: 100,
                    //   fit: BoxFit.cover,
                    // ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  child: Html(
                    data: post.content,
                    style: {
                      'body': Style(
                        fontFamily: 'Nunito',
                        fontSize: FontSize(15),
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                        lineHeight: LineHeight(1.7),
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      'p': Style(
                        margin: Margins.only(bottom: 12),
                        textAlign: TextAlign.justify,
                      ),
                      'h1': Style(),
                      'h2': Style(),
                      'h3': Style(),
                      'a': Style(
                        color: AppColors.gold,
                        textDecoration: TextDecoration.underline,
                      ),
                      'strong': Style(),
                      'blockquote': Style(),
                      'img': Style(
                        width: Width(100, Unit.percent),
                        display: Display.block,
                      ),
                    },
                  ),
                );
              },
            ),
          ),
        ],
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
