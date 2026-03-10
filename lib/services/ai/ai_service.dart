import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/logger.dart';
import '../storage/secure_storage_service.dart';

class AiService {
  AiService._();
  static final instance = AiService._();

  String? _activeProvider;
  String? _activeModel;

  String? get activeProvider => _activeProvider;
  String? get activeModel => _activeModel;

  Future<void> loadConfig() async {
    final storage = SecureStorageService.instance;
    _activeProvider = await storage.read('ai_provider');
    _activeModel = await storage.read('ai_model');
  }

  Future<void> setProvider(String provider, String model) async {
    _activeProvider = provider;
    _activeModel = model;
    final storage = SecureStorageService.instance;
    await storage.write('ai_provider', provider);
    await storage.write('ai_model', model);
  }

  Future<void> saveApiKey(String provider, String key) async {
    await SecureStorageService.instance.write('api_key_$provider', key);
    AppLogger.info('API key saved for $provider');
  }

  Future<String?> getApiKey(String provider) async {
    return SecureStorageService.instance.read('api_key_$provider');
  }

  Future<void> saveModel(String provider, String model) async {
    await SecureStorageService.instance.write('ai_model_$provider', model);
    AppLogger.info('Model saved for $provider: $model');
  }

  Future<String?> getSavedModel(String provider) async {
    return SecureStorageService.instance.read('ai_model_$provider');
  }

  /// Get model list for a provider that has a saved API key
  Future<List<String>> getAvailableModels(String provider) async {
    final key = await getApiKey(provider);
    if (key == null || key.isEmpty) return [];

    return switch (provider) {
      'openai' => ['GPT-5.4 Pro', 'GPT-5.4 Thinking', 'GPT-5.3 Instant', 'GPT-5.2'],
      'anthropic' => ['Claude Opus 4.6', 'Claude Sonnet 4.6', 'Claude Haiku 4.5', 'Claude Opus 4.5'],
      'google' => ['Gemini 3.1 Pro Preview', 'Gemini 3.1 Flash-Lite', 'Gemini 3 Deep Think'],
      'groq' => ['Llama 4 Maverick', 'DeepSeek V4', 'Qwen3 Max Thinking'],
      'together ai' => ['Llama 4 Maverick', 'Mistral Medium 3', 'DeepSeek V4'],
      'openrouter' => [
        'openrouter/free',
        'Claude Opus 4.6',
        'GPT-5.4 Pro',
        'Gemini 3.1 Pro Preview',
        'Llama 4 Maverick',
        'Grok 4.1 Fast',
        'DeepSeek V4',
        'Qwen3 Max Thinking',
      ],
      _ => ['Custom Model'],
    };
  }

  /// Send a message and get AI response
  Future<String> sendMessage(
    List<Map<String, String>> messages, {
    String? provider,
    String? model,
  }) async {
    final usedProvider = provider ?? _activeProvider;
    final usedModel = model ?? _activeModel;

    if (usedProvider == null || usedModel == null) {
      throw Exception('No AI provider configured');
    }

    final apiKey = await getApiKey(usedProvider);
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('No API key for $usedProvider');
    }

    try {
      return await _callApi(usedProvider, usedModel, apiKey, messages);
    } catch (e) {
      AppLogger.error('AI API call failed: $e');
      rethrow;
    }
  }

  Future<String> _callApi(
    String provider,
    String model,
    String apiKey,
    List<Map<String, String>> messages,
  ) async {
    late final Uri url;
    late final Map<String, String> headers;
    late final Map<String, dynamic> body;

    switch (provider) {
      case 'openai':
        url = Uri.parse('https://api.openai.com/v1/chat/completions');
        headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
        body = {
          'model': _resolveModelId(provider, model),
          'messages': messages,
        };
      case 'anthropic':
        url = Uri.parse('https://api.anthropic.com/v1/messages');
        headers = {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        };
        // Convert messages format for Anthropic
        final systemMsg = messages.where((m) => m['role'] == 'system').map((m) => m['content']).join('\n');
        final chatMsgs = messages.where((m) => m['role'] != 'system').toList();
        body = {
          'model': _resolveModelId(provider, model),
          'max_tokens': 4096,
          'messages': chatMsgs,
          if (systemMsg.isNotEmpty) 'system': systemMsg,
        };
      case 'google':
        final modelId = _resolveModelId(provider, model);
        url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$modelId:generateContent?key=$apiKey');
        headers = {'Content-Type': 'application/json'};
        body = {
          'contents': messages.map((m) => {
            'role': m['role'] == 'assistant' ? 'model' : 'user',
            'parts': [{'text': m['content']}],
          }).toList(),
        };
      case 'openrouter':
        url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
        headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://krivana.dev',
          'X-Title': 'Krivana',
        };
        body = {
          'model': _resolveModelId(provider, model),
          'messages': messages,
        };
      default:
        // Groq, Together AI, Custom - use OpenAI-compatible format
        final baseUrl = _getBaseUrl(provider);
        url = Uri.parse('$baseUrl/chat/completions');
        headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
        body = {
          'model': _resolveModelId(provider, model),
          'messages': messages,
        };
    }

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('API error (${response.statusCode}): ${response.body}');
    }

    final json = jsonDecode(response.body);
    return _extractContent(provider, json);
  }

  String _resolveModelId(String provider, String model) {
    return switch (provider) {
      'openai' => switch (model) {
        'GPT-5.4 Pro' => 'gpt-5.4-pro',
        'GPT-5.4 Thinking' => 'gpt-5.4-thinking',
        'GPT-5.3 Instant' => 'gpt-5.3-instant',
        'GPT-5.2' => 'gpt-5.2',
        _ => model.toLowerCase().replaceAll(' ', '-'),
      },
      'anthropic' => switch (model) {
        'Claude Opus 4.6' => 'claude-opus-4-6',
        'Claude Sonnet 4.6' => 'claude-sonnet-4-6',
        'Claude Haiku 4.5' => 'claude-haiku-4-5',
        'Claude Opus 4.5' => 'claude-opus-4-5-20251101',
        _ => model.toLowerCase().replaceAll(' ', '-'),
      },
      'google' => switch (model) {
        'Gemini 3.1 Pro Preview' => 'gemini-3.1-pro-preview',
        'Gemini 3.1 Flash-Lite' => 'gemini-3.1-flash-lite',
        'Gemini 3 Deep Think' => 'gemini-3-deep-think',
        _ => model.toLowerCase().replaceAll(' ', '-'),
      },
      'openrouter' => switch (model) {
        'openrouter/free' => 'openrouter/auto',
        _ => model.toLowerCase().replaceAll(' ', '-'),
      },
      _ => model.toLowerCase().replaceAll(' ', '-'),
    };
  }

  String _getBaseUrl(String provider) {
    return switch (provider) {
      'groq' => 'https://api.groq.com/openai/v1',
      'together ai' => 'https://api.together.xyz/v1',
      _ => 'https://api.openai.com/v1', // fallback for custom
    };
  }

  String _extractContent(String provider, Map<String, dynamic> json) {
    switch (provider) {
      case 'anthropic':
        final content = json['content'] as List?;
        if (content != null && content.isNotEmpty) {
          return content.first['text'] as String? ?? 'No response';
        }
        return 'No response';
      case 'google':
        final candidates = json['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates.first['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts.first['text'] as String? ?? 'No response';
          }
        }
        return 'No response';
      default:
        // OpenAI-compatible format (OpenAI, Groq, Together, OpenRouter)
        final choices = json['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          return choices.first['message']?['content'] as String? ?? 'No response';
        }
        return 'No response';
    }
  }
}
