import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:re_editor/re_editor.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/re_highlight.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/svg/krivana_svg.dart';

class CodeEditorScreen extends ConsumerStatefulWidget {
  const CodeEditorScreen({
    super.key,
    required this.filePath,
    required this.projectId,
  });

  final String filePath;
  final String projectId;

  @override
  ConsumerState<CodeEditorScreen> createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends ConsumerState<CodeEditorScreen> {
  late CodeLineEditingController _controller;
  String _content = '';
  bool _isLoading = true;
  bool _hasChanges = false;

  String get _fileName => widget.filePath.split('/').last;

  String get _extension {
    final dot = _fileName.lastIndexOf('.');
    return dot == -1 ? '' : _fileName.substring(dot + 1);
  }

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController();
    _loadFile();
  }

  Future<void> _loadFile() async {
    // TODO: Load from backend
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _content = '// File: ${widget.filePath}\n// Start editing...\n';
      _controller = CodeLineEditingController.fromText(_content);
      _isLoading = false;
    });
  }

  Future<void> _saveFile() async {
    // TODO: Save to backend
    HapticFeedback.mediumImpact();
    setState(() => _hasChanges = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File saved'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  CodeHighlightTheme _buildCodeTheme() {
    final mode = _getLanguageMode();
    final languages = <String, CodeHighlightThemeMode>{};
    if (mode != null) {
      languages[_extension] = CodeHighlightThemeMode(mode: mode);
    }
    return CodeHighlightTheme(
      languages: languages,
      theme: {},
    );
  }

  Mode? _getLanguageMode() {
    return switch (_extension) {
      'dart' => langDart,
      'js' || 'jsx' => langJavascript,
      'ts' || 'tsx' => langTypescript,
      'html' || 'htm' || 'xml' => langXml,
      'css' || 'scss' => langCss,
      'json' => langJson,
      'py' => langPython,
      'yaml' || 'yml' => langYaml,
      'md' => langMarkdown,
      _ => null,
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fileName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        if (_hasChanges)
                          Text(
                            'Unsaved changes',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              color: AppColors.warning,
                            ),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showEditorMenu(context),
                    child: KrivanaSvg(SvgPaths.icThreeDots, size: 24),
                  ),
                ],
              ),
            ),

            // Editor
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CodeEditor(
                      controller: _controller,
                      style: CodeEditorStyle(
                        fontSize: 14,
                        fontFamily: 'Courier New',
                        backgroundColor: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        textColor: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        codeTheme: _buildCodeTheme(),
                      ),
                      indicatorBuilder: (context, editingController,
                          chunkController, notifier) {
                        return Row(
                          children: [
                            DefaultCodeLineNumber(
                              controller: editingController,
                              notifier: notifier,
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditorMenu(BuildContext context) {
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
              leading: const Icon(Icons.save_rounded),
              title: const Text('Save'),
              onTap: () {
                Navigator.pop(context);
                _saveFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.save_as_rounded),
              title: const Text('Save As'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.undo_rounded),
              title: const Text('Undo'),
              onTap: () {
                Navigator.pop(context);
                // _controller.undo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.redo_rounded),
              title: const Text('Redo'),
              onTap: () {
                Navigator.pop(context);
                // _controller.redo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete file'),
              onTap: () {
                Navigator.pop(context);
                // TODO: delete file
              },
            ),
          ],
        ),
      ),
    );
  }
}
