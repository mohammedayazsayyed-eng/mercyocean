import 'package:flutter/material.dart';
// Splash-only UI; font initialization happens in MyApp

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/icons/SplashScreen.jpeg',
            fit: BoxFit.cover,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    value: null,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Loading…',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
