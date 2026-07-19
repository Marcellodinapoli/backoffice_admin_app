import 'callable_function_client.dart';

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

Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return null;
}

class AiUsageTotals {
  const AiUsageTotals({
    this.calls = 0,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.totalTokens = 0,
    this.estimatedCostUsd = 0,
    this.errors = 0,
  });

  final int calls;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final double estimatedCostUsd;
  final int errors;

  factory AiUsageTotals.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const AiUsageTotals();
    return AiUsageTotals(
      calls: _asInt(data['calls']),
      inputTokens: _asInt(data['inputTokens']),
      outputTokens: _asInt(data['outputTokens']),
      totalTokens: _asInt(data['totalTokens']),
      estimatedCostUsd: _asDouble(data['estimatedCostUsd']),
      errors: _asInt(data['errors']),
    );
  }

  AiUsageTotals operator +(AiUsageTotals other) => AiUsageTotals(
        calls: calls + other.calls,
        inputTokens: inputTokens + other.inputTokens,
        outputTokens: outputTokens + other.outputTokens,
        totalTokens: totalTokens + other.totalTokens,
        estimatedCostUsd: estimatedCostUsd + other.estimatedCostUsd,
        errors: errors + other.errors,
      );
}

class AiUsageBreakdownRow {
  const AiUsageBreakdownRow({
    required this.key,
    required this.label,
    required this.totals,
  });

  final String key;
  final String label;
  final AiUsageTotals totals;

  factory AiUsageBreakdownRow.fromMap(Map<String, dynamic> data) {
    return AiUsageBreakdownRow(
      key: (data['key'] ?? '').toString(),
      label: (data['label'] ?? '').toString(),
      totals: AiUsageTotals(
        calls: _asInt(data['calls']),
        inputTokens: _asInt(data['inputTokens']),
        outputTokens: _asInt(data['outputTokens']),
        totalTokens: _asInt(data['totalTokens']),
        estimatedCostUsd: _asDouble(data['estimatedCostUsd']),
        errors: _asInt(data['errors']),
      ),
    );
  }
}

class AiUsageStats {
  const AiUsageStats({
    required this.fromMs,
    required this.toMs,
    required this.scanned,
    required this.truncated,
    required this.roleplay,
    required this.evaluation,
    required this.byFeature,
    required this.byUser,
    required this.byDay,
    required this.byModel,
  });

  final int fromMs;
  final int toMs;
  final int scanned;
  final bool truncated;
  final AiUsageTotals roleplay;
  final AiUsageTotals evaluation;
  final List<AiUsageBreakdownRow> byFeature;
  final List<AiUsageBreakdownRow> byUser;
  final List<AiUsageBreakdownRow> byDay;
  final List<AiUsageBreakdownRow> byModel;

  AiUsageTotals get combined {
    if (byFeature.isNotEmpty) {
      return byFeature.fold(const AiUsageTotals(), (acc, row) => acc + row.totals);
    }
    return roleplay + evaluation;
  }

  factory AiUsageStats.fromMap(Map<String, dynamic> data) {
    List<AiUsageBreakdownRow> rows(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((item) => AiUsageBreakdownRow.fromMap(
                Map<String, dynamic>.from(item),
              ))
          .toList();
    }

    return AiUsageStats(
      fromMs: _asInt(data['fromMs']),
      toMs: _asInt(data['toMs']),
      scanned: _asInt(data['scanned']),
      truncated: data['truncated'] == true,
      roleplay: AiUsageTotals.fromMap(_asStringKeyedMap(data['roleplay'])),
      evaluation: AiUsageTotals.fromMap(_asStringKeyedMap(data['evaluation'])),
      byFeature: rows(data['byFeature']),
      byUser: rows(data['byUser']),
      byDay: rows(data['byDay']),
      byModel: rows(data['byModel']),
    );
  }
}

abstract final class AiUsageMonitorService {
  static Future<AiUsageStats> loadStats({
    required DateTime from,
    required DateTime to,
  }) async {
    final raw = await CallableFunctionClient.call('getAiUsageStats', {
      'fromMs': from.millisecondsSinceEpoch,
      'toMs': to.millisecondsSinceEpoch,
    });

    final map = _asStringKeyedMap(raw);
    if (map == null) {
      throw Exception('Risposta getAiUsageStats non valida.');
    }

    return AiUsageStats.fromMap(map);
  }
}
