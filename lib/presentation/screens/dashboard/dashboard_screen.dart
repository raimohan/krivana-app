import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod/legacy.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_repository.dart';
import '../../../presentation/widgets/glass/glass_container.dart';
import '../../../presentation/widgets/common/krivana_button.dart';
import '../../../presentation/widgets/common/krivana_text_field.dart';
import '../../../presentation/widgets/svg/krivana_svg.dart';
import '../../../services/notifications/local_notification_service.dart';

final _projectsProvider = StateProvider<List<ProjectModel>>((ref) {
  final box = Hive.box(AppConstants.hiveProjectsBox);
  final raw = box.values.toList();
  return raw
      .whereType<Map>()
      .map((e) => ProjectModel.fromJson(Map<String, dynamic>.from(e)))
      .toList()
    ..sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return (b.updatedAt ?? DateTime(2000))
          .compareTo(a.updatedAt ?? DateTime(2000));
    });
});

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning';
  if (hour < 17) return 'Good Afternoon';
  return 'Good Evening';
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _autoNotificationTimer;

  static const _notificationTemplates = [
    (
      'Star our GitHub repo',
      'Enjoying Krivana? Star the repository to support the project.',
      NotificationType.github,
    ),
    (
      'AI workflows are ready',
      'Try Planning Chat to generate your next feature faster.',
      NotificationType.ai,
    ),
    (
      'Deploy in one tap',
      'Use the Deploy tab to ship your app with your preferred platform.',
      NotificationType.deploy,
    ),
    (
      'Keep your backend healthy',
      'Quickly check backend status from Settings > Backend.',
      NotificationType.system,
    ),
    (
      'Import your GitHub repo',
      'Connect GitHub and pull your repositories directly into Krivana.',
      NotificationType.github,
    ),
    (
      'Tip: keep building daily',
      'Small daily commits compound into big progress.',
      NotificationType.update,
    ),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pushHourlyNotificationIfDue();
      _autoNotificationTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _pushHourlyNotificationIfDue(),
      );
    });
  }

  @override
  void dispose() {
    _autoNotificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _pushHourlyNotificationIfDue() async {
    final settings = Hive.box(AppConstants.hiveSettingsBox);
    final now = DateTime.now();
    final lastAtMs =
        settings.get(AppConstants.settingsLastAutoNotificationAt) as int?;
    if (lastAtMs != null) {
      final lastAt = DateTime.fromMillisecondsSinceEpoch(lastAtMs);
      if (now.difference(lastAt) < const Duration(hours: 1)) return;
    }

    final idx = (settings.get(AppConstants.settingsAutoNotificationIndex,
            defaultValue: 0) as int?) ??
        0;
    final template =
        _notificationTemplates[idx % _notificationTemplates.length];
    final notification = AppNotification(
      id: 'auto_${now.millisecondsSinceEpoch}',
      title: template.$1,
      body: template.$2,
      type: template.$3,
      createdAt: now,
    );

    final notificationBox = Hive.box(AppConstants.hiveNotificationsBox);
    await notificationBox.put(notification.id, notification.toJson());
    await settings.put(
      AppConstants.settingsLastAutoNotificationAt,
      now.millisecondsSinceEpoch,
    );
    await settings.put(
      AppConstants.settingsAutoNotificationIndex,
      (idx + 1) % _notificationTemplates.length,
    );
    await LocalNotificationService.instance.showNotification(notification);

    if (!mounted) return;
    setState(() {});
  }

  int _unreadCount() {
    final box = Hive.box(AppConstants.hiveNotificationsBox);
    return box.values
        .whereType<Map>()
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
        .where((n) => !n.isRead)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = ref.watch(_projectsProvider);
    final unreadCount = _unreadCount();
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subtextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (isDark) ...[
              const Positioned(
                left: -90,
                top: 72,
                child: _AmbientGlow(
                  size: 220,
                  colors: [
                    Color(0x337C3AED),
                    Color(0x00EC4899),
                  ],
                ),
              ),
              const Positioned(
                right: -120,
                top: 220,
                child: _AmbientGlow(
                  size: 260,
                  colors: [
                    Color(0x1F22D3EE),
                    Color(0x00EC4899),
                  ],
                ),
              ),
            ],
            Column(
              children: [
                // ── Top bar ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Bell
                      SizedBox(
                        width: 36,
                        child: GestureDetector(
                          onTap: () => context.push('/notifications'),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(Icons.notifications_none_rounded,
                                  size: 24, color: textColor),
                              if (unreadCount > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: AppColors.accentPurple,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      unreadCount > 9 ? '9+' : '$unreadCount',
                                      style: AppTextStyles.caption.copyWith(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Brand center
                      Expanded(
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const KrivanaSvg(
                                SvgPaths.krivanaIcon,
                                size: 30,
                                autoTheme: false,
                                animate: false,
                              ),
                              const SizedBox(width: 8),
                              RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                      text: 'Krivana',
                                      style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: textColor)),
                                  TextSpan(
                                      text: '.',
                                      style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.accentPurple)),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Settings
                      SizedBox(
                        width: 36,
                        child: GestureDetector(
                          onTap: () => context.push('/settings'),
                          child: KrivanaSvg(SvgPaths.icSettings, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable content ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // ── Greeting section ──
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const _SparkleBadge(),
                                const SizedBox(width: 8),
                                Text(
                                  _greeting(),
                                  style: AppTextStyles.heading1.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Ready to build something ',
                                  style: AppTextStyles.body.copyWith(
                                      color: subtextColor, height: 1.4),
                                ),
                                const _AnimatedGradientWord(text: 'amazing?'),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Feature cards row 1 ──
                        Row(
                          children: [
                            Expanded(
                              child: _FeatureCard(
                                title: 'Scan QR',
                                svgPath: SvgPaths.icQrScan,
                                accentColors: const [
                                  AppColors.accentPurple,
                                  AppColors.accentPink,
                                ],
                                iconColor: const Color(0xFFD38BFF),
                                onTap: () => context.push('/qr-scanner'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _FeatureCard(
                                title: 'Import Repo',
                                svgPath: SvgPaths.logoGitHub,
                                autoThemeSvg: false,
                                accentColors: const [
                                  Color(0xFF246BFD),
                                  AppColors.accentPurple,
                                ],
                                iconColor: const Color(0xFF7FB4FF),
                                onTap: () => context.push('/import-repo'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ── Feature cards row 2 ──
                        Row(
                          children: [
                            Expanded(
                              child: _FeatureCard(
                                title: 'AI Chat',
                                svgPath: SvgPaths.icAiChat,
                                accentColors: const [
                                  Color(0xFF06B6D4),
                                  Color(0xFF3B82F6),
                                ],
                                iconColor: const Color(0xFF38DDF8),
                                onTap: () => context.push('/planning-chat'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _FeatureCard(
                                title: 'Deploy',
                                svgPath: SvgPaths.icDeploy,
                                accentColors: const [
                                  Color(0xFF10B981),
                                  Color(0xFF34D399),
                                ],
                                iconColor: const Color(0xFF52F1B3),
                                onTap: () => context.push('/deploy'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ── Projects header ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RECENT PROJECTS',
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: subtextColor,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/projects'),
                              child: Text(
                                'View All',
                                style: AppTextStyles.caption.copyWith(
                                    color: AppColors.accentPurple,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Projects stack ──
                        projects.isEmpty
                            ? _buildEmptyProjects(isDark, subtextColor)
                            : _SwipeableProjectStack(projects: projects),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActionBar(),
    );
  }

  Widget _buildEmptyProjects(bool isDark, Color subtextColor) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          KrivanaSvg(SvgPaths.illustEmptyProjects, size: 120),
          const SizedBox(height: 16),
          Text('No projects yet',
              style: AppTextStyles.body.copyWith(color: subtextColor)),
          const SizedBox(height: 8),
          Text('Tap + to create your first project',
              style: AppTextStyles.caption.copyWith(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextSecondary)),
        ],
      ),
    );
  }
}

// ── Feature card ──────────────────────────────────────────────────────────────

class _FeatureCard extends StatefulWidget {
  final String title;
  final String svgPath;
  final VoidCallback onTap;
  final bool autoThemeSvg;
  final List<Color> accentColors;
  final Color iconColor;

  const _FeatureCard({
    required this.title,
    required this.svgPath,
    required this.onTap,
    this.autoThemeSvg = true,
    required this.accentColors,
    required this.iconColor,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) {
        _press.forward();
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _press.reverse();
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        _press.reverse();
        setState(() => _isPressed = false);
      },
      child: ScaleTransition(
        scale: _scale,
        child: GlassContainer(
          padding: const EdgeInsets.all(18),
          tintOpacity: 0.08,
          borderOpacity: 0.14,
          child: AspectRatio(
            aspectRatio: 1.28,
            child: Stack(
              children: [
                Positioned(
                  left: -18,
                  top: -14,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    width: _isPressed ? 132 : 114,
                    height: _isPressed ? 132 : 114,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.accentColors.first.withValues(
                            alpha: isDark
                                ? (_isPressed ? 0.22 : 0.16)
                                : (_isPressed ? 0.08 : 0.04),
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -26,
                  bottom: -32,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    width: _isPressed ? 140 : 120,
                    height: _isPressed ? 140 : 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.accentColors.last.withValues(
                            alpha: isDark
                                ? (_isPressed ? 0.18 : 0.12)
                                : (_isPressed ? 0.06 : 0.03),
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.accentColors.first.withValues(
                              alpha: isDark
                                  ? (_isPressed ? 0.34 : 0.22)
                                  : (_isPressed ? 0.16 : 0.10),
                            ),
                            widget.accentColors.last.withValues(
                              alpha: isDark
                                  ? (_isPressed ? 0.22 : 0.12)
                                  : (_isPressed ? 0.10 : 0.06),
                            ),
                          ],
                        ),
                        border: Border.all(
                          color:
                              (isDark ? Colors.white : Colors.black).withValues(
                            alpha: _isPressed ? 0.14 : 0.08,
                          ),
                        ),
                        boxShadow: isDark
                            ? [
                                BoxShadow(
                                  color: widget.accentColors.first.withValues(
                                    alpha: _isPressed ? 0.18 : 0.08,
                                  ),
                                  blurRadius: _isPressed ? 26 : 18,
                                ),
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 220),
                        scale: _isPressed ? 1.08 : 1,
                        child: KrivanaSvg(
                          widget.svgPath,
                          size: 24,
                          autoTheme: widget.autoThemeSvg,
                          color: widget.autoThemeSvg ? widget.iconColor : null,
                        ),
                      ),
                    ),
                    Text(
                      widget.title,
                      style: AppTextStyles.heading2.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Swipeable project stack ──────────────────────────────────────────────────

class _SwipeableProjectStack extends ConsumerStatefulWidget {
  final List<ProjectModel> projects;
  const _SwipeableProjectStack({required this.projects});

  @override
  ConsumerState<_SwipeableProjectStack> createState() =>
      _SwipeableProjectStackState();
}

class _SwipeableProjectStackState extends ConsumerState<_SwipeableProjectStack>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  double _dragOffset = 0;
  late AnimationController _animController;
  late Animation<double> _dragAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateBack() {
    _dragAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward(from: 0).then((_) {
      if (mounted) setState(() => _dragOffset = 0);
    });
    _dragAnimation.addListener(() {
      if (mounted) setState(() => _dragOffset = _dragAnimation.value);
    });
  }

  @override
  void didUpdateWidget(covariant _SwipeableProjectStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projects.isEmpty) {
      _currentIndex = 0;
      _dragOffset = 0;
      return;
    }

    final maxIndex = widget.projects.length - 1;
    if (_currentIndex > maxIndex) {
      _currentIndex = maxIndex;
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onHorizontalDragUpdate: (d) => setState(() => _dragOffset += d.delta.dx),
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (_dragOffset.abs() > 80 || v.abs() > 500) {
          if ((_dragOffset < 0 || v < -500) &&
              _currentIndex < widget.projects.length - 1) {
            setState(() {
              _currentIndex++;
              _dragOffset = 0;
            });
          } else if ((_dragOffset > 0 || v > 500) && _currentIndex > 0) {
            setState(() {
              _currentIndex--;
              _dragOffset = 0;
            });
          } else {
            _animateBack();
          }
        } else {
          _animateBack();
        }
      },
      child: SizedBox(
        height: 214,
        child: Stack(
          clipBehavior: Clip.none,
          children: _buildCards(isDark),
        ),
      ),
    );
  }

  List<Widget> _buildCards(bool isDark) {
    final cards = <Widget>[];
    const maxVisible = 3;
    for (int i = (maxVisible - 1).clamp(0, widget.projects.length - 1);
        i >= 0;
        i--) {
      final projIdx = _currentIndex + i;
      if (projIdx >= widget.projects.length) continue;

      final project = widget.projects[projIdx];
      final offset = i * 14.0;
      final scale = 1.0 - (i * 0.04);
      final opacity = 1.0 - (i * 0.18);

      cards.add(
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          top: offset,
          left: i == 0 ? _dragOffset * 0.4 : (i * 6.0),
          right: i == 0 ? -_dragOffset * 0.4 : (i * 6.0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/projects/${project.id}/files');
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  _showProjectMenu(context, project);
                },
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Stack(
                    children: [
                      Positioned(
                        left: -18,
                        top: -24,
                        child: IgnorePointer(
                          child: Container(
                            width: 136,
                            height: 136,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.accentPurple
                                      .withValues(alpha: isDark ? 0.22 : 0.07),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -20,
                        bottom: -36,
                        child: IgnorePointer(
                          child: Container(
                            width: 156,
                            height: 156,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.accentPink
                                      .withValues(alpha: isDark ? 0.16 : 0.05),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.accentPurple.withValues(
                                          alpha: isDark ? 0.26 : 0.12),
                                      AppColors.accentPink.withValues(
                                          alpha: isDark ? 0.16 : 0.08),
                                    ],
                                  ),
                                  border: Border.all(
                                    color:
                                        (isDark ? Colors.white : Colors.black)
                                            .withValues(alpha: 0.10),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: KrivanaSvg(
                                  SvgPaths.icCodeEditor,
                                  size: 22,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.accentPurple,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.07)
                                      : Colors.black.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _timeAgo(project.updatedAt),
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              if (project.isPinned) ...[
                                KrivanaSvg(
                                  SvgPaths.icPin,
                                  size: 13,
                                  color: AppColors.accentPurple,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Expanded(
                                child: Text(
                                  project.name,
                                  style: AppTextStyles.heading2.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.account_tree_outlined,
                                size: 16,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'main • ${project.techStack ?? 'Workspace'}',
                                  style: AppTextStyles.body.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Page dots
    if (widget.projects.length > 1) {
      cards.add(
        Positioned(
          bottom: -34,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.projects.length.clamp(0, 10),
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentIndex ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: i == _currentIndex
                      ? AppColors.accentPurple
                      : AppColors.accentPurple.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return cards;
  }

  void _showProjectMenu(BuildContext context, ProjectModel project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => SafeArea(
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: KrivanaSvg(SvgPaths.icAiChat, size: 20),
                title: Text('Open in Chat',
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/project-chat/${project.id}');
                },
              ),
              ListTile(
                leading: KrivanaSvg(SvgPaths.icPin, size: 20),
                title: Text(project.isPinned ? 'Unpin' : 'Pin',
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black)),
                onTap: () async {
                  Navigator.pop(context);
                  await ProjectRepository.togglePin(project.id);
                  ref.invalidate(_projectsProvider);
                },
              ),
              ListTile(
                leading: KrivanaSvg(SvgPaths.icTrash,
                    size: 20, color: AppColors.error),
                title: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(context);
                  await ProjectRepository.deleteProject(project.id);
                  ref.invalidate(_projectsProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bottom action bar ────────────────────────────────────────────────────────

class _BottomActionBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BottomActionBar> createState() => _BottomActionBarState();
}

class _BottomActionBarState extends ConsumerState<_BottomActionBar> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassContainer(
              borderRadius: 999,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: SizedBox(
                width: 176,
                height: 52,
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeOutCubic,
                      alignment: _activeIndex == 0
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.accentPurple,
                              AppColors.accentPink,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentPurple
                                  .withValues(alpha: isDark ? 0.24 : 0.14),
                              blurRadius: isDark ? 24 : 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _BottomActionButton(
                            svgPath: SvgPaths.icPlus,
                            isActive: _activeIndex == 0,
                            onTap: () {
                              setState(() => _activeIndex = 0);
                              HapticFeedback.mediumImpact();
                              _showCreateSheet(context, ref);
                            },
                          ),
                        ),
                        Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                        Expanded(
                          child: _BottomActionButton(
                            svgPath: SvgPaths.icSearch,
                            isActive: _activeIndex == 1,
                            onTap: () {
                              setState(() => _activeIndex = 1);
                              HapticFeedback.lightImpact();
                              context.push('/planning-chat');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Project',
                  style: AppTextStyles.heading2.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                KrivanaTextField(
                  controller: controller,
                  hint: 'Project name',
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                KrivanaButton(
                  label: 'Create',
                  width: double.infinity,
                  onTap: () {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;

                    final project = ProjectModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      techStack: 'Not set',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );

                    final box = Hive.box(AppConstants.hiveProjectsBox);
                    box.put(project.id, project.toJson());
                    ref.invalidate(_projectsProvider);

                    Navigator.pop(ctx);
                    context.push('/project-chat/${project.id}');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.svgPath,
    required this.isActive,
    required this.onTap,
  });

  final String svgPath;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isActive
        ? Colors.white
        : (isDark
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.black.withValues(alpha: 0.65));
    final dotColor = isActive
        ? Colors.white
        : (isDark
            ? Colors.white.withValues(alpha: 0.42)
            : Colors.black.withValues(alpha: 0.28));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            scale: isActive ? 1.04 : 1,
            child: KrivanaSvg(
              svgPath,
              size: 25,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            width: isActive ? 7 : 4,
            height: isActive ? 7 : 4,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _SparkleBadge extends StatefulWidget {
  const _SparkleBadge();

  @override
  State<_SparkleBadge> createState() => _SparkleBadgeState();
}

class _SparkleBadgeState extends State<_SparkleBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: (-0.12 + (_controller.value * 0.24)),
          child: Transform.scale(
            scale: 0.95 + (_controller.value * 0.12),
            child: child,
          ),
        );
      },
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Color(0xFFFFE082),
        size: 28,
      ),
    );
  }
}

class _AnimatedGradientWord extends StatefulWidget {
  const _AnimatedGradientWord({required this.text});

  final String text;

  @override
  State<_AnimatedGradientWord> createState() => _AnimatedGradientWordState();
}

class _AnimatedGradientWordState extends State<_AnimatedGradientWord>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shift = _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + shift, 0),
              end: Alignment(1 - shift, 0),
              colors: const [
                AppColors.accentPurple,
                AppColors.accentPink,
                Color(0xFFFF7AC6),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Text(
        widget.text,
        style: AppTextStyles.body.copyWith(
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
