import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../presentation/providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final AnimationController _dotController;
  late final Animation<double> _dotScale;
  late final AnimationController _madeWithController;
  late final Animation<double> _madeWithOpacity;

  String _displayedName = '';
  Timer? _typeTimer;
  int _charIndex = 0;

  static const _appName = AppConstants.appName;

  @override
  void initState() {
    super.initState();

    // Logo animation: fade+scale in (0-600ms)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoScale = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Purple dot pulse
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _dotScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dotController, curve: Curves.elasticOut),
    );

    // "Made with" fade in
    _madeWithController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _madeWithOpacity = Tween(begin: 0.0, end: 0.18).animate(
      CurvedAnimation(parent: _madeWithController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  void _startSequence() {
    // 0ms: Logo fades in
    _logoController.forward();

    // 700ms: Start typing
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _typeTimer = Timer.periodic(AppConstants.typingSpeed, (timer) {
        if (_charIndex < _appName.length) {
          setState(() {
            _charIndex++;
            _displayedName = _appName.substring(0, _charIndex);
          });
        } else {
          timer.cancel();
        }
      });
    });

    // 1200ms: Purple dot
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _dotController.forward();
    });

    // 1600ms: Made with
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      _madeWithController.forward();
    });

    // 2800ms: Navigate
    Future.delayed(AppConstants.splashDuration, () {
      if (!mounted) return;
      final onboardingDone = ref.read(onboardingCompleteProvider);
      if (onboardingDone) {
        context.go('/dashboard');
      } else {
        context.go('/backend-connect');
      }
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _logoController.dispose();
    _dotController.dispose();
    _madeWithController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Logo + name centered
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (_, __) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: SvgPicture.asset(
                        SvgPaths.krivanaLogo,
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Typing name + purple dot
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _displayedName,
                      style: AppTextStyles.splashTitle,
                    ),
                    const SizedBox(width: 4),
                    ScaleTransition(
                      scale: _dotScale,
                      child: const Text(
                        '●',
                        style: TextStyle(
                          fontSize: 20,
                          color: AppColors.accentPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // "Made with ♥ Krivana" at bottom
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.1,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _madeWithOpacity,
              child: const Text(
                'Made with ♥ Krivana',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Brockmann',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
