import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import 'package:riverpod/legacy.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/project_model.dart';
import '../../../presentation/widgets/glass/glass_container.dart';
import '../../../presentation/widgets/common/krivana_button.dart';
import '../../../presentation/widgets/common/krivana_text_field.dart';

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

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = ref.watch(_projectsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Notifications
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: SvgPicture.asset(SvgPaths.icNotifications,
                        width: 24, height: 24),
                  ),
                  const Spacer(),
                  // Logo
                  SvgPicture.asset(SvgPaths.krivanaIcon,
                      width: 28, height: 28),
                  const Spacer(),
                  // Settings
                  GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: SvgPicture.asset(SvgPaths.icSettings,
                        width: 24, height: 24),
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
                    const SizedBox(height: 16),

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
                              SvgPicture.asset(SvgPaths.icChevronRight,
                                  width: 14, height: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Project cards
                    if (projects.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            SvgPicture.asset(
                              SvgPaths.illustEmptyProjects,
                              width: 120,
                              height: 120,
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
                      _ProjectStack(projects: projects.take(3).toList()),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // FAB
      floatingActionButton: _NewProjectFAB(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              SvgPicture.asset(widget.svgPath, width: 28, height: 28),
              Text(
                widget.title,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
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

class _ProjectStack extends ConsumerWidget {
  final List<ProjectModel> projects;

  const _ProjectStack({required this.projects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(projects.length, (index) {
          final project = projects[index];
          final offset = index * 12.0;
          final scale = 1.0 - (index * 0.04);

          return Positioned(
            top: offset,
            left: 0,
            right: 0,
            child: Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/projects/${project.id}/files');
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  _showProjectMenu(context, ref, project);
                },
                child: GlassContainer(
                  padding: const EdgeInsets.all(20),
                  tintOpacity: project.isGitHubImported ? 0.08 : 0.07,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (project.isPinned) ...[
                                  SvgPicture.asset(SvgPaths.icPin,
                                      width: 14, height: 14),
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
                        SvgPicture.asset(SvgPaths.logoGitHub,
                            width: 20, height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showProjectMenu(
      BuildContext context, WidgetRef ref, ProjectModel project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: SvgPicture.asset(SvgPaths.icAiChat,
                  width: 20, height: 20),
              title: const Text('Open in Chat'),
              onTap: () {
                Navigator.pop(context);
                context.push('/project-chat/${project.id}');
              },
            ),
            ListTile(
              leading:
                  SvgPicture.asset(SvgPaths.icPin, width: 20, height: 20),
              title: Text(project.isPinned ? 'Unpin' : 'Pin'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: SvgPicture.asset(SvgPaths.icTrash,
                  width: 20, height: 20),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewProjectFAB extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showCreateSheet(context, ref);
      },
      child: GlassContainer(
        borderRadius: 50,
        padding: const EdgeInsets.all(16),
        tintOpacity: 0.12,
        child: SvgPicture.asset(SvgPaths.icPlus, width: 24, height: 24),
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

                  // Refresh provider
                  ref.invalidate(_projectsProvider);

                  Navigator.pop(ctx);
                  context.push('/project-chat/${project.id}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
