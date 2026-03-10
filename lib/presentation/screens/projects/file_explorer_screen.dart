import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/file_model.dart';
import '../../widgets/common/krivana_text_field.dart';
import '../../widgets/common/krivana_button.dart';
import '../../widgets/editor/file_tree_tile.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/svg/krivana_svg.dart';

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
    final box = Hive.box(AppConstants.hiveProjectsBox);
    final raw = box.get('files_${widget.projectId}');
    if (raw != null) {
      final list = (raw as List).cast<Map>();
      _files = list.map((e) => FileItem.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      _files = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveFiles() async {
    final box = Hive.box(AppConstants.hiveProjectsBox);
    await box.put('files_${widget.projectId}', _files.map((f) => f.toJson()).toList());
  }

  void _createFile(String name) {
    if (name.trim().isEmpty) return;
    final file = FileItem(
      name: name.trim(),
      path: '/${name.trim()}',
      isDirectory: name.trim().endsWith('/'),
      content: '',
    );
    setState(() => _files.add(file));
    _saveFiles();
  }

  Future<void> _importFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      if (result != null) {
        for (final file in result.files) {
          if (file.name.isNotEmpty) {
            final item = FileItem(
              name: file.name,
              path: '/${file.name}',
              isDirectory: false,
              content: '',
              size: file.size,
            );
            setState(() => _files.add(item));
          }
        }
        _saveFiles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import: $e')),
        );
      }
    }
  }

  void _deleteFile(String path) {
    setState(() => _files.removeWhere((f) => f.path == path));
    _saveFiles();
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
                          child: KrivanaSvg(SvgPaths.icClose, size: 24),
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
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
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
                          child: KrivanaSvg(SvgPaths.icThreeDots, size: 24),
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
                              KrivanaSvg(SvgPaths.icFileExplorer, size: 56),
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
                    _showCreateFileDialog();
                  },
                  child: GlassContainer(
                    borderRadius: 50,
                    padding: const EdgeInsets.all(14),
                    tintOpacity: 0.12,
                    child: KrivanaSvg(SvgPaths.icPlus, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                // Import file
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _importFile();
                  },
                  child: GlassContainer(
                    borderRadius: 50,
                    padding: const EdgeInsets.all(14),
                    tintOpacity: 0.12,
                    child: KrivanaSvg(SvgPaths.icUpload, size: 20),
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
      builder: (_) => SafeArea(
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: KrivanaSvg(SvgPaths.icPlus, size: 20),
                title: Text('New File',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _showCreateFileDialog();
                },
              ),
              ListTile(
                leading: KrivanaSvg(SvgPaths.icUpload, size: 20),
                title: Text('Import File',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _importFile();
                },
              ),
              ListTile(
                leading: KrivanaSvg(SvgPaths.icRefresh, size: 20),
                title: Text('Refresh',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white : Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _loadFiles();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateFileDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
                  'New File',
                  style: AppTextStyles.heading2.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                KrivanaTextField(
                  controller: controller,
                  hint: 'File name (e.g. main.dart)',
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                KrivanaButton(
                  label: 'Create',
                  width: double.infinity,
                  onTap: () {
                    _createFile(controller.text);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showItemMenu(BuildContext context, FileItem file) {
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
                leading: KrivanaSvg(SvgPaths.icEdit, size: 20),
                title: Text('Rename',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white : Colors.black)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: KrivanaSvg(SvgPaths.icMove, size: 20),
                title: Text('Move',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white : Colors.black)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: KrivanaSvg(SvgPaths.icCopy, size: 20),
                title: Text('Copy',
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
                onTap: () {
                  Navigator.pop(context);
                  _deleteFile(file.path);
                },
              ),
            ],
          ),
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
