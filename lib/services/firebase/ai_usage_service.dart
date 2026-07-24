import 'package:cloud_firestore/cloud_firestore.dart';

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

class AiFeatureUsage {
  const AiFeatureUsage({
    this.calls = 0,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.whisperSeconds = 0,
  });

  final int calls;
  final int inputTokens;
  final int outputTokens;
  final int whisperSeconds;

  int get totalTokens => inputTokens + outputTokens;

  factory AiFeatureUsage.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const AiFeatureUsage();
    return AiFeatureUsage(
      calls: _asInt(data['calls']),
      inputTokens: _asInt(data['inputTokens']),
      outputTokens: _asInt(data['outputTokens']),
      whisperSeconds: _asInt(data['whisperSeconds']),
    );
  }
}

class AiMonthUsage {
  const AiMonthUsage({
    this.features = const {},
    this.totalCalls = 0,
    this.totalInputTokens = 0,
    this.totalOutputTokens = 0,
    this.totalWhisperSeconds = 0,
    this.estimatedEur = 0,
    this.updatedAt,
  });

  final Map<String, AiFeatureUsage> features;
  final int totalCalls;
  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalWhisperSeconds;
  final double estimatedEur;
  final DateTime? updatedAt;

  int get totalTokens => totalInputTokens + totalOutputTokens;

  static const featureOrder = [
    'normativeSearch',
    'callAnalysis',
    'roleplayStep',
    'roleplaySuggestion',
    'roleplayRealtime',
    'warmupEvaluate',
    'contestationGenerate',
  ];

  static const featureLabels = {
    'normativeSearch': 'Ricerca normativa',
    'callAnalysis': 'Analisi telefonata',
    'roleplayStep': 'Role play',
    'roleplaySuggestion': 'Role play · suggerimenti',
    'roleplayRealtime': 'Role play Realtime (voce)',
    'warmupEvaluate': 'Warm-up',
    'contestationGenerate': 'Contestazioni',
  };

  factory AiMonthUsage.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const AiMonthUsage();

    final rawFeatures = data['features'] as Map<String, dynamic>? ?? {};
    final features = <String, AiFeatureUsage>{};
    for (final entry in rawFeatures.entries) {
      features[entry.key] = AiFeatureUsage.fromMap(
        entry.value is Map<String, dynamic>
            ? entry.value as Map<String, dynamic>
            : Map<String, dynamic>.from(entry.value as Map),
      );
    }

    final totals = data['totals'] as Map<String, dynamic>? ?? {};
    final updatedAtRaw = data['updatedAt'];
    DateTime? updatedAt;
    if (updatedAtRaw is Timestamp) {
      updatedAt = updatedAtRaw.toDate();
    }

    return AiMonthUsage(
      features: features,
      totalCalls: _asInt(totals['calls']),
      totalInputTokens: _asInt(totals['inputTokens']),
      totalOutputTokens: _asInt(totals['outputTokens']),
      totalWhisperSeconds: _asInt(totals['whisperSeconds']),
      estimatedEur: _asDouble(totals['estimatedEur']),
      updatedAt: updatedAt,
    );
  }
}

abstract final class AiUsageService {
  static DocumentReference<Map<String, dynamic>> _monthRef(String monthKey) {
    return FirebaseFirestore.instance
        .collection('settings')
        .doc('ai_usage')
        .collection('months')
        .doc(monthKey);
  }

  static Stream<AiMonthUsage> watchMonth(String monthKey) {
    return _monthRef(monthKey).snapshots().map(
          (snap) => AiMonthUsage.fromMap(snap.data()),
        );
  }
}
