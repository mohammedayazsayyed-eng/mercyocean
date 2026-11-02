import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../service/api_service.dart';
import '../utils/html_text_utils.dart';

class MonthDetailPage extends StatefulWidget {
  final String title;
  final String slug;

  const MonthDetailPage({super.key, required this.title, required this.slug});

  @override
  State<MonthDetailPage> createState() => _MonthDetailPageState();
}

class _MonthDetailPageState extends State<MonthDetailPage> {
  final ApiService _apiService = ApiService();
  late Future<String?> _contentFuture;

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

  Future<void> _handleLinkTap(String? url) async {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link')));
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
          const SizedBox(width: 42),
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Html(
            data: preventHyphenLineBreaks(snapshot.data!),
            onLinkTap: (url, attributes, element) => _handleLinkTap(url),
            style: {
              'body': Style(
                fontFamily: 'Nunito',
                fontSize: FontSize(14),
                color: isDark ? AppColors.darkText : AppColors.lightText,
                lineHeight: LineHeight(1.8),
              ),
              'p.arabic-content': Style(
                fontFamily: 'Neirizi',
                fontSize: FontSize(15),
                fontWeight: FontWeight(500),
                lineHeight: LineHeight(2.0),
                direction: TextDirection.rtl,
                textAlign: TextAlign.right,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
              'h1': Style(
                fontFamily: 'Poppins',
                fontSize: FontSize(20),
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
              'h2': Style(
                fontFamily: 'Poppins',
                fontSize: FontSize(18),
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
              'h3': Style(
                fontFamily: 'Poppins',
                fontSize: FontSize(16),
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
              ),
              'li': Style(
                fontFamily: 'Nunito',
                fontSize: FontSize(14),
                lineHeight: LineHeight(1.8),
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            },
          ),
        );
      },
    );
  }
}
