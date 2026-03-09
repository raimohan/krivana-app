import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/file_model.dart';

class FileTreeTile extends StatefulWidget {
  const FileTreeTile({
    super.key,
    required this.file,
    this.depth = 0,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.selectionMode = false,
    this.onSelect,
    this.onMenuTap,
  });

  final FileItem file;
  final int depth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool selectionMode;
  final ValueChanged<bool>? onSelect;
  final VoidCallback? onMenuTap;

  @override
  State<FileTreeTile> createState() => _FileTreeTileState();
}

class _FileTreeTileState extends State<FileTreeTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.file.isDirectory) {
      setState(() {
        _expanded = !_expanded;
        if (_expanded) {
          _expandController.forward();
        } else {
          _expandController.reverse();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final file = widget.file;
    final indent = widget.depth * 20.0;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            if (widget.selectionMode) {
              widget.onSelect?.call(!widget.isSelected);
            } else if (file.isDirectory) {
              _toggle();
            } else {
              widget.onTap?.call();
            }
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            widget.onLongPress?.call();
          },
          child: Container(
            color: widget.isSelected
                ? AppColors.accentPurple.withValues(alpha: 0.1)
                : Colors.transparent,
            padding: EdgeInsets.only(
                left: 16 + indent, right: 8, top: 10, bottom: 10),
            child: Row(
              children: [
                if (widget.selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      widget.isSelected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 18,
                      color: widget.isSelected
                          ? AppColors.accentPurple
                          : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextSecondary),
                    ),
                  ),

                // Icon
                if (file.isDirectory) ...[
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: SvgPicture.asset(SvgPaths.icChevronRight,
                        width: 14, height: 14),
                  ),
                  const SizedBox(width: 6),
                  SvgPicture.asset(SvgPaths.icFolder,
                      width: 18, height: 18),
                ] else ...[
                  const SizedBox(width: 20),
                  SvgPicture.asset(
                    SvgPaths.fileIcon(file.extension),
                    width: 18,
                    height: 18,
                  ),
                ],

                const SizedBox(width: 10),

                // Name
                Expanded(
                  child: Text(
                    file.name,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Menu
                if (widget.onMenuTap != null)
                  GestureDetector(
                    onTap: widget.onMenuTap,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: SvgPicture.asset(SvgPaths.icThreeDots,
                          width: 16, height: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Children (for folders)
        if (file.isDirectory && file.children.isNotEmpty)
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: file.children
                  .map((child) => FileTreeTile(
                        file: child,
                        depth: widget.depth + 1,
                        onTap: widget.onTap,
                        selectionMode: widget.selectionMode,
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
