import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/glass/glass_container.dart';

enum _DeployTarget { vercel, netlify, githubPages, custom }

class DeployScreen extends ConsumerStatefulWidget {
  const DeployScreen({super.key});

  @override
  ConsumerState<DeployScreen> createState() => _DeployScreenState();
}

class _DeployScreenState extends ConsumerState<DeployScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: SvgPicture.asset(SvgPaths.icBack,
                        width: 24, height: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Deploy',
                    style: AppTextStyles.heading2.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Choose a platform',
                    style: AppTextStyles.body.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _DeployCard(
                    title: 'Vercel',
                    description: 'Deploy to Vercel with API key',
                    svgPath: SvgPaths.logoVercel,
                    onTap: () => _deploy(_DeployTarget.vercel),
                  ),
                  const SizedBox(height: 12),
                  _DeployCard(
                    title: 'Netlify',
                    description: 'Deploy to Netlify',
                    svgPath: SvgPaths.icDeploy,
                    onTap: () => _deploy(_DeployTarget.netlify),
                  ),
                  const SizedBox(height: 12),
                  _DeployCard(
                    title: 'GitHub Pages',
                    description: 'One-click deploy if GitHub is connected',
                    svgPath: SvgPaths.logoGitHub,
                    onTap: () => _deploy(_DeployTarget.githubPages),
                  ),
                  const SizedBox(height: 12),
                  _DeployCard(
                    title: 'Custom Server',
                    description: 'SSH credentials or webhook URL',
                    svgPath: SvgPaths.icDeploy,
                    onTap: () => _deploy(_DeployTarget.custom),
                  ),

                  const SizedBox(height: 32),

                  // Deploy history
                  Text(
                    'Deploy History',
                    style: AppTextStyles.heading2.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No deployments yet',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _deploy(_DeployTarget target) {
    HapticFeedback.mediumImpact();
    // TODO: implement deploy flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deploy to ${target.name} — coming soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _DeployCard extends StatelessWidget {
  final String title;
  final String description;
  final String svgPath;
  final VoidCallback onTap;

  const _DeployCard({
    required this.title,
    required this.description,
    required this.svgPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SvgPicture.asset(svgPath, width: 32, height: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SvgPicture.asset(SvgPaths.icChevronRight,
                width: 16, height: 16),
          ],
        ),
      ),
    );
  }
}
