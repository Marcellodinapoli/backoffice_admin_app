import 'roleplay_default_simulation_prompt.dart';

/// Parametri simulazione roleplay (allineati a credit_calc_core).
abstract final class RoleplayConfigService {
  static const collection = 'roleplay';
  static const promptField = 'prompt';
  static const legacyGptPromptField = 'gptPrompt';
  static const aiProviderField = 'aiProvider';
  static const difficultyField = 'difficulty';
  static const personalityField = 'personality';
  static const openAiProvider = 'gpt';

  static const difficulties = [
    'facile',
    'media',
    'difficile',
    'esperto',
  ];

  static const personalities = [
    'collaborativo',
    'diffidente',
    'aggressivo',
    'manipolatore',
    'emotivo',
    'razionale',
  ];

  static const defaultDifficulty = 'media';
  static const defaultPersonality = 'collaborativo';

  static const defaultSimulationPrompt = RoleplayDefaultSimulationPrompt.text;

  static String resolveDifficulty(Map<String, dynamic> data) {
    final raw = (data[difficultyField] ?? '').toString().trim().toLowerCase();
    return difficulties.contains(raw) ? raw : defaultDifficulty;
  }

  static String resolvePersonality(Map<String, dynamic> data) {
    final raw = (data[personalityField] ?? '').toString().trim().toLowerCase();
    return personalities.contains(raw) ? raw : defaultPersonality;
  }

  static String difficultyLabel(String value) {
    return switch (value) {
      'facile' => 'Facile',
      'difficile' => 'Difficile',
      'esperto' => 'Esperto',
      _ => 'Media',
    };
  }

  static String personalityLabel(String value) {
    return switch (value) {
      'collaborativo' => 'Collaborativo',
      'diffidente' => 'Diffidente',
      'aggressivo' => 'Aggressivo',
      'manipolatore' => 'Manipolatore',
      'emotivo' => 'Emotivo',
      'razionale' => 'Razionale',
      _ => 'Collaborativo',
    };
  }

  static String resolveSimulationPrompt(Map<String, dynamic> data) {
    final prompt = (data[promptField] ?? '').toString().trim();
    if (prompt.isNotEmpty) return prompt;
    final legacyGpt =
        (data[legacyGptPromptField] ?? '').toString().trim();
    if (legacyGpt.isNotEmpty) return legacyGpt;
    return defaultSimulationPrompt;
  }

  static String resolveStoredSimulationPrompt(Map<String, dynamic> data) {
    final prompt = (data[promptField] ?? '').toString().trim();
    if (prompt.isNotEmpty) return prompt;
    return (data[legacyGptPromptField] ?? '').toString().trim();
  }
}
