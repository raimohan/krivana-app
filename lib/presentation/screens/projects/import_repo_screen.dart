import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../presentation/providers/app_providers.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/common/krivana_button.dart';

class ImportRepoScreen extends ConsumerStatefulWidget {
  const ImportRepoScreen({super.key});

  @override
  ConsumerState<ImportRepoScreen> createState() => _ImportRepoScreenState();
}

class _ImportRepoScreenState extends ConsumerState<ImportRepoScreen> {
  bool _isLoading = false;

  // TODO: Load from GitHub API
  final List<Map<String, dynamic>> _repos = [];

  @override
  void initState() {
    super.initState();
    _loadRepos();
  }

  Future<void> _loadRepos() async {
    final isConnected = ref.read(gitHubConnectedProvider);
    if (!isConnected) return;

    setState(() => _isLoading = true);
    // TODO: Fetch repos from GitHub
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = ref.watch(gitHubConnectedProvider);

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
                    'Import Repository',
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
              child: !isConnected
                  ? _buildConnectPrompt(isDark)
                  : _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _repos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(SvgPaths.logoGitHub,
                                      width: 56, height: 56),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No repositories found',
                                    style: AppTextStyles.body.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _repos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, index) =>
                                  _RepoCard(repo: _repos[index]),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectPrompt(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(SvgPaths.logoGitHub, width: 56, height: 56),
            const SizedBox(height: 20),
            Text(
              'Connect GitHub to import repos',
              style: AppTextStyles.body.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            KrivanaButton(
              label: 'Connect GitHub',
              svgIconPath: SvgPaths.logoGitHub,
              onTap: () => context.push('/github-connect'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepoCard extends StatelessWidget {
  final Map<String, dynamic> repo;

  const _RepoCard({required this.repo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  repo['name'] as String? ?? '',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                if (repo['description'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    repo['description'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (repo['language'] != null) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accentPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        repo['language'] as String,
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(width: 12),
                    ],
                    const Icon(Icons.star_border, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '${repo['stars'] ?? 0}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          KrivanaButton(
            label: 'Import',
            isPrimary: false,
            onTap: () {
              HapticFeedback.mediumImpact();
              // TODO: Import repo
            },
          ),
        ],
      ),
    );
  }
}
