import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mercyocean/pages/Contact.dart';
import 'package:mercyocean/pages/ShaykhMehmat.dart';
import 'package:mercyocean/pages/intro_page.dart';
import 'package:mercyocean/pages/Shaykhnazim.dart';
import 'package:mercyocean/widgets/bottom_nav_bar.dart';
import 'package:mercyocean/widgets/tasbih_floating_button.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'config/app_theme.dart';
import 'config/app_state.dart';
import 'config/home_screen.dart';
import 'splash_screen.dart';
import 'package:mercyocean/service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global notifier for the font script (false = Uthmani, true = IndoPak)
final ValueNotifier<bool> isIndoPakNotifier = ValueNotifier(false);

// Function to toggle and save the font preference
Future<void> toggleFontScript(bool isIndoPak) async {
  isIndoPakNotifier.value = isIndoPak;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isIndoPakScript', isIndoPak);
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  // Load saved font script preference
  final isIndoPak = prefs.getBool('isIndoPakScript') ?? false;
  isIndoPakNotifier.value = isIndoPak;
  
  runApp(const MyApp());
}

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<ThemeMode>(
//       valueListenable: themeNotifier,
//       builder: (context, currentMode, _) {
//         return MaterialApp(
//           title: 'MercyOcean',
//           theme: AppTheme.light,
//           darkTheme: AppTheme.dark,
//           themeMode: currentMode,
//           debugShowCheckedModeBanner: false,
//           home: const SplashScreen(),
//         );
//       },
//     );
//   }
// }

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _fontsLoaded = false;
  @override
  void initState() {
    super.initState();
    _initAppData();
    _initializeFonts();
  }

  Future<void> _initAppData() async {
    try {
      await ApiService().getAllDuas();
    } catch (_) {}
  }

  void _initializeFonts() async {
    try {
      // Skip font loading on web (path_provider not available)
      if (kIsWeb) {
        if (mounted) setState(() => _fontsLoaded = true);
        return;
      }
      await QcfFontLoader.setupFontsAtStartup(
        onProgress: (double progress) {
          debugPrint(
            'Font Loading Progress: ${(progress * 100).toStringAsFixed(1)}%',
          );
        },
      );
      if (mounted) setState(() => _fontsLoaded = true);
    } catch (e) {
      debugPrint('Font loading failed: $e');
      if (mounted) setState(() => _fontsLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'MercyOcean',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: currentMode,
          debugShowCheckedModeBanner: false,
          home: _fontsLoaded ? const RootScreen() : const SplashScreen(),
        );
      },
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  static const List<Widget> _pages = [
    IntroPage(),
    Shaykhmehmat("shaykh-muhammad-aadil-ar-rabbani"),
    HomeScreen(),
    Shaykhnazim(),
    ContactUs(),
  ];

  // Index of the Home tab within _pages — the only tab where the
  // floating Tasbih badge is shown.
  static const int _homeIndex = 2;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (navIndexNotifier.value != _homeIndex) {
          navIndexNotifier.value = _homeIndex;
        }
      },
      child: ValueListenableBuilder<int>(
        valueListenable: navIndexNotifier,
        builder: (context, index, _) {
          final isHome = index == _homeIndex;
          final bottomInset = MediaQuery.of(context).padding.bottom;

          return Stack(
            children: [
              Scaffold(
                body: IndexedStack(index: index, children: _pages),
                bottomNavigationBar: const BottomNavBar(),
              ),
              // Sits in this screen-sized Stack (not inside BottomNavBar's
              // own compact bounds) so it stays hit-testable, and toggles
              // with the active tab. Parked clear of the bar's top edge so
              // it never covers a nav icon.
              Positioned(
                right: 18,
                bottom: BottomNavBar.barHeight + bottomInset + 14,
                child: IgnorePointer(
                  ignoring: !isHome,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    scale: isHome ? 1.0 : 0.6,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: isHome ? 1.0 : 0.0,
                      child: const TasbihFloatingButton(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
