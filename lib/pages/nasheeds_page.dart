import 'package:flutter/material.dart';
import '../config/app_theme.dart';

// ── Nasheed data model ───────────────────────────────────────
class _Nasheed {
  final String title;
  final String lyrics;
  const _Nasheed({required this.title, required this.lyrics});
}

const List<_Nasheed> _nasheeds = [
  _Nasheed(
    title: 'THE OPENING QASIDA',
    lyrics: '''Ya Rabbi şalli 'alā Muḥammad
Ya Rabbi ṣalli 'alayhi wa sallim

Ya Rabbi ṣalli 'alā Muḥammad
Ya Rabbi balligh-hu 'l-wasilah

Ya Rabbi şalli 'alā Muḥammad
Ya Rabbi khuşşah bi 'l-fadilah

Ya Rabbi şalli 'alā Muḥammad
Ya Rabbi wa 'arḍā 'ani 's-ṣaḥābah

Ya Rabbi şalli 'alā Muḥammad
Ya Rabbi wa 'arḍā 'ani 's-sulalah

Ya Rabbi şalli 'alā Muḥammad
Ya Rabbi wa 'arḍā 'ani 'l-mashāyikh

Ya Rabbi şalli 'alā Muḥammad
Ya Rabbi farḥam wālidīna

Allahumma şalli 'alā Muḥammad
Ya Rabbi warḥamnā jamī'an

Allahumma şalli 'alā Muḥammad
Ya Rabbi warḥam kulla Muslim

Allahumma şalli 'alā Muḥammad
Ya Rabbi waghfir li-kulli mudhnib

Allahumma şalli 'alā Muḥammad
Ya Rabbi yā sāmi' du'ānā

Ya Rabbi salli 'alā Muḥammad
Ya Rabbi lā taqṭa' rajānā

Ya Rabbi şalli 'alā Muḥammad
Ya Rabbi ballighnā nazūruh

Ya Rabbi salli 'alā Muḥammad
Ya Rabbi taghshānā bi nūrih

Ya Rabbi şalli 'alā Muḥammad
Ya Rabbi ḥifṇānak wa amānak

Ya Rabbi şalli 'alā Muḥammad
Ya Rabbi wa 'skinnā jinānak

Ya Rabbi şalli 'alā Muḥammad
Ya Rabbi 'ajirnā min 'adhābik

Ya Rabbi şalli 'alā Muḥammad
Ya Rabbi warzuqnā 'ash-shahadah

Ya Rabbi şalli 'alā Muḥammad
Ya Rabbi hiṭnā bis-sa'ādah

Allahumma şalli 'alā Muḥammad
Ya Rabbi waşliḥ kulla musliḥ

Allahumma şalli 'alā Muḥammad
Ya Rabbi wakfī kulla mū'dhī

Allahumma şalli 'alā Muḥammad
Ya Rabbi nakhtim bil-mushaffa'

Allahumma şalli 'alā Muḥammad
Ya Rabbi ṣalli 'alayhi wa sallim''',
  ),
  _Nasheed(
    title: 'ALLAH ALLAH AGHISNA YA RASOOL ALLAH',
    lyrics: '''Allah Allah Aghisna Ya Rasool Allah,
Ya 'Adhimal Jah 'Alaika Sholawatullah

Abdun Bilbab Yartaji' Latsmal A'tab,
Jud Bil Jawab Marhaban Qod Qobalna

Antal Ma'ruf Bil Juudi Muqrid Dhuyuf,
Inni Malhuf Aghisni Bihaqqillah

Antal Ma'ruf Bil Juudi Muqrid Dhuyuf,
Inni Malhuf Aghisni Bihaqqillah

Allah Allah Aghisna Ya Rasool Allah,
Ya 'Adhimal Jah 'Alaika Sholawatullah

Antal Habibul A'dhom Sirrul Mujib,
Haa sha Yaakhib Man Laadza Birosulillah

Antal Habibul A'dhom Sirrul Mujib,
Haa sha Yaakhib Man Laadza Birosulillah

Allah Allah Aghisna Ya Rasool Allah,
Ya 'Adhimal Jah 'Alaika Sholawatullah

Allah Allah Aghisna Ya Rosulallah,
Ya 'Adhimal Jah 'Alaika Sholawatullah

Abdun Bilbab Yartaji' Latsmal A'tab,
Jud Bil Jawab Marhaban Qod Qobalna''',
  ),
  _Nasheed(
    title: 'ALLAH ALLAH - SHAYKH NAZIM',
    lyrics: '''Allah Allah Hu Allah, Allah Allah Haq Allah,
Allah Allah Ya Allah, La ILaha IL-Allah

Hasbi Rabbi Jallallah, Maafi Qalbi Gair'ulallah
Noor-e-Mohammad Sallalla, La ILaha IL-Allah
-
Shijra Paya Siddiqui, Shaykh Nazim Al-Haqqani
Rumi Aur Aap Jeelani, Shaykh Nazim Al-Haqqani

Allah Allah Hu Allah, Allah Allah Haq Allah,
Allah Allah Ya Allah, La ILaha IL-Allah

Awliya Tumko Jaane, Awliya Tumko Maney
Haqqani Tum Rabbani, Shaykh Nazim Al-Haqqani
-
Aal-E-Nabi Aaya Hai, Nazim Humne Paya Hai
Haza Min Fazli Rabbi, Shaykh Nazim Al-Haqqani

Allah Allah Hu Allah, Allah Allah Haq Allah,
Allah Allah Ya Allah, La ILaha IL-Allah

Meri Nisbat Hai Tumse, Meri Kismat Hai Tumse
Murshid Mera Rabbani, Shaykh Nazim Al-Haqqani
-
Qibris Wale Maulana, Mere Ghar Bhi Tum Aana
Meri Kismat Jagahna, Shaykh Nazim Al-Haqqani

Allah Allah Hu Allah, Allah Allah Haq Allah,
Allah Allah Ya Allah, La ILaha IL-Allah

Elahi Anta Maqsoodi, Wa Ridaaqa Matloobi,
Yeh Humne Tumse Seekha, Shaykh Nazim Al-Haqqani
-
Abdiyat Ka Martaba, Tumse Humne Hai Jaana
Yeh Khaadim Bhi Haazir Hai, Shaykh Nazim Al-Haqqani

Allah Allah Hu Allah, Allah Allah Haq Allah,
Allah Allah Ya Allah, La ILaha IL-Allah

Daghestani Peer Aapke, Istanbuli Khalifa
Chaalisve Sultan Aap Hai, Shaykh Nazim Al-Haqqani
-
Aapka Hukum Sar Aankhon Par, Shaykh Mehmat Abh Murshid Hai
Seerat Soorat Aapki Hai, Shaykh Nazim Al-Haqqani

Allah Allah Hu Allah, Allah Allah Haq Allah,
Allah Allah Ya Allah, La ILaha IL-Allah

Hasbi Rabbi Jalalallah, Maafi Qalbi Gair'ulallah
Noor-e-Mohammad Sallalla, La ILaha IL-Allah
-
Meri Nisbat Hai Tumse, Meri Kismat Hai Tumse
Murshid Mera Rabbani, Shaykh Nazim Al-Haqqani

Allah Allah Hu Allah, Allah Allah Haq Allah,
Allah Allah Ya Allah, La ILaha IL-Allah''',
  ),

  _Nasheed(
    title: 'YA SAYYIDI IRHAMLANA',
    lyrics: ''' Allah Allah, Allah Allah
Allah Allah, Allah Allah

Allah Allah, Allah Allah
Allah Allah, Allah Allah

Ya Sayyidi Irhamlana Ya Sayyidi Irhamlana
Ya Syayidi Irhamlana Ya Sayyidi Irhamlana

Innil Tiya ree Hassaba Youmun Ilaa Ardil Haram
Balligh Salaami Roudatun Feehannabiyul Mohtaram

Allah Allah, Allah Allah
Allah Allah, Allah Allah

Maw Wajhohu Shams-ud-Duha Mun Khaddohu Badr-ud-Duja
Maw Zaatohu Noor-ul-Huda Mun Kaffohu Bahr-ul-Hemam

Innil Tiya ree Hassaba Youmun Ilaa Ardil Haram
Balligh Salaami Roudatun Feehannabiyul Mohtaram

Allah Allah, Allah Allah
Allah Allah, Allah Allah

Allah Allah, Allah Allah
Allah Allah, Allah Allah

Qur’anuhu burhaanuna faskhal li’adyaanin madat,
Iz jaa’a naa ahkaamuhu kullus suhufi saaral adam

Innil Tiya ree Hassaba Youmun Ilaa Ardil Haram
Balligh Salaami Roudatun Feehannabiyul Mohtaram

Allah Allah, Allah Allah
Allah Allah, Allah Allah

Allah Allah, Allah Allah
Allah Allah, Allah Allah

Akbadona Majruhatumin Saifey Hijril Mustafa
Tooba Le-Ahle Baldatin Fee-hun-Nabiyul Mohtasham

Ya Sayyidi Irhamlana Ya Sayyidi Irhamlana
Ya Syayidi Irhamlana Ya Sayyidi Irhamlana

Innil Tiya ree Hassaba Youmun Ilaa Ardil Haram
Balligh Salaami Roudatun Feehannabiyul Mohtaram

Allah Allah, Allah Allah
Allah Allah, Allah Allah

Allah Allah, Allah Allah
Allah Allah, Allah Allah

Ya Rehmatallil A'alameen Anta Shafiul Muznebeen
Akrim Lana Youmal Hazeen Fadlaw Wa Judaw Wal Karam

Ya Rehmatallil A'alameen Adrik Li Zainil A'abeedeen
Mahboosi Aydiz Zalimeen Fil Mawkabee Wal Muzdaham''',
  ),
  // Add more nasheeds here
];

// ── Page ────────────────────────────────────────────────────
class NasheedsPage extends StatelessWidget {
  const NasheedsPage({super.key});

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
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: _nasheeds.length,
                  itemBuilder: (context, index) => _NasheedException(
                    nasheed: _nasheeds[index],
                    number: index + 1,
                    isDark: isDark,
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
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
              'Nasheeds',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}

// ── Accordion item ───────────────────────────────────────────
class _NasheedException extends StatefulWidget {
  final _Nasheed nasheed;
  final int number;
  final bool isDark;

  const _NasheedException({
    required this.nasheed,
    required this.number,
    required this.isDark,
  });

  @override
  State<_NasheedException> createState() => _NasheedExceptionState();
}

class _NasheedExceptionState extends State<_NasheedException>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _iconTurn;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconTurn = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: isDark
            ? AppShadows.cardShadowDark
            : AppShadows.cardShadowLight,
        border: _expanded
            ? Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Column(
          children: [
            // ── Header ──────────────────────────────
            GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Number badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppGradients.goldShimmer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.number}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Text(
                        widget.nasheed.title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkText
                              : AppColors.lightText,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    // Chevron
                    RotationTransition(
                      turns: _iconTurn,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.gold,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Divider (only when expanded) ─────────
            if (_expanded)
              Divider(
                height: 1,
                thickness: 1,
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),

            // ── Lyrics body ──────────────────────────
            SizeTransition(
              sizeFactor: _fadeIn,
              axisAlignment: -1,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Text(
                    widget.nasheed.lyrics,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      height: 2.0,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
