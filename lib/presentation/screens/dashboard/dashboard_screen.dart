import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/models/project_model.dart';
import '../../../presentation/widgets/glass/glass_container.dart';
import '../../../presentation/widgets/common/krivana_button.dart';
import '../../../presentation/widgets/common/krivana_text_field.dart';
import '../../../presentation/widgets/svg/krivana_svg.dart';

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
    final lastAtMs = settings.get(AppConstants.settingsLastAutoNotificationAt) as int?;
    if (lastAtMs != null) {
      final lastAt = DateTime.fromMillisecondsSinceEpoch(lastAtMs);
      if (now.difference(lastAt) < const Duration(hours: 1)) {
        return;
      }
    }

    final idx =
        (settings.get(AppConstants.settingsAutoNotificationIndex, defaultValue: 0)
                as int?) ??
            0;
    final template = _notificationTemplates[idx % _notificationTemplates.length];
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

    if (!mounted) return;
    _showNotificationBanner(notification);
    setState(() {});
  }

  void _showNotificationBanner(AppNotification notification) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/icon.png',
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
        content: Text(
          '${notification.title}\n${notification.body}',
          style: AppTextStyles.caption.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              context.push('/notifications');
            },
            child: const Text('View'),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted) return;
      messenger.hideCurrentMaterialBanner();
    });
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar - notifications left, brand center, settings right
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: GestureDetector(
                      onTap: () => context.push('/notifications'),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 24,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
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
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.accentPurple,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'K',
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentPurple,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Krivana',
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                ),
                                TextSpan(
                                  text: '.',
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.accentPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Feature cards grid
                    _FeatureCardsGrid(),

                    const SizedBox(height: 28),

                    // Projects section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Projects',
                          style: AppTextStyles.heading2.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/projects'),
                          child: Row(
                            children: [
                              Text(
                                'View All',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.accentPurple,
                                ),
                              ),
                              const SizedBox(width: 4),
                              KrivanaSvg(SvgPaths.icChevronRight,
                                  size: 14,
                                  color: AppColors.accentPurple),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Project cards with swipeable stack
                    if (projects.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            KrivanaSvg(
                              SvgPaths.illustEmptyProjects,
                              size: 120,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No projects yet',
                              style: AppTextStyles.body.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to create your first project',
                              style: AppTextStyles.caption.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _SwipeableProjectStack(projects: projects),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom bar with + and search
      bottomNavigationBar: _BottomActionBar(),
    );
  }
}

class _FeatureCardsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _FeatureCard(
          title: 'Scan QR',
          svgPath: SvgPaths.icQrScan,
          onTap: () => context.push('/qr-scanner'),
        ),
        _FeatureCard(
          title: 'Import Repo',
          svgPath: SvgPaths.icImportRepo,
          onTap: () => context.push('/import-repo'),
        ),
        _FeatureCard(
          title: 'AI Chat',
          svgPath: SvgPaths.icAiChat,
          onTap: () => context.push('/planning-chat'),
        ),
        _FeatureCard(
          title: 'Deploy',
          svgPath: SvgPaths.icDeploy,
          onTap: () => context.push('/deploy'),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final String title;
  final String svgPath;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.svgPath,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              KrivanaSvg(widget.svgPath, size: 28),
              Text(
                widget.title,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Swipeable project stack - user can swipe through all projects
class _SwipeableProjectStack extends ConsumerStatefulWidget {
  final List<ProjectModel> projects;

  const _SwipeableProjectStack({required this.projects});

  @override
  ConsumerState<_SwipeableProjectStack> createState() =>
      _SwipeableProjectStackState();
}

class _SwipeableProjectStackState
    extends ConsumerState<_SwipeableProjectStack>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  double _dragOffset = 0;
  late AnimationController _animController;
  late Animation<double> _dragAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateBack() {
    _dragAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0).then((_) {
      if (mounted) setState(() => _dragOffset = 0);
    });
    _dragAnimation.addListener(() {
      if (mounted) setState(() => _dragOffset = _dragAnimation.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() => _dragOffset += details.delta.dx);
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (_dragOffset.abs() > 80 || velocity.abs() > 500) {
          if ((_dragOffset < 0 || velocity < -500) &&
              _currentIndex < widget.projects.length - 1) {
            setState(() {
              _currentIndex++;
              _dragOffset = 0;
            });
          } else if ((_dragOffset > 0 || velocity > 500) && _currentIndex > 0) {
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
        height: 160,
        child: Stack(
          clipBehavior: Clip.none,
          children: _buildCards(isDark),
        ),
      ),
    );
  }

  List<Widget> _buildCards(bool isDark) {
    final cards = <Widget>[];
    final maxVisible = 3;
    for (int i = (maxVisible - 1).clamp(0, widget.projects.length - 1);
        i >= 0;
        i--) {
      final projIdx = _currentIndex + i;
      if (projIdx >= widget.projects.length) continue;

      final project = widget.projects[projIdx];
      final offset = i * 12.0;
      final scale = 1.0 - (i * 0.05);
      final opacity = 1.0 - (i * 0.2);

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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (project.isPinned) ...[
                                  KrivanaSvg(SvgPaths.icPin, size: 14),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    project.name,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              project.techStack ?? 'Not set',
                              style: AppTextStyles.caption.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (project.isGitHubImported)
                        KrivanaSvg(SvgPaths.logoGitHub,
                            size: 20, autoTheme: false),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Page indicator
    if (widget.projects.length > 1) {
      cards.add(
        Positioned(
          bottom: -24,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.projects.length.clamp(0, 10),
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentIndex ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
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
                          : Colors.black,
                    )),
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
                          : Colors.black,
                    )),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: KrivanaSvg(SvgPaths.icTrash, size: 20,
                    color: AppColors.error),
                title: const Text('Delete',
                    style: TextStyle(color: AppColors.error)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom action bar with + (create) and search (planning mode)
class _BottomActionBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassContainer(
              borderRadius: 50,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Create new
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showCreateSheet(context, ref);
                    },
                    child: KrivanaSvg(SvgPaths.icPlus, size: 24),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  // Search / Planning mode
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/planning-chat');
                    },
                    child: KrivanaSvg(SvgPaths.icSearch, size: 24),
                  ),
                ],
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
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
