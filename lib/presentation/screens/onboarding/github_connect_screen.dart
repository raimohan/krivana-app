import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../presentation/providers/app_providers.dart';
import '../../../presentation/widgets/common/krivana_button.dart';
import '../../../presentation/widgets/glass/glass_container.dart';
import '../../../services/github/github_service.dart';

class GitHubConnectScreen extends ConsumerStatefulWidget {
  const GitHubConnectScreen({super.key});

  @override
  ConsumerState<GitHubConnectScreen> createState() =>
      _GitHubConnectScreenState();
}

class _GitHubConnectScreenState extends ConsumerState<GitHubConnectScreen> {
  bool _isLoading = false;
  bool _isConnected = false;
  String? _username;
  bool _showInfo = false;

  Future<void> _connectGitHub() async {
    setState(() => _isLoading = true);

    try {
      final github = GitHubService();
      final result = await github.startOAuth();

      if (!mounted) return;

      if (result != null) {
        ref.read(gitHubConnectedProvider.notifier).state = true;
        final box = Hive.box(AppConstants.hiveSettingsBox);
        await box.put(AppConstants.settingsGitHubConnected, true);

        setState(() {
          _isLoading = false;
          _isConnected = true;
          _username = result;
        });

        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 800));
        _finishOnboarding();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _finishOnboarding() {
    final box = Hive.box(AppConstants.hiveSettingsBox);
    box.put(AppConstants.settingsOnboardingComplete, true);
    ref.read(onboardingCompleteProvider.notifier).state = true;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: _finishOnboarding,
                    child: Text(
                      'Skip',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.accentPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Connect GitHub',
                        style: AppTextStyles.heading1.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (_isConnected) ...[
                        // Connected state
                        const Icon(Icons.check_circle,
                            color: AppColors.success, size: 56),
                        const SizedBox(height: 16),
                        Text(
                          'Connected as $_username',
                          style: AppTextStyles.body.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ] else ...[
                        // GitHub OAuth button
                        KrivanaButton(
                          label: 'Sign in with GitHub',
                          svgIconPath: SvgPaths.logoGitHub,
                          onTap: _isLoading ? null : _connectGitHub,
                          isLoading: _isLoading,
                          backgroundColor: const Color(0xFF24292F),
                          foregroundColor: Colors.white,
                          width: double.infinity,
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Info section
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showInfo = !_showInfo),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showInfo
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Why connect GitHub?',
                              style: AppTextStyles.caption.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_showInfo) ...[
                        const SizedBox(height: 16),
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          tintOpacity: 0.04,
                          child: Column(
                            children: [
                              _featureRow(Icons.download_rounded,
                                  'Import repos directly'),
                              const SizedBox(height: 10),
                              _featureRow(Icons.cloud_upload_rounded,
                                  'Push changes to GitHub'),
                              const SizedBox(height: 10),
                              _featureRow(Icons.rocket_launch_rounded,
                                  'Auto-deploy via GitHub Pages'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: AppColors.accentPurple, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTextStyles.body.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
