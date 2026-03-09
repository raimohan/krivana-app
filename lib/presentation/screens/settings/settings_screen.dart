import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../presentation/providers/app_providers.dart';
import '../../widgets/glass/glass_container.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = 'v${info.version}');
    } catch (_) {
      if (mounted) setState(() => _appVersion = 'v${AppConstants.appVersion}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);
    final backendUrl = ref.watch(backendUrlProvider);
    final gitHubConnected = ref.watch(gitHubConnectedProvider);

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
                    'Settings',
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
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 8),

                  // ── Appearance ──
                  const _SectionTitle('Appearance'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SettingRow(
                          title: 'Theme',
                          trailing: DropdownButton<ThemeMode>(
                            value: themeMode,
                            underline: const SizedBox(),
                            dropdownColor:
                                isDark ? AppColors.darkCard : AppColors.lightCard,
                            items: const [
                              DropdownMenuItem(
                                  value: ThemeMode.dark, child: Text('Dark')),
                              DropdownMenuItem(
                                  value: ThemeMode.light, child: Text('Light')),
                              DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Text('System')),
                            ],
                            onChanged: (mode) {
                              if (mode == null) return;
                              ref.read(themeModeProvider.notifier).state = mode;
                              final box = Hive.box(AppConstants.hiveSettingsBox);
                              box.put(
                                  AppConstants.settingsThemeMode, mode.name);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Backend ──
                  const _SectionTitle('Backend'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SettingRow(
                          title: 'Backend URL',
                          subtitle: backendUrl ?? 'Not configured',
                        ),
                        const Divider(height: 24),
                        _SettingRow(
                          title: 'Connection Status',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: backendUrl != null
                                      ? AppColors.success
                                      : AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                backendUrl != null
                                    ? 'Connected'
                                    : 'Disconnected',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── AI Configuration ──
                  const _SectionTitle('AI Configuration'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () => context.push('/api-keys'),
                      child: _SettingRow(
                        title: 'Manage API Keys',
                        trailing: SvgPicture.asset(SvgPaths.icChevronRight,
                            width: 16, height: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── GitHub ──
                  const _SectionTitle('GitHub'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SettingRow(
                          title: 'GitHub Account',
                          subtitle: gitHubConnected
                              ? 'Connected'
                              : 'Not connected',
                          trailing: gitHubConnected
                              ? GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(gitHubConnectedProvider.notifier)
                                        .state = false;
                                    final box =
                                        Hive.box(AppConstants.hiveSettingsBox);
                                    box.put(
                                        AppConstants.settingsGitHubConnected,
                                        false);
                                  },
                                  child: Text(
                                    'Disconnect',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () =>
                                      context.push('/github-connect'),
                                  child: Text(
                                    'Connect',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.accentPurple,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Account & Memory ──
                  const _SectionTitle('Account & Memory'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SettingRow(
                          title: 'User Profile SVG',
                          subtitle: 'Upload your avatar',
                          trailing: SvgPicture.asset(SvgPaths.icChevronRight,
                              width: 16, height: 16),
                        ),
                        const Divider(height: 24),
                        GestureDetector(
                          onTap: () {
                            // TODO: clear all memory
                            HapticFeedback.mediumImpact();
                          },
                          child: _SettingRow(
                            title: 'Clear All Memory',
                            trailing: Text(
                              'Clear',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── App ──
                  const _SectionTitle('App'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SettingRow(
                          title: 'Version',
                          trailing: Text(
                            _appVersion,
                            style: AppTextStyles.caption,
                          ),
                        ),
                        const Divider(height: 24),
                        GestureDetector(
                          onTap: () {
                            // TODO: check for updates
                          },
                          child: _SettingRow(
                            title: 'Check for Updates',
                            trailing: SvgPicture.asset(
                                SvgPaths.icChevronRight,
                                width: 16,
                                height: 16),
                          ),
                        ),
                        const Divider(height: 24),
                        _SettingRow(
                          title: 'Privacy Policy',
                          trailing: SvgPicture.asset(
                              SvgPaths.icExternalLink,
                              width: 16,
                              height: 16),
                        ),
                        const Divider(height: 24),
                        _SettingRow(
                          title: 'Terms of Service',
                          trailing: SvgPicture.asset(
                              SvgPaths.icExternalLink,
                              width: 16,
                              height: 16),
                        ),
                        const Divider(height: 24),
                        _SettingRow(
                          title: 'Open Source Licenses',
                          trailing: SvgPicture.asset(
                              SvgPaths.icChevronRight,
                              width: 16,
                              height: 16),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SettingRow({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
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
        if (trailing != null) trailing!,
      ],
    );
  }
}
