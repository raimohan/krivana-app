import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../presentation/providers/app_providers.dart';
import '../../../services/backend/backend_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {

  String _displayedName = '';
  Timer? _typeTimer;
  int _charIndex = 0;

  static const _appName = AppConstants.appName;

  @override
  void initState() {
    super.initState();

    _startSequence();
  }

  void _startSequence() {
    // Start typing animation
    Future.delayed(const Duration(milliseconds: 300), () {
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

    // 2800ms: Navigate
    Future.delayed(AppConstants.splashDuration, () async {
      if (!mounted) return;
      final onboardingDone = ref.read(onboardingCompleteProvider);
      if (!onboardingDone) {
        context.go('/backend-connect');
        return;
      }
      // Onboarding complete - check backend health but don't force reconfig
      final backendUrl = ref.read(backendUrlProvider);
      if (backendUrl != null && backendUrl.isNotEmpty) {
        final isHealthy = await BackendService.instance.healthCheck();
        if (!mounted) return;
        if (isHealthy) {
          ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.connected;
        } else {
          // Backend offline but onboarding done - mark as disconnected, still go to dashboard
          ref.read(connectionStatusProvider.notifier).state = ConnectionStatus.disconnected;
        }
      }
      // After onboarding is complete, always go to dashboard (will show offline indicator if needed)
      context.go('/dashboard');
    });
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          _displayedName,
          style: AppTextStyles.splashTitle,
        ),
      ),
    );
  }
}
