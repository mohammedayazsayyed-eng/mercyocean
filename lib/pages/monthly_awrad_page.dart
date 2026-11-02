import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../config/app_theme.dart';
import 'month_detail_page.dart';

class IslamicMonth {
  final String name;
  final String arabicName;
  final int monthNumber;
  final String description;
  final String? slug;

  IslamicMonth({
    required this.name,
    required this.arabicName,
    required this.monthNumber,
    required this.description,
    this.slug,
  });
}

class MonthlyAwradPage extends StatefulWidget {
  const MonthlyAwradPage({super.key});

  @override
  State<MonthlyAwradPage> createState() => _MonthlyAwradPageState();
}

class _MonthlyAwradPageState extends State<MonthlyAwradPage> {
  late int currentIslamicDay;
  late int currentIslamicMonth;
  late int currentIslamicYear;

  @override
  void initState() {
    super.initState();
    _calculateCurrentIslamicDate();
  }

  void _calculateCurrentIslamicDate() {
    final hijri = HijriCalendar.now();
    currentIslamicDay = hijri.hDay;
    currentIslamicMonth = hijri.hMonth;
    currentIslamicYear = hijri.hYear;
  }

  final List<IslamicMonth> islamicMonths = [
    IslamicMonth(
      name: 'Muharram',
      arabicName: 'محرم',
      monthNumber: 1,
      description: 'The Sacred Month',
      slug: 'wazifa-muharram',
    ),
    IslamicMonth(
      name: 'Safar',
      arabicName: 'صفر',
      monthNumber: 2,
      description: 'The Month of Travel',
      slug: 'duties-of-the-month-of-safar-ul-khayr',
    ),
    IslamicMonth(
      name: 'Rabi\' Al-Awwal', //
      arabicName: 'ربيع الأول',
      monthNumber: 3,
      description: 'Birth Month of Prophet Muhammad ﷺ',
      slug: 'duties-of-the-month-of-rabih-al-awwal',
    ),
    IslamicMonth(
      name: 'Rabi\' Al-Thani', //not on website
      arabicName: 'ربيع الثاني',
      monthNumber: 4,
      description: 'The Second Rabi\' Month',
      slug: null,
    ),
    IslamicMonth(
      name: 'Jumada Al-Awwal', // not on website
      arabicName: 'جمادى الأولى',
      monthNumber: 5,
      description: 'The First Jumada',
      slug: null,
    ),
    IslamicMonth(
      name: 'Jumada Al-Thani', // not on website
      arabicName: 'جمادى الثانية',
      monthNumber: 6,
      description: 'The Second Jumada',
      slug: null,
    ),
    IslamicMonth(
      name: 'Rajab',
      arabicName: 'رجب',
      monthNumber: 7,
      description: 'The Month of Reverence',
      slug: 'duties-of-the-month-of-rajab',
    ),
    IslamicMonth(
      name: 'Sha\'ban',
      arabicName: 'شعبان',
      monthNumber: 8,
      description: 'Preparation for Ramadan',
      slug: 'adab-of-the-night-baraah-15th-of-shaban',
    ),
    IslamicMonth(
      name: 'Ramadan',
      arabicName: 'رمضان',
      monthNumber: 9,
      description: 'The Month of Fasting & Quran',
      slug: 'duas-to-recite-in-ramadan',
    ),
    IslamicMonth(
      name: 'Shawwal',
      arabicName: 'شوال',
      monthNumber: 10,
      description: 'Month of Eid Al-Fitr',
      slug: null,
    ),
    IslamicMonth(
      name: 'Dhu Al-Qi\'dah',
      arabicName: 'ذو القعدة',
      monthNumber: 11,
      description: 'The Month of Sitting',
      slug: null,
    ),
    IslamicMonth(
      name: 'Dhu Al-Hijjah',
      arabicName: 'ذو الحجة',
      monthNumber: 12,
      description: 'Month of Hajj & Eid Al-Adha',
      slug: 'duties-of-the-month-of-dhul-hijjah',
    ),
  ];

  // Your card gradients — same as home screen cards
  List<Color> _getMonthGradient(int monthNumber, bool isDark) {
    final index = (monthNumber - 1) % AppColors.lightCardGradients.length;
    return isDark
        ? AppColors.darkCardGradients[index]
        : AppColors.lightCardGradients[index];
  }

  Color _getMonthIconColor(int monthNumber, bool isDark) {
    final index = (monthNumber - 1) % AppColors.lightCardIconColors.length;
    return isDark
        ? AppColors.darkCardIconColors[index]
        : AppColors.lightCardIconColors[index];
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
              // ── App Bar ──────────────────────────
              _buildAppBar(context, isDark),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ── Current Date Card ─────────────
                      _buildCurrentDateCard(isDark),
                      const SizedBox(height: 24),

                      // ── Title ─────────────────────────
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppGradients.goldShimmer.createShader(bounds),
                        child: const Text(
                          'Islamic Months',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Months Grid ───────────────────
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive childAspectRatio based on screen size
                          double childAspectRatio = 0.75;
                          if (constraints.maxWidth > 600) {
                            childAspectRatio = 0.85;
                          } else if (constraints.maxWidth < 350) {
                            childAspectRatio = 0.65;
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: childAspectRatio,
                                ),
                            itemCount: islamicMonths.length,
                            itemBuilder: (context, index) {
                              final month = islamicMonths[index];
                              final isCurrent =
                                  month.monthNumber == currentIslamicMonth;
                              return _buildMonthCard(month, isCurrent, isDark);
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 24),
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
              'Hijri Calender',
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

  // ── Current Date Card ────────────────────────────────────────
  Widget _buildCurrentDateCard(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.goldShimmer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.goldGlow,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Current Islamic Date',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dateBlock(currentIslamicDay.toString().padLeft(2, '0'), 'Date'),
              _divider(),
              _dateBlock(
                currentIslamicMonth.toString().padLeft(2, '0'),
                'Month',
              ),
              _divider(),
              _dateBlock(currentIslamicYear.toString(), 'Year (AH)'),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Based on your device\'s local timezone',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontFamily: 'Nunito',
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 40,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    color: Colors.white38,
  );

  Widget _dateBlock(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }

  // ── Month Card ───────────────────────────────────────────────
  Widget _buildMonthCard(IslamicMonth month, bool isCurrent, bool isDark) {
    final gradientColors = _getMonthGradient(month.monthNumber, isDark);
    final iconColor = _getMonthIconColor(month.monthNumber, isDark);

    return GestureDetector(
      onTap: month.slug != null
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MonthDetailPage(title: month.name, slug: month.slug!),
              ),
            )
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: isCurrent
              ? Border.all(color: AppColors.gold, width: 2)
              : null,
          boxShadow: isDark
              ? AppShadows.cardShadowDark
              : AppShadows.cardShadowLight,
        ),
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (isCurrent)
        Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: AppGradients.goldShimmer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Current',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (isCurrent) const SizedBox(height: 8),
            Text(
              month.monthNumber.toString(),
              style: TextStyle(
                color: iconColor,
                fontSize: 26,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              month.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: iconColor,
                fontSize: 20,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              month.arabicName,
              style: TextStyle(
                color: iconColor.withOpacity(0.85),
                fontSize: 25,
                fontFamily: 'alKitab',
                fontWeight: FontWeight(700),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              month.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: iconColor.withOpacity(0.7),
                fontSize: 12,
                fontFamily: 'Nunito',
              ),
            ),
            // Coming soon indicator for months without content
            if (month.slug == null) ...[
              const SizedBox(height: 6),
              Text(
                'Coming Soon',
                style: TextStyle(
                  color: iconColor.withOpacity(0.5),
                  fontSize: 10,
                  fontFamily: 'Nunito',
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}
