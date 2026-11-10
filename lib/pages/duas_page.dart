import 'package:flutter/material.dart';
import '../service/api_service.dart';
import '../models/dua_model.dart';
import '../config/app_theme.dart';

class DuasPage extends StatefulWidget {
  const DuasPage({super.key});

  @override
  State<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends State<DuasPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Dua>?> _duaListFuture;

  @override
  void initState() {
    super.initState();
    _duaListFuture = _apiService.getRabbanaDua('app-rabbana-duas');
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
              'Duas & Salawat',
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

  // ── Body ─────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, bool isDark) {
    return FutureBuilder<List<Dua>?>(
      future: _duaListFuture,
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );
        }

        // Error
        if (snapshot.hasError) {
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
                    'Failed to load Duas',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkSubText
                          : AppColors.lightSubText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _duaListFuture = _apiService.getAllDuas();
                    }),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        final duas = snapshot.data ?? [];

        // Empty state
        if (duas.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.library_books_rounded,
                    color: AppColors.gold,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Duas Available',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Check back later for more duas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkSubText
                          : AppColors.lightSubText,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: duas.length,
          itemBuilder: (context, index) {
            return _buildDuaCard(context, isDark, duas[index], index);
          },
        );
      },
    );
  }

  // ── Dua Card ────────────────────────────────────────────────
  Widget _buildDuaCard(BuildContext context, bool isDark, Dua dua, int index) {
    final gradientIndex = index % AppColors.lightCardGradients.length;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: isDark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => _buildDuaDetailSheet(context, isDark, dua),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          boxShadow: isDark
              ? AppShadows.cardShadowDark
              : AppShadows.cardShadowLight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Number circle ────────────────────
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? AppColors.darkCardGradients[gradientIndex]
                        : AppColors.lightCardGradients[gradientIndex],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkCardIconColors[gradientIndex]
                          : AppColors.lightCardIconColors[gradientIndex],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // ── Dua details ─────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      dua.title ?? 'Dua',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkText
                            : AppColors.lightText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Category + Occasion
                    Text(
                      '${dua.category ?? 'General'} • ${dua.occasion ?? 'Anytime'}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkSubText
                            : AppColors.lightSubText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Arabic dua preview
                    // if (dua.duaText != null)
                    //   Text(
                    //     dua.duaText!,
                    //     style: const TextStyle(
                    //       fontFamily: 'alKitab',
                    //       fontSize: 14,
                    //       // height: 1.6,
                    //     ),
                    //     maxLines: 2,
                    //     overflow: TextOverflow.ellipsis,
                    //     textAlign: TextAlign.right,
                    //   ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // ── Arrow icon ──────────────────────
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? AppColors.darkSubText : AppColors.lightSubText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dua Detail Sheet ────────────────────────────────────────
  Widget _buildDuaDetailSheet(BuildContext context, bool isDark, Dua dua) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Title ───────────────────────
                Text(
                  dua.title ?? 'Dua',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),

                const SizedBox(height: 8),

                // ── Metadata ────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dua.category ?? 'General',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dua.occasion ?? 'Anytime',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Description ─────────────────
                if (dua.description != null && dua.description!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dua.description!.replaceAll('<br/>', '\n'),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          height: 1.6,
                          color: isDark
                              ? AppColors.darkSubText
                              : AppColors.lightSubText,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                // ── Arabic Dua ──────────────────
                if (dua.duaText != null && dua.duaText!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dua (Arabic)',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          dua.duaText!.replaceAll('<br/>', '\n'),
                          style: const TextStyle(
                            fontFamily: 'Neirizi',
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                            height: 3.0,
                            letterSpacing: 0.5,
                            wordSpacing: 4.0,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                // ── Transliteration ─────────────────
                if (dua.transliteration != null &&
                    dua.transliteration!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transliteration',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground
                              : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          dua.transliteration!.replaceAll('<br/>', '\n'),
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            height: 1.8,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                // ── Translation ─────────────────
                if (dua.duaTranslation != null &&
                    dua.duaTranslation!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Translation',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground
                              : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          dua.duaTranslation!.replaceAll('<br/>', '\n'),
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            height: 1.6,
                            color: isDark
                                ? AppColors.darkText
                                : AppColors.lightText,
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}
