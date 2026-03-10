import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../presentation/widgets/common/krivana_button.dart';
import '../../../presentation/widgets/common/krivana_text_field.dart';
import '../../../presentation/widgets/glass/glass_container.dart';
import '../../../presentation/widgets/svg/krivana_svg.dart';
import '../../../services/ai/ai_service.dart';

class _ProviderConfig {
  final String name;
  final String logoPath;
  final List<String> models;
  final bool hasCustomModel;

  const _ProviderConfig({
    required this.name,
    required this.logoPath,
    required this.models,
    this.hasCustomModel = false,
  });
}

const _providers = [
  _ProviderConfig(
    name: 'OpenAI',
    logoPath: SvgPaths.logoOpenAI,
    models: ['GPT-5.4 Pro', 'GPT-5.4 Thinking', 'GPT-5.3 Instant', 'GPT-5.2'],
  ),
  _ProviderConfig(
    name: 'Anthropic',
    logoPath: SvgPaths.logoAnthropic,
    models: ['Claude Opus 4.6', 'Claude Sonnet 4.6', 'Claude Haiku 4.5', 'Claude Opus 4.5'],
  ),
  _ProviderConfig(
    name: 'Google',
    logoPath: SvgPaths.logoGemini,
    models: ['Gemini 3.1 Pro Preview', 'Gemini 3.1 Flash-Lite', 'Gemini 3 Deep Think'],
  ),
  _ProviderConfig(
    name: 'Groq',
    logoPath: SvgPaths.logoGroq,
    models: ['Llama 4 Maverick', 'DeepSeek V4', 'Qwen3 Max Thinking'],
  ),
  _ProviderConfig(
    name: 'Together AI',
    logoPath: SvgPaths.logoTogetherAI,
    models: ['Llama 4 Maverick', 'Mistral Medium 3', 'DeepSeek V4'],
  ),
  _ProviderConfig(
    name: 'OpenRouter',
    logoPath: SvgPaths.logoOpenRouter,
    models: [
      'openrouter/free',
      'Claude Opus 4.6',
      'GPT-5.4 Pro',
      'Gemini 3.1 Pro Preview',
      'Llama 4 Maverick',
      'Grok 4.1 Fast',
      'DeepSeek V4',
      'Qwen3 Max Thinking',
      'Custom',
    ],
    hasCustomModel: true,
  ),
  _ProviderConfig(
    name: 'Custom',
    logoPath: SvgPaths.logoCustomApi,
    models: ['Custom Model'],
    hasCustomModel: true,
  ),
];

class ApiKeyScreen extends ConsumerStatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  ConsumerState<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends ConsumerState<ApiKeyScreen> {
  final Map<String, TextEditingController> _keyControllers = {};
  final Map<String, TextEditingController> _customModelControllers = {};
  final Map<String, String> _selectedModels = {};
  final Map<String, String> _savedKeyMasks = {};
  int? _expandedIndex;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    for (final p in _providers) {
      _keyControllers[p.name] = TextEditingController();
      _customModelControllers[p.name] = TextEditingController();
      _selectedModels[p.name] = p.models.first;
    }
    _loadSavedKeys();
  }

  Future<void> _loadSavedKeys() async {
    final aiService = AiService.instance;
    for (final p in _providers) {
      final key = await aiService.getApiKey(p.name.toLowerCase());
      if (key != null && key.isNotEmpty) {
        _savedKeyMasks[p.name] = _maskKey(key);
        _keyControllers[p.name]!.text = key;
      }
      final model = await aiService.getSavedModel(p.name.toLowerCase());
      if (model != null && model.isNotEmpty) {
        _selectedModels[p.name] = model;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _maskKey(String key) {
    if (key.length <= 8) return '\u2022' * 8;
    return '${key.substring(0, 4)}${'\u2022' * (key.length - 8).clamp(0, 20)}${key.substring(key.length - 4)}';
  }

  @override
  void dispose() {
    for (final c in _keyControllers.values) {
      c.dispose();
    }
    for (final c in _customModelControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    final aiService = AiService.instance;

    for (final p in _providers) {
      final key = _keyControllers[p.name]!.text.trim();
      if (key.isNotEmpty) {
        await aiService.saveApiKey(p.name.toLowerCase(), key);
        String model = _selectedModels[p.name]!;
        if (model == 'Custom') {
          final custom = _customModelControllers[p.name]!.text.trim();
          if (custom.isNotEmpty) model = custom;
        }
        await aiService.saveModel(p.name.toLowerCase(), model);
      }
    }

    HapticFeedback.mediumImpact();
    if (mounted) context.go('/github-connect');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  GestureDetector(
                    onTap: () => context.go('/github-connect'),
                    child: Text(
                      'Skip',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.accentPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'AI Configuration',
                  style: AppTextStyles.heading1.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      itemCount: _providers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildProviderCard(index, isDark),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: KrivanaButton(
                label: 'Save & Continue',
                onTap: _saveAndContinue,
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderCard(int index, bool isDark) {
    final provider = _providers[index];
    final isExpanded = _expandedIndex == index;
    final hasSaved = _savedKeyMasks.containsKey(provider.name);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _expandedIndex = isExpanded ? null : index);
      },
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: KrivanaSvg(
                        provider.logoPath,
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        autoTheme: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.name,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        if (hasSaved)
                          Text(
                            'Key saved',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (hasSaved)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: provider.models.contains(_selectedModels[provider.name])
                      ? _selectedModels[provider.name]
                      : provider.models.first,
                  decoration: InputDecoration(
                    labelText: 'Model',
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  dropdownColor:
                      isDark ? AppColors.darkCard : AppColors.lightCard,
                  style: AppTextStyles.body.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  items: provider.models
                      .map((m) =>
                          DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedModels[provider.name] = val);
                    }
                  },
                ),
                if (provider.hasCustomModel &&
                    _selectedModels[provider.name] == 'Custom') ...[
                  const SizedBox(height: 12),
                  KrivanaTextField(
                    controller: _customModelControllers[provider.name]!,
                    hint: 'Enter model name (e.g. meta-llama/llama-4-maverick)',
                  ),
                ],
                const SizedBox(height: 12),
                KrivanaTextField(
                  controller: _keyControllers[provider.name]!,
                  hint: hasSaved
                      ? _savedKeyMasks[provider.name]!
                      : 'Enter API key',
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Where to get an API key?',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accentPurple,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
