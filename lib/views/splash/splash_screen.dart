import 'package:flutter/material.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _ctrl,
    curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColor.kPrimary, AppColor.kDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 5),
              ScaleTransition(
                scale: _scale,
                child: Image.asset(
                  'assets/splash/splash_icon.png',
                  width: 150,
                  height: 150,
                  // keeps working even if the asset is not added yet
                  errorBuilder: (context, error, stack) => const Icon(
                    Icons.explore_rounded,
                    size: 110,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FadeTransition(
                opacity: _fade,
                child: const Column(
                  children: [
                    Text(
                      'Wanderly',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Explore. Connect. Share.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 4),
              FadeTransition(
                opacity: _fade,
                child: const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
