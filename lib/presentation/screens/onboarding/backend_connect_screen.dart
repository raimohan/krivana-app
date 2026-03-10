import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../presentation/providers/app_providers.dart';
import '../../../presentation/widgets/common/krivana_button.dart';
import '../../../presentation/widgets/common/krivana_text_field.dart';
import '../../../presentation/widgets/glass/glass_container.dart';
import '../../../presentation/widgets/svg/krivana_svg.dart';
import '../../../services/backend/backend_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';

class BackendConnectScreen extends ConsumerStatefulWidget {
  const BackendConnectScreen({super.key});

  @override
  ConsumerState<BackendConnectScreen> createState() =>
      _BackendConnectScreenState();
}

class _BackendConnectScreenState extends ConsumerState<BackendConnectScreen>
    with SingleTickerProviderStateMixin {
  final _urlController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _error;
  bool _showDetails = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    if (!Validators.isValidUrl(url)) {
      setState(() => _error = 'Please enter a valid URL');
      _shakeController.forward().then((_) => _shakeController.reverse());
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = BackendService(baseUrl: url);
      final healthy = await service.healthCheck();

      if (!mounted) return;

      if (healthy) {
        // Save backend URL
        final box = Hive.box(AppConstants.hiveSettingsBox);
        await box.put(AppConstants.settingsBackendUrl, url);
        ref.read(backendUrlProvider.notifier).state = url;
        ref.read(connectionStatusProvider.notifier).state =
            ConnectionStatus.connected;

        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });

        HapticFeedback.heavyImpact();

        // Auto-advance after success animation
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          // Check if already onboarded - if yes, go back to dashboard, else continue to API keys
          final isOnboarded = ref.read(onboardingCompleteProvider);
          if (isOnboarded) {
            context.pop();
          } else {
            context.go('/api-keys');
          }
        }
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Backend returned unhealthy status';
        });
        _shakeController.forward().then((_) => _shakeController.reverse());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Connection failed. Check URL and try again.';
      });
      _shakeController.forward().then((_) => _shakeController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                const KrivanaSvg(
                  SvgPaths.krivanaLogo,
                  width: 48,
                  height: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Connect Backend',
                  style: AppTextStyles.heading1.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your self-hosted backend URL',
                  style: AppTextStyles.body.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // URL Input card
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(_shakeAnimation.value *
                              ((_shakeController.value * 10).toInt().isOdd
                                  ? 1
                                  : -1), 0),
                          child: child,
                        ),
                        child: KrivanaTextField(
                          controller: _urlController,
                          hint: 'https://your-backend.com',
                          keyboardType: TextInputType.url,
                          errorText: _error,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Connect button or success
                      if (_isSuccess)
                        const Icon(Icons.check_circle,
                            color: AppColors.success, size: 48)
                      else
                        KrivanaButton(
                          label: 'Connect',
                          onTap: _isLoading ? null : _connect,
                          isLoading: _isLoading,
                          width: double.infinity,
                        ),

                      const SizedBox(height: 16),

                      // QR option
                      GestureDetector(
                        onTap: () async {
                          final result =
                              await context.push<String>('/qr-scanner');
                          if (result != null && mounted) {
                            _urlController.text = result;
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const KrivanaSvg(
                              SvgPaths.icQrScan,
                              width: 18,
                              height: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'or scan QR code',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.accentPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Collapsible details
                GestureDetector(
                  onTap: () => setState(() => _showDetails = !_showDetails),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showDetails
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Where do I get a backend URL?',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showDetails) ...[
                  const SizedBox(height: 12),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    tintOpacity: 0.04,
                    child: Text(
                      'Krivana requires a self-hosted backend to store your '
                      'projects and handle AI interactions. Visit the Krivana '
                      'documentation for setup instructions.',
                      style: AppTextStyles.caption.copyWith(
                        height: 1.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
