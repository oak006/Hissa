import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/hissa_mark.dart';
import '../../app/constants.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';

/// Navy title screen. The only place the brand runs full-bleed.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: K.navy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E44A0), K.navy, Color(0xFF0E2258)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: K.pagePad,
            child: Column(
              children: [
                const Spacer(flex: 3),
                FadeTransition(
                  opacity: _c,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(
                      CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
                    ),
                    child: Column(
                      children: [
                        // The real lockup, not a type approximation of it —
                        // the same image the loading screen just showed.
                        const HissaWordmark(height: 68),
                        const SizedBox(height: 14),
                        Text(
                          s.t('tagline'),
                          style: context.tt.titleMedium?.copyWith(
                            color: K.amber,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _c,
                    curve: const Interval(0.45, 1, curve: Curves.easeOut),
                  ),
                  child: Column(
                    children: [
                      Text(
                        s.t('splash_sub'),
                        textAlign: TextAlign.center,
                        style: context.tt.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: () => context.go('/onboarding/phone'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: K.navy,
                        ),
                        child: Text(s.t('get_started')),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        // Straight to the app — the pitch does not always
                        // start from onboarding.
                        onPressed: () => context.go('/home'),
                        child: Text(
                          s.t('skip'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
