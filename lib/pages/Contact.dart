import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:mercyocean/config/app_theme.dart';
import 'package:mercyocean/config/app_state.dart';
import 'package:mercyocean/models/wordpress_post_model.dart';
import 'package:mercyocean/service/api_service.dart';

class ContactUs extends StatefulWidget {
  const ContactUs({super.key});

  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs> {
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
      final result = await ApiService().getPages('app-contact-page');
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
              Expanded(
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: _buildBody(context, isDark),
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
              'Contact Us',
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

    if (_error != null) {
      return _buildError();
    }

    if (_posts.isEmpty) {
      return _buildEmpty(isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        return _buildContent(_posts[index], isDark);
      },
    );
  }

  Widget _buildContent(WordpressPost post, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
                  margin: Margins.only(bottom: 12),
                  textAlign: TextAlign.justify,
                ),
                'a': Style(
                  color: AppColors.gold,
                  textDecoration: TextDecoration.underline,
                ),
                'img': Style(
                  width: Width(100, Unit.percent),
                  display: Display.block,
                ),
              },
            ),
          );
        },
      ),
    );
  }

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
