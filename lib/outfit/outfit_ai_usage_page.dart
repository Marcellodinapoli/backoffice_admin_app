import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import 'outfit_firebase.dart';
import 'outfit_pages.dart';

class _OutfitFeatureMeta {
  const _OutfitFeatureMeta(
    this.key,
    this.label,
    this.model,
    this.icon,
    this.color,
  );
  final String key;
  final String label;
  final String model;
  final IconData icon;
  final Color color;
}

const _features = <_OutfitFeatureMeta>[
  _OutfitFeatureMeta(
    'visionAnalyze',
    'Vision guardaroba',
    'gpt-5.5',
    Icons.image_search_outlined,
    Color(0xFF00838F),
  ),
  _OutfitFeatureMeta(
    'outfitGeneration',
    'Generazione outfit',
    'gpt-5.5',
    Icons.checkroom_outlined,
    Color(0xFF1565C0),
  ),
  _OutfitFeatureMeta(
    'outfitCopy',
    'Copy outfit',
    'gpt-5.5',
    Icons.edit_note_outlined,
    Color(0xFF6A1B9A),
  ),
];

class _Totals {
  const _Totals({
    this.calls = 0,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.estimatedCostUsd = 0,
  });

  final int calls;
  final int inputTokens;
  final int outputTokens;
  final double estimatedCostUsd;

  int get totalTokens => inputTokens + outputTokens;

  _Totals operator +(_Totals other) => _Totals(
        calls: calls + other.calls,
        inputTokens: inputTokens + other.inputTokens,
        outputTokens: outputTokens + other.outputTokens,
        estimatedCostUsd: estimatedCostUsd + other.estimatedCostUsd,
      );
}

int _asInt(dynamic v) {
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? 0;
}

double _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

_Totals _featureFromDoc(Map<String, dynamic> data, String feature) {
  final nested = data['features'];
  if (nested is Map && nested[feature] is Map) {
    final row = Map<String, dynamic>.from(nested[feature] as Map);
    return _Totals(
      calls: _asInt(row['calls']),
      inputTokens: _asInt(row['inputTokens']),
      outputTokens: _asInt(row['outputTokens']),
    );
  }
  return _Totals(
    calls: _asInt(data['features.$feature.calls']),
    inputTokens: _asInt(data['features.$feature.inputTokens']),
    outputTokens: _asInt(data['features.$feature.outputTokens']),
  );
}

double _monthEur(Map<String, dynamic> data) {
  final nested = data['totals'];
  if (nested is Map) {
    final eur = _asDouble(nested['estimatedEur']);
    if (eur > 0) return eur;
  }
  return _asDouble(data['totals.estimatedEur']);
}

class OutfitAiUsagePage extends StatefulWidget {
  const OutfitAiUsagePage({super.key});

  @override
  State<OutfitAiUsagePage> createState() => _OutfitAiUsagePageState();
}

class _OutfitAiUsagePageState extends State<OutfitAiUsagePage> {
  static const _ranges = {'7g': 7, '30g': 30, '90g': 90};
  String _selectedRange = '30g';

  DateTime get _to => DateTime.now();
  DateTime get _from =>
      _to.subtract(Duration(days: _ranges[_selectedRange] ?? 30));

  List<String> get _monthKeys {
    final keys = <String>[];
    var cursor = DateTime.utc(_from.year, _from.month, 1);
    final end = DateTime.utc(_to.year, _to.month, 1);
    while (!cursor.isAfter(end)) {
      keys.add(
        '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}',
      );
      cursor = DateTime.utc(cursor.year, cursor.month + 1, 1);
    }
    return keys;
  }

  Future<Map<_OutfitFeatureMeta, _Totals>> _load(FirebaseFirestore db) async {
    final result = <_OutfitFeatureMeta, _Totals>{
      for (final f in _features) f: const _Totals(),
    };

    for (final key in _monthKeys) {
      final snap = await db
          .collection('settings')
          .doc('ai_usage')
          .collection('months')
          .doc(key)
          .get();
      if (!snap.exists) continue;
      final data = snap.data() ?? {};
      final monthEur = _monthEur(data);
      final monthUsd = monthEur / 0.92;

      final perFeature = <_OutfitFeatureMeta, _Totals>{};
      var tokenSum = 0;
      for (final f in _features) {
        final totals = _featureFromDoc(data, f.key);
        if (totals.calls <= 0 && totals.totalTokens <= 0) continue;
        perFeature[f] = totals;
        tokenSum += totals.totalTokens;
      }

      final nested = data['totals'];
      final nestedSum = nested is Map
          ? _asInt(nested['inputTokens']) + _asInt(nested['outputTokens'])
          : 0;
      final flatSum = _asInt(data['totals.inputTokens']) +
          _asInt(data['totals.outputTokens']);
      final denom = nestedSum > 0
          ? nestedSum
          : (flatSum > 0 ? flatSum : (tokenSum > 0 ? tokenSum : 1));

      for (final entry in perFeature.entries) {
        final withCost = _Totals(
          calls: entry.value.calls,
          inputTokens: entry.value.inputTokens,
          outputTokens: entry.value.outputTokens,
          estimatedCostUsd: monthUsd > 0
              ? monthUsd * (entry.value.totalTokens / denom)
              : 0,
        );
        result[entry.key] = result[entry.key]! + withCost;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return OutfitAvailability(
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Consumi AI Outfit',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Per area e modello OpenAI',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedRange,
                    items: const [
                      DropdownMenuItem(value: '7g', child: Text('7 giorni')),
                      DropdownMenuItem(value: '30g', child: Text('30 giorni')),
                      DropdownMenuItem(value: '90g', child: Text('90 giorni')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedRange = value);
                    },
                  ),
                  IconButton(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final db = OutfitFirebase.firestore;
                  if (db == null) {
                    return const Center(child: Text('Firestore Outfit non disponibile.'));
                  }
                  return FutureBuilder<Map<_OutfitFeatureMeta, _Totals>>(
                    future: _load(db),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return Center(child: Text('${snap.error}'));
                      }
                      return _buildContent(snap.data ?? {});
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Map<_OutfitFeatureMeta, _Totals> data) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final combined = data.values.fold(const _Totals(), (a, b) => a + b);
    final byModel = <String, _Totals>{};
    for (final entry in data.entries) {
      byModel[entry.key.model] =
          (byModel[entry.key.model] ?? const _Totals()) + entry.value;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Periodo ${dateFmt.format(_from)} – ${dateFmt.format(_to)}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        if (combined.calls == 0)
          const Card(
            color: Color(0xFFFFF8E1),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Nessun consumo registrato nel periodo. '
                'I dati partono dalle chiamate OpenAI successive '
                'al tracking (Vision, Generazione, Copy).',
              ),
            ),
          ),
        const SizedBox(height: 12),
        for (final f in _features) ...[
          _TotalsCard(
            title: f.label,
            subtitle: f.model,
            color: f.color,
            icon: f.icon,
            totals: data[f] ?? const _Totals(),
          ),
          const SizedBox(height: 12),
        ],
        _TotalsCard(
          title: 'Totale',
          subtitle: 'Tutte le aree',
          color: const Color(0xFF2E7D32),
          icon: Icons.auto_awesome_outlined,
          totals: combined,
        ),
        const SizedBox(height: 20),
        _TableCard(
          title: 'Per area (dove)',
          labelHeader: 'Area',
          rows: [
            for (final f in _features) (f.label, data[f] ?? const _Totals()),
          ],
        ),
        const SizedBox(height: 12),
        _TableCard(
          title: 'Per modello (quale AI)',
          labelHeader: 'Modello',
          rows: [
            for (final e in byModel.entries) (e.key, e.value),
          ],
        ),
      ],
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.totals,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final _Totals totals;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _row('Chiamate', '${totals.calls}'),
            _row('Token input', _fmt(totals.inputTokens)),
            _row('Token output', _fmt(totals.outputTokens)),
            _row('Token totali', _fmt(totals.totalTokens)),
            _row(
              'Costo stimato',
              '\$${totals.estimatedCostUsd.toStringAsFixed(4)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return '$v';
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.title,
    required this.labelHeader,
    required this.rows,
  });

  final String title;
  final String labelHeader;
  final List<(String, _Totals)> rows;

  @override
  Widget build(BuildContext context) {
    final hasData = rows.any((r) => r.$2.calls > 0);
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (!hasData)
              const Text('Nessun dato nel periodo selezionato.')
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(labelHeader)),
                    const DataColumn(label: Text('Chiamate')),
                    const DataColumn(label: Text('Input')),
                    const DataColumn(label: Text('Output')),
                    const DataColumn(label: Text('Totali')),
                    const DataColumn(label: Text('USD')),
                  ],
                  rows: [
                    for (final row in rows)
                      if (row.$2.calls > 0 || row.$2.totalTokens > 0)
                        DataRow(
                          cells: [
                            DataCell(Text(row.$1)),
                            DataCell(Text('${row.$2.calls}')),
                            DataCell(Text('${row.$2.inputTokens}')),
                            DataCell(Text('${row.$2.outputTokens}')),
                            DataCell(Text('${row.$2.totalTokens}')),
                            DataCell(Text(
                              row.$2.estimatedCostUsd.toStringAsFixed(4),
                            )),
                          ],
                        ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
