import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/file_model.dart';
import '../../widgets/editor/file_tree_tile.dart';
import '../../widgets/glass/glass_container.dart';

class FileExplorerScreen extends ConsumerStatefulWidget {
  const FileExplorerScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends ConsumerState<FileExplorerScreen> {
  List<FileItem> _files = [];
  final Set<String> _selected = {};
  bool _selectionMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    // TODO: Load from backend
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _files = [];
      _isLoading = false;
    });
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selected.contains(path)) {
        _selected.remove(path);
        if (_selected.isEmpty) _selectionMode = false;
      } else {
        _selected.add(path);
      }
    });
  }

  void _enterSelectionMode(String path) {
    setState(() {
      _selectionMode = true;
      _selected.add(path);
    });
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
              child: _selectionMode
                  ? Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectionMode = false;
                              _selected.clear();
                            });
                          },
                          child: SvgPicture.asset(SvgPaths.icClose,
                              width: 24, height: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_selected.length} selected',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: SvgPicture.asset(SvgPaths.icBack,
                              width: 24, height: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Project Files',
                            style: AppTextStyles.heading2.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showFileMenu(context),
                          child: SvgPicture.asset(SvgPaths.icThreeDots,
                              width: 24, height: 24),
                        ),
                      ],
                    ),
            ),

            // File tree
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _files.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(SvgPaths.icFileExplorer,
                                  width: 56, height: 56),
                              const SizedBox(height: 16),
                              Text(
                                'No files yet',
                                style: AppTextStyles.body.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Use AI Chat to generate code or create files manually',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _files.length,
                          itemBuilder: (_, index) {
                            final file = _files[index];
                            return FileTreeTile(
                              file: file,
                              selectionMode: _selectionMode,
                              isSelected: _selected.contains(file.path),
                              onTap: () {
                                if (!file.isDirectory) {
                                  context.push('/editor', extra: {
                                    'filePath': file.path,
                                    'projectId': widget.projectId,
                                  });
                                }
                              },
                              onLongPress: () =>
                                  _enterSelectionMode(file.path),
                              onSelect: (selected) =>
                                  _toggleSelection(file.path),
                              onMenuTap: () =>
                                  _showItemMenu(context, file),
                            );
                          },
                        ),
            ),

            // Bottom action bar
            if (_selectionMode)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const _BottomAction(icon: Icons.drive_file_move, label: 'Move'),
                    const _BottomAction(icon: Icons.copy_rounded, label: 'Copy'),
                    const _BottomAction(
                        icon: Icons.delete_outline, label: 'Delete'),
                    _BottomAction(
                      icon: Icons.close,
                      label: 'Cancel',
                      onTap: () {
                        setState(() {
                          _selectionMode = false;
                          _selected.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      // Create + Import buttons
      floatingActionButton: _selectionMode
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Create file
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: show create file dialog
                  },
                  child: GlassContainer(
                    borderRadius: 50,
                    padding: const EdgeInsets.all(14),
                    tintOpacity: 0.12,
                    child: SvgPicture.asset(SvgPaths.icPlus,
                        width: 20, height: 20),
                  ),
                ),
                const SizedBox(width: 12),
                // Import file
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // TODO: open file picker
                  },
                  child: GlassContainer(
                    borderRadius: 50,
                    padding: const EdgeInsets.all(14),
                    tintOpacity: 0.12,
                    child: SvgPicture.asset(SvgPaths.icUpload,
                        width: 20, height: 20),
                  ),
                ),
              ],
            ),
    );
  }

  void _showFileMenu(BuildContext context) {
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
              leading:
                  SvgPicture.asset(SvgPaths.icPlus, width: 20, height: 20),
              title: const Text('New File'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: SvgPicture.asset(SvgPaths.icUpload,
                  width: 20, height: 20),
              title: const Text('Import File'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: SvgPicture.asset(SvgPaths.icRefresh,
                  width: 20, height: 20),
              title: const Text('Refresh'),
              onTap: () {
                Navigator.pop(context);
                _loadFiles();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showItemMenu(BuildContext context, FileItem file) {
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
              leading:
                  SvgPicture.asset(SvgPaths.icEdit, width: 20, height: 20),
              title: const Text('Rename'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: SvgPicture.asset(SvgPaths.icMove,
                  width: 20, height: 20),
              title: const Text('Move'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading:
                  SvgPicture.asset(SvgPaths.icCopy, width: 20, height: 20),
              title: const Text('Copy'),
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

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
