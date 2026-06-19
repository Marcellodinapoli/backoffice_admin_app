import '../core/utils/roleplay_ai_provider.dart';

class RoleplaySimulation {
  final String id;
  final String title;
  final String category;
  final String prompt;
  final String gptPrompt;
  final String? audioUrl;
  final List<Map<String, dynamic>> practiceData;
  final String date;
  final String aiProvider;

  const RoleplaySimulation({
    required this.id,
    required this.title,
    required this.category,
    required this.prompt,
    this.gptPrompt = '',
    this.audioUrl,
    this.practiceData = const [],
    required this.date,
    this.aiProvider = RoleplayAiProvider.hetzner,
  });

  factory RoleplaySimulation.fromFirestore(String id, Map<String, dynamic> data) {
    final practice = (data['practiceData'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    return RoleplaySimulation(
      id: id,
      title: data['title']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Sollecito',
      prompt: data['prompt']?.toString() ?? '',
      gptPrompt: data['gptPrompt']?.toString() ?? '',
      audioUrl: data['audioUrl']?.toString(),
      practiceData: practice,
      date: data['date']?.toString() ?? '',
      aiProvider: RoleplayAiProvider.read(data),
    );
  }
}
