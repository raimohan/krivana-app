import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/svg_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../presentation/widgets/common/krivana_button.dart';
import '../../../presentation/widgets/common/krivana_text_field.dart';
import '../../../presentation/widgets/glass/glass_container.dart';
import '../../../services/ai/ai_service.dart';

class _ProviderConfig {
  final String name;
  final String logoPath;
  final List<String> models;

  const _ProviderConfig({
    required this.name,
    required this.logoPath,
    required this.models,
  });
}

const _providers = [
  _ProviderConfig(
    name: 'OpenAI',
    logoPath: SvgPaths.logoOpenAI,
    models: ['GPT-4o', 'GPT-4 Turbo'],
  ),
  _ProviderConfig(
    name: 'Anthropic',
    logoPath: SvgPaths.logoAnthropic,
    models: ['Claude 3.5 Sonnet', 'Claude 3 Opus'],
  ),
  _ProviderConfig(
    name: 'Google',
    logoPath: SvgPaths.logoGemini,
    models: ['Gemini 1.5 Pro', 'Gemini Flash'],
  ),
  _ProviderConfig(
    name: 'Groq',
    logoPath: SvgPaths.logoGroq,
    models: ['Llama 3', 'Mixtral'],
  ),
  _ProviderConfig(
    name: 'Together AI',
    logoPath: SvgPaths.logoTogetherAI,
    models: ['Llama 3 70B', 'Mixtral 8x7B'],
  ),
  _ProviderConfig(
    name: 'OpenRouter',
    logoPath: SvgPaths.logoOpenRouter,
    models: ['Auto', 'Custom'],
  ),
  _ProviderConfig(
    name: 'Custom',
    logoPath: SvgPaths.logoCustomApi,
    models: ['Custom Model'],
  ),
];

class ApiKeyScreen extends ConsumerStatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  ConsumerState<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends ConsumerState<ApiKeyScreen> {
  final Map<String, TextEditingController> _keyControllers = {};
  final Map<String, String> _selectedModels = {};
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    for (final p in _providers) {
      _keyControllers[p.name] = TextEditingController();
      _selectedModels[p.name] = p.models.first;
    }
  }

  @override
  void dispose() {
    for (final c in _keyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    final aiService = AiService();

    for (final p in _providers) {
      final key = _keyControllers[p.name]!.text.trim();
      if (key.isNotEmpty) {
        await aiService.saveApiKey(p.name.toLowerCase(), key);
        await aiService.saveModel(
            p.name.toLowerCase(), _selectedModels[p.name]!);
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
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: SvgPicture.asset(SvgPaths.icBack,
                        width: 24, height: 24),
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

            // Title
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

            // Provider cards
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: _providers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final provider = _providers[index];
                  final isExpanded = _expandedIndex == index;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _expandedIndex = isExpanded ? null : index;
                      });
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
                                SvgPicture.asset(provider.logoPath,
                                    width: 32, height: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    provider.name,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ),
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
                              // Model selector
                              DropdownButtonFormField<String>(
                                initialValue: _selectedModels[provider.name],
                                decoration: InputDecoration(
                                  labelText: 'Model',
                                  labelStyle: AppTextStyles.caption,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                dropdownColor: isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightCard,
                                items: provider.models
                                    .map((m) => DropdownMenuItem(
                                        value: m, child: Text(m)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedModels[provider.name] = val;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              // Key input
                              KrivanaTextField(
                                controller: _keyControllers[provider.name]!,
                                hint: 'Enter API key',
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
                },
              ),
            ),

            // Save button
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
}
