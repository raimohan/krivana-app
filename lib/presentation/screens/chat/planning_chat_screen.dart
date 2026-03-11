import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/chat_model.dart';
import '../../../services/ai/ai_service.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/chat/chat_input_bar.dart';
import '../../widgets/chat/chat_sidebar.dart';
import '../../widgets/chat/thinking_indicator.dart';
import '../../widgets/glass/glass_container.dart';
import '../../widgets/svg/krivana_svg.dart';

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

class _PlanningChatScreenState extends ConsumerState<PlanningChatScreen>
    with TickerProviderStateMixin {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  List<ChatSession> _sessions = [];
  bool _sidebarOpen = false;
  bool _isThinking = false;
  bool _inputFocused = false;
  String _chatTitle = 'Untitled';
  String? _currentSessionId;
  bool _editingTitle = false;
  final _titleController = TextEditingController();

  // Typing suggestion state
  int _suggestionIndex = 0;
  String _currentSuggestion = '';
  Timer? _typingTimer;
  int _charPos = 0;
  bool _isTypingForward = true;

  // Gradient animation
  late AnimationController _gradientController;
  late Animation<Color?> _gradientColor1;
  late Animation<Color?> _gradientColor2;

  @override
  void initState() {
    super.initState();

    // Gradient animation for "today?" text
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _gradientColor1 = ColorTween(
      begin: AppColors.accentPurple,
      end: AppColors.accentPink,
    ).animate(CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut));
    _gradientColor2 = ColorTween(
      begin: AppColors.accentPink,
      end: AppColors.accentPurple,
    ).animate(CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut));

    _inputController.addListener(() {
      final hasFocus = _inputController.text.isNotEmpty;
      if (hasFocus != _inputFocused) {
        setState(() => _inputFocused = hasFocus);
      }
    });
    _loadSessions();
    if (_messages.isEmpty) {
      _startSuggestionCycle();
    }
  }

  Future<void> _loadSessions() async {
    final box = Hive.box(AppConstants.hiveChatBox);
    final raw = box.get('planning_sessions');
    if (raw != null) {
      final list = (raw as List).cast<Map>();
      _sessions = list.map((e) {
        final map = Map<String, dynamic>.from(e);
        return ChatSession(
          id: map['id'] as String,
          title: map['title'] as String,
          isPinned: map['is_pinned'] as bool? ?? false,
          createdAt: map['created_at'] != null
              ? DateTime.parse(map['created_at'] as String)
              : null,
          messages: (map['messages'] as List?)
                  ?.cast<Map>()
                  .map((m) =>
                      ChatMessage.fromJson(Map<String, dynamic>.from(m)))
                  .toList() ??
              [],
        );
      }).toList();
      if (mounted) setState(() {});
    }
  }

  Future<void> _saveSessions() async {
    final box = Hive.box(AppConstants.hiveChatBox);
    final data = _sessions.map((s) => {
          'id': s.id,
          'title': s.title,
          'is_pinned': s.isPinned,
          'created_at': s.createdAt?.toIso8601String(),
          'messages': s.messages.map((m) => m.toJson()).toList(),
        }).toList();
    await box.put('planning_sessions', data);
  }

  void _saveCurrentSession() {
    if (_currentSessionId == null || _messages.isEmpty) return;
    final idx = _sessions.indexWhere((s) => s.id == _currentSessionId);
    final session = ChatSession(
      id: _currentSessionId!,
      title: _chatTitle,
      createdAt: idx >= 0
          ? _sessions[idx].createdAt
          : DateTime.now(),
      messages: List.from(_messages),
    );
    if (idx >= 0) {
      _sessions[idx] = session;
    } else {
      _sessions.insert(0, session);
    }
    _saveSessions();
  }

  void _startSuggestionCycle() {
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
          setState(
              () => _currentSuggestion = target.substring(0, _charPos));
          _typeNextChar();
        } else {
          _typingTimer = Timer(const Duration(milliseconds: 1200), () {
            _isTypingForward = false;
            _typeNextChar();
          });
        }
      } else {
        if (_charPos > 0) {
          _charPos--;
          setState(
              () => _currentSuggestion = target.substring(0, _charPos));
          _typeNextChar();
        } else {
          _suggestionIndex++;
          _isTypingForward = true;
          _typingTimer = Timer(const Duration(milliseconds: 300), () {
            _typeNextChar();
          });
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    // Create session on first message
    if (_currentSessionId == null) {
      _currentSessionId = const Uuid().v4();
      // Auto-title from first message
      _chatTitle = text.length > 30 ? '${text.substring(0, 30)}...' : text;
    }

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
    _saveCurrentSession();

    // Call real AI API
    try {
      final aiService = AiService.instance;
      await aiService.loadConfig();

      final apiMessages = _messages.map((m) => {
        'role': m.role == ChatRole.user ? 'user' : 'assistant',
        'content': m.content,
      }).toList();

      final response = await aiService.sendMessage(apiMessages);

      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          role: ChatRole.assistant,
          content: response,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _messages.add(ChatMessage(
          id: const Uuid().v4(),
          role: ChatRole.assistant,
          content:
              'Error: ${e.toString().replaceAll('Exception: ', '')}\n\nPlease check your API key in Settings > AI Configuration.',
          timestamp: DateTime.now(),
        ));
      });
    }

    _scrollToBottom();
    _saveCurrentSession();
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

  void _loadSession(String sessionId) {
    final session = _sessions.firstWhere((s) => s.id == sessionId,
        orElse: () => const ChatSession(id: '', title: ''));
    if (session.id.isEmpty) return;

    setState(() {
      _messages.clear();
      _messages.addAll(session.messages);
      _chatTitle = session.title;
      _currentSessionId = session.id;
      _sidebarOpen = false;
    });
  }

  void _startNewChat() {
    _saveCurrentSession();
    setState(() {
      _messages.clear();
      _chatTitle = 'Untitled';
      _currentSessionId = null;
      _sidebarOpen = false;
    });
    _startSuggestionCycle();
  }

  @override
  void dispose() {
    _saveCurrentSession();
    _inputController.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _typingTimer?.cancel();
    _gradientController.dispose();
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
                // Top bar with title
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _sidebarOpen = !_sidebarOpen);
                        },
                        child: KrivanaSvg(SvgPaths.icMenuHamburger, size: 24),
                      ),
                      const SizedBox(width: 12),
                      // Title with edit
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _editingTitle = true);
                            _titleController.text = _chatTitle;
                          },
                          child: _editingTitle
                              ? TextField(
                                  controller: _titleController,
                                  autofocus: true,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (val) {
                                    setState(() {
                                      _chatTitle =
                                          val.isEmpty ? 'Untitled' : val;
                                      _editingTitle = false;
                                    });
                                    _saveCurrentSession();
                                  },
                                )
                              : Text(
                                  _chatTitle,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ),
                      if (!_editingTitle)
                        GestureDetector(
                          onTap: () {
                            setState(() => _editingTitle = true);
                            _titleController.text = _chatTitle;
                          },
                          child: KrivanaSvg(SvgPaths.icEdit, size: 18),
                        ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _startNewChat,
                        child: GlassContainer(
                          borderRadius: 20,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              KrivanaSvg(SvgPaths.icPlus, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'New Chat',
                                style: AppTextStyles.caption.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chat area
                Expanded(
                  child:
                      isEmpty ? _buildEmptyState(isDark) : _buildMessages(isDark),
                ),

                // Prompt chips
                if (isEmpty && !_inputFocused)
                  SizedBox(
                    height: 50,
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
                              horizontal: 16, vertical: 10),
                          child: Center(
                            child: Text(
                              _promptChips[index],
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.accentPurple,
                                height: 1.2,
                              ),
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
                pinnedSessions:
                    _sessions.where((s) => s.isPinned).toList(),
                onNewChat: _startNewChat,
                onSelectSession: _loadSession,
                onClose: () => setState(() => _sidebarOpen = false),
                onDeleteSession: (id) {
                  setState(() {
                    _sessions.removeWhere((s) => s.id == id);
                  });
                  _saveSessions();
                },
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
          AnimatedBuilder(
            animation: _gradientController,
            builder: (_, __) => RichText(
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
                        ..shader = LinearGradient(
                          colors: [
                            _gradientColor1.value ?? AppColors.accentPurple,
                            _gradientColor2.value ?? AppColors.accentPink,
                          ],
                        ).createShader(const Rect.fromLTWH(0, 0, 100, 40)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
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
