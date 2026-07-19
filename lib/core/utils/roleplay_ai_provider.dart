import 'package:flutter/material.dart';

/// Motore AI roleplay (allineato a backoffice web / CreditCore).
abstract final class RoleplayAiProvider {
  static const openAi = 'gpt';
  static const realtime = 'realtime';
  static const _legacyGptAlias = 'hetzner';

  static const defaultProvider = realtime;

  static String read(Map<String, dynamic> data) {
    final raw = data['aiProvider'];
    if (raw == null || raw.toString().trim().isEmpty) {
      return defaultProvider;
    }
    return readValue(raw.toString());
  }

  static String label(String provider) {
    return switch (readValue(provider)) {
      realtime => 'OpenAI Realtime',
      _ => 'OpenAI GPT',
    };
  }

  static String readValue(String? provider) {
    if (provider == null || provider.trim().isEmpty) {
      return defaultProvider;
    }
    final value = provider.toLowerCase().trim();
    return switch (value) {
      openAi => openAi,
      _legacyGptAlias => openAi,
      realtime => realtime,
      _ => defaultProvider,
    };
  }

  static String readPrompt(Map<String, dynamic> data, [String? provider]) {
    final prompt = (data['prompt'] ?? '').toString().trim();
    if (prompt.isNotEmpty) return prompt;
    return (data['gptPrompt'] ?? '').toString();
  }

  static String promptFirestoreField(String provider) => 'prompt';

  static String promptFieldLabel(String provider) => 'Prompt OpenAI';

  static Widget engineDropdown({
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final normalized = readValue(value);
    return DropdownButtonFormField<String>(
      value: normalized,
      decoration: const InputDecoration(
        labelText: 'Motore AI',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: realtime,
          child: Text('OpenAI Realtime (voce)'),
        ),
        DropdownMenuItem(
          value: openAi,
          child: Text('OpenAI GPT (STT/TTS locale)'),
        ),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }

  static Widget promptEditor({
    required String aiProvider,
    required TextEditingController hetznerPrompt,
    required TextEditingController gptPrompt,
  }) {
    return TextField(
      controller: hetznerPrompt,
      minLines: 14,
      maxLines: 28,
      decoration: InputDecoration(
        labelText: promptFieldLabel(aiProvider),
        hintText: 'Istruzioni per il debitore simulato',
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }
}
