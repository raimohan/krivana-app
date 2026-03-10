import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/project_model.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/svg/krivana_svg.dart';

class AllProjectsScreen extends ConsumerStatefulWidget {
  const AllProjectsScreen({super.key});

  @override
  ConsumerState<AllProjectsScreen> createState() => _AllProjectsScreenState();
}

enum _ProjectFilter { all, created, github }

class _AllProjectsScreenState extends ConsumerState<AllProjectsScreen> {
  _ProjectFilter _filter = _ProjectFilter.all;
  bool _isGrid = true;
  List<ProjectModel> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _loadProjects() {
    final box = Hive.box(AppConstants.hiveProjectsBox);
    final raw = box.values.toList();
    setState(() {
      _projects = raw
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
  }

  List<ProjectModel> get _filtered {
    return switch (_filter) {
      _ProjectFilter.all => _projects,
      _ProjectFilter.created =>
        _projects.where((p) => !p.isGitHubImported).toList(),
      _ProjectFilter.github =>
        _projects.where((p) => p.isGitHubImported).toList(),
    };
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
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
                  const SizedBox(width: 16),
                  Text(
                    'All Projects',
                    style: AppTextStyles.heading2.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _isGrid = !_isGrid),
                    child: Icon(
                      _isGrid ? Icons.list_rounded : Icons.grid_view_rounded,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'All',
                    isActive: _filter == _ProjectFilter.all,
                    onTap: () =>
                        setState(() => _filter = _ProjectFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Created',
                    isActive: _filter == _ProjectFilter.created,
                    onTap: () =>
                        setState(() => _filter = _ProjectFilter.created),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'GitHub',
                    isActive: _filter == _ProjectFilter.github,
                    onTap: () =>
                        setState(() => _filter = _ProjectFilter.github),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Projects
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          KrivanaSvg(SvgPaths.illustEmptyProjects, size: 120),
                          const SizedBox(height: 16),
                          Text(
                            'No projects found',
                            style: AppTextStyles.body.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _isGrid
                      ? GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _ProjectCard(project: _filtered[i]),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) =>
                              _ProjectCard(project: _filtered[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        tintOpacity: isActive ? 0.12 : 0.04,
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: isActive
                ? AppColors.accentPurple
                : (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.push('/projects/${project.id}/files'),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showMenu(context);
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        tintOpacity: project.isGitHubImported ? 0.08 : 0.06,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (project.isPinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: KrivanaSvg(SvgPaths.icPin, size: 12),
                  ),
                Expanded(
                  child: Text(
                    project.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (project.isGitHubImported)
                  KrivanaSvg(SvgPaths.logoGitHub, size: 16, autoTheme: false),
              ],
            ),
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
    );
  }

  void _showMenu(BuildContext context) {
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
                          ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/project-chat/${project.id}');
                },
              ),
              ListTile(
                leading: KrivanaSvg(SvgPaths.icEdit, size: 20),
                title: Text('Rename',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white : Colors.black)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: KrivanaSvg(SvgPaths.icPin, size: 20),
                title: Text(project.isPinned ? 'Unpin' : 'Pin',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white : Colors.black)),
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
