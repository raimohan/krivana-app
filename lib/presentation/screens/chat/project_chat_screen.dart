import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/chat_model.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/chat/chat_input_bar.dart';
import '../../widgets/chat/chat_sidebar.dart';
import '../../widgets/chat/thinking_indicator.dart';
import '../../widgets/glass/glass_container.dart';

const _projectPromptChips = [
  'Build a landing page',
  'Add authentication',
  'Create a dashboard',
  'Style with Tailwind',
];

class ProjectChatScreen extends ConsumerStatefulWidget {
  const ProjectChatScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<ProjectChatScreen> createState() => _ProjectChatScreenState();
}

class _ProjectChatScreenState extends ConsumerState<ProjectChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<ChatSession> _sessions = [];
  bool _sidebarOpen = false;
  bool _isThinking = false;
  bool _showChat = true; // true = Chat, false = Preview

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      role: ChatRole.user,
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isThinking = true;
    });
    _inputController.clear();
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          role: ChatRole.assistant,
          content:
              'I\'m working on that for your project. Let me generate the code...\n\n'
              '```html\n'
              '<!DOCTYPE html>\n'
              '<html lang="en">\n'
              '<head><title>Your App</title></head>\n'
              '<body>\n'
              '  <h1>Hello World</h1>\n'
              '</body>\n'
              '</html>\n'
              '```\n\n'
              'I\'ve created the initial file. Would you like me to continue?',
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEmpty = _messages.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar with Chat/Preview toggle
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _sidebarOpen = !_sidebarOpen);
                        },
                        child: SvgPicture.asset(SvgPaths.icMenuHamburger,
                            width: 24, height: 24),
                      ),
                      const Spacer(),
                      // Chat / Preview toggle
                      GlassContainer(
                        borderRadius: 20,
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          children: [
                            _ToggleButton(
                              label: 'Chat',
                              isActive: _showChat,
                              onTap: () =>
                                  setState(() => _showChat = true),
                            ),
                            _ToggleButton(
                              label: 'Preview',
                              isActive: !_showChat,
                              onTap: () =>
                                  setState(() => _showChat = false),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {},
                        child: SvgPicture.asset(SvgPaths.icSettings,
                            width: 22, height: 22),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _showChat ? _buildChatPanel(isDark, isEmpty) : _buildPreviewPanel(isDark),
                ),
              ],
            ),

            // Sidebar
            if (_sidebarOpen) ...[
              GestureDetector(
                onTap: () => setState(() => _sidebarOpen = false),
                child: Container(color: Colors.black54),
              ),
              ChatSidebar(
                sessions: _sessions,
                pinnedSessions:
                    _sessions.where((s) => s.isPinned).toList(),
                onNewChat: () {
                  setState(() {
                    _messages.clear();
                    _sidebarOpen = false;
                  });
                },
                onSelectSession: (id) {
                  setState(() => _sidebarOpen = false);
                },
                onClose: () => setState(() => _sidebarOpen = false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatPanel(bool isDark, bool isEmpty) {
    return Column(
      children: [
        Expanded(
          child: isEmpty
              ? Center(
                  child: Text(
                    'Start building your project',
                    style: AppTextStyles.body.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount:
                      _messages.length + (_isThinking ? 1 : 0),
                  itemBuilder: (_, index) {
                    if (index == _messages.length && _isThinking) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: ThinkingIndicator(),
                      );
                    }
                    return ChatBubble(message: _messages[index]);
                  },
                ),
        ),

        // Prompt chips
        if (isEmpty)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _projectPromptChips.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) => GestureDetector(
                onTap: () {
                  _inputController.text = _projectPromptChips[index];
                },
                child: GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  tintOpacity: 0.06,
                  child: Text(
                    _projectPromptChips[index],
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accentPurple,
                    ),
                  ),
                ),
              ),
            ),
          ),

        if (isEmpty) const SizedBox(height: 8),

        // Input
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ChatInputBar(
            controller: _inputController,
            onSend: _sendMessage,
            hintText: 'Describe what you want to build...',
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewPanel(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(SvgPaths.icPreview, width: 56, height: 56),
          const SizedBox(height: 16),
          Text(
            'Preview will appear here',
            style: AppTextStyles.body.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start building to see a live preview',
            style: AppTextStyles.caption.copyWith(
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accentPurple.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: isActive
                ? AppColors.accentPurple
                : (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
