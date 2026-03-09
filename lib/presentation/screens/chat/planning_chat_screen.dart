import 'dart:async';
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

const _suggestions = [
  'I want to build a SaaS landing page...',
  'Help me create a portfolio site...',
  'Build me a React e-commerce app...',
  'I need a Next.js blog with CMS...',
  'Design me a dashboard for analytics...',
];

const _promptChips = [
  'Plan a SaaS app',
  'Design a landing page',
  'Help me structure my idea',
];

class PlanningChatScreen extends ConsumerStatefulWidget {
  const PlanningChatScreen({super.key});

  @override
  ConsumerState<PlanningChatScreen> createState() => _PlanningChatScreenState();
}

class _PlanningChatScreenState extends ConsumerState<PlanningChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<ChatSession> _sessions = [];
  bool _sidebarOpen = false;
  bool _isThinking = false;
  bool _inputFocused = false;

  // Typing suggestion state
  int _suggestionIndex = 0;
  String _currentSuggestion = '';
  Timer? _typingTimer;
  Timer? _cycleTimer;
  int _charPos = 0;
  bool _isTypingForward = true;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      final hasFocus = _inputController.text.isNotEmpty;
      if (hasFocus != _inputFocused) {
        setState(() => _inputFocused = hasFocus);
      }
    });
    if (_messages.isEmpty) {
      _startSuggestionCycle();
    }
  }

  void _startSuggestionCycle() {
    _cycleTimer?.cancel();
    _typingTimer?.cancel();
    _charPos = 0;
    _isTypingForward = true;
    _currentSuggestion = '';
    _typeNextChar();
  }

  void _typeNextChar() {
    _typingTimer = Timer(const Duration(milliseconds: 60), () {
      if (!mounted || _inputFocused || _messages.isNotEmpty) return;

      final target = _suggestions[_suggestionIndex % _suggestions.length];

      if (_isTypingForward) {
        if (_charPos < target.length) {
          _charPos++;
          setState(() {
            _currentSuggestion = target.substring(0, _charPos);
          });
          _typeNextChar();
        } else {
          // Pause at end, then reverse
          _typingTimer = Timer(const Duration(milliseconds: 1200), () {
            _isTypingForward = false;
            _typeNextChar();
          });
        }
      } else {
        if (_charPos > 0) {
          _charPos--;
          setState(() {
            _currentSuggestion = target.substring(0, _charPos);
          });
          _typeNextChar();
        } else {
          // Move to next suggestion
          _suggestionIndex++;
          _isTypingForward = true;
          _typingTimer = Timer(const Duration(milliseconds: 300), () {
            _typeNextChar();
          });
        }
      }
    });
  }

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
              'I can help you with that! Let me think about the best approach...\n\n'
              'Here are some ideas to consider:\n'
              '- Start with a clear project structure\n'
              '- Define your tech stack early\n'
              '- Plan the core features first\n\n'
              'Would you like me to elaborate on any of these?',
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
    _typingTimer?.cancel();
    _cycleTimer?.cancel();
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
            // Main content
            Column(
              children: [
                // Top bar
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
                      GestureDetector(
                        onTap: () {},
                        child: SvgPicture.asset(SvgPaths.icSettings,
                            width: 22, height: 22),
                      ),
                    ],
                  ),
                ),

                // Chat area
                Expanded(
                  child: isEmpty
                      ? _buildEmptyState(isDark)
                      : _buildMessages(isDark),
                ),

                // Prompt chips
                if (isEmpty && !_inputFocused)
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _promptChips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) => GestureDetector(
                        onTap: () {
                          _inputController.text = _promptChips[index];
                          setState(() => _inputFocused = true);
                        },
                        child: GlassContainer(
                          borderRadius: 20,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          tintOpacity: 0.06,
                          child: Text(
                            _promptChips[index],
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accentPurple,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (isEmpty && !_inputFocused) const SizedBox(height: 8),

                // Input bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: ChatInputBar(
                    controller: _inputController,
                    onSend: _sendMessage,
                    hintText: 'Ask anything...',
                  ),
                ),
              ],
            ),

            // Sidebar overlay
            if (_sidebarOpen) ...[
              GestureDetector(
                onTap: () => setState(() => _sidebarOpen = false),
                child: Container(color: Colors.black54),
              ),
              ChatSidebar(
                sessions: _sessions,
                pinnedSessions: _sessions.where((s) => s.isPinned).toList(),
                onNewChat: () {
                  setState(() {
                    _messages.clear();
                    _sidebarOpen = false;
                  });
                  _startSuggestionCycle();
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Greeting
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.chatGreeting.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              children: [
                const TextSpan(text: 'What are you planning\nto build '),
                TextSpan(
                  text: 'today?',
                  style: AppTextStyles.chatGreeting.copyWith(
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [AppColors.accentPink, AppColors.accentPurple],
                      ).createShader(
                          const Rect.fromLTWH(0, 0, 100, 40)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Typing suggestion
          if (_currentSuggestion.isNotEmpty && !_inputFocused)
            Text(
              _currentSuggestion,
              style: AppTextStyles.body.copyWith(
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessages(bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _messages.length + (_isThinking ? 1 : 0),
      itemBuilder: (_, index) {
        if (index == _messages.length && _isThinking) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: ThinkingIndicator(),
          );
        }
        return ChatBubble(message: _messages[index]);
      },
    );
  }
}
