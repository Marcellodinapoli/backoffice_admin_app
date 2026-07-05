import 'package:flutter/material.dart';

/// Motore AI roleplay: solo OpenAI (Cloud Function `roleplayStep`).
abstract final class RoleplayAiProvider {
  static const openAi = 'gpt';

  static String read(Map<String, dynamic> data) => openAi;

  static String label(String provider) => 'OpenAI';

  static String readPrompt(Map<String, dynamic> data, [String? provider]) {
    final prompt = (data['prompt'] ?? '').toString().trim();
    if (prompt.isNotEmpty) return prompt;
    return (data['gptPrompt'] ?? '').toString();
  }

  static String promptFirestoreField(String provider) => 'prompt';

  static String promptFieldLabel(String provider) => 'Prompt OpenAI';

  static Widget promptEditor({
    required String aiProvider,
    required TextEditingController hetznerPrompt,
    required TextEditingController gptPrompt,
  }) {
    return TextField(
      controller: hetznerPrompt,
      maxLines: 8,
      decoration: const InputDecoration(
        labelText: 'Prompt OpenAI',
        hintText: 'Istruzioni per il debitore simulato',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }
}
