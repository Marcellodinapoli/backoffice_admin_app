import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/firebase/ai_usage_monitor_service.dart';

/// Consumi AI (roleplay + valutazione) — allineato a backoffice web.
class AiUsagePage extends StatefulWidget {
  const AiUsagePage({super.key});

  @override
  State<AiUsagePage> createState() => _AiUsagePageState();
}

class _AiUsagePageState extends State<AiUsagePage> {
  static const _ranges = {
    '7g': 7,
    '30g': 30,
    '90g': 90,
  };

  String _selectedRange = '30g';
  AiUsageStats? _stats;
  Object? _error;
  bool _loading = true;

  DateTime get _to => DateTime.now();
  DateTime get _from =>
      _to.subtract(Duration(days: _ranges[_selectedRange] ?? 30));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stats = await AiUsageMonitorService.loadStats(
        from: _from,
        to: _to,
      );
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                      'Consumi AI',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  _load();
                },
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                tooltip: 'Aggiorna',
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorState(error: _error!, onRetry: _load)
                  : _buildContent(_stats!),
        ),
      ],
    );
  }

  Widget _buildContent(AiUsageStats stats) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (stats.truncated)
          Card(
            color: const Color(0xFFFFF3E0),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Mostrati i primi ${stats.scanned} eventi nel periodo '
                '${dateFmt.format(_from)} – ${dateFmt.format(_to)}.',
              ),
            ),
          ),
        const SizedBox(height: 12),
        for (final row in stats.byFeature) ...[
          _TotalsCard(
            title: row.label.isNotEmpty ? row.label : row.key,
            color: _featureColor(row.key),
            icon: _featureIcon(row.key),
            totals: row.totals,
          ),
          const SizedBox(height: 12),
        ],
        _TotalsCard(
          title: 'Totale',
          color: const Color(0xFF2E7D32),
          icon: Icons.auto_awesome_outlined,
          totals: stats.combined,
        ),
        const SizedBox(height: 20),
        _BreakdownSection(
          title: 'Per area (dove)',
          rows: stats.byFeature,
          labelHeader: 'Area',
        ),
        const SizedBox(height: 12),
        _BreakdownSection(
          title: 'Per modello (quale AI)',
          rows: stats.byModel,
          labelHeader: 'Modello',
        ),
        const SizedBox(height: 12),
        _BreakdownSection(
          title: 'Per utente',
          rows: stats.byUser,
          labelHeader: 'Utente',
        ),
        const SizedBox(height: 12),
        _BreakdownSection(
          title: 'Per giorno',
          rows: stats.byDay,
          labelHeader: 'Giorno',
        ),
      ],
    );
  }

  Color _featureColor(String key) => switch (key) {
        'roleplayStep' => const Color(0xFF1565C0),
        'warmupEvaluate' => const Color(0xFF6A1B9A),
        'contestationGenerate' => const Color(0xFFC62828),
        'normativeSearch' => const Color(0xFF00838F),
        'callAnalysis' => const Color(0xFFEF6C00),
        _ => const Color(0xFF455A64),
      };

  IconData _featureIcon(String key) => switch (key) {
        'roleplayStep' => Icons.record_voice_over_outlined,
        'warmupEvaluate' => Icons.psychology_outlined,
        'contestationGenerate' => Icons.gavel_outlined,
        'normativeSearch' => Icons.balance_outlined,
        'callAnalysis' => Icons.phone_in_talk_outlined,
        _ => Icons.auto_awesome_outlined,
      };
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Riprova')),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.title,
    required this.color,
    required this.icon,
    required this.totals,
  });

  final String title;
  final Color color;
  final IconData icon;
  final AiUsageTotals totals;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _metric('Chiamate', _formatInt(totals.calls)),
            _metric('Token input', _formatInt(totals.inputTokens)),
            _metric('Token output', _formatInt(totals.outputTokens)),
            _metric('Token totali', _formatInt(totals.totalTokens)),
            _metric(
              'Costo stimato',
              '\$${totals.estimatedCostUsd.toStringAsFixed(4)}',
            ),
            if (totals.errors > 0) _metric('Errori', totals.errors.toString()),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatInt(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toString();
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({
    required this.title,
    required this.rows,
    required this.labelHeader,
  });

  final String title;
  final List<AiUsageBreakdownRow> rows;
  final String labelHeader;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
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
                    const DataColumn(label: Text('Errori')),
                  ],
                  rows: rows
                      .map(
                        (row) => DataRow(
                          cells: [
                            DataCell(Text(row.label.isNotEmpty
                                ? row.label
                                : row.key)),
                            DataCell(Text(row.totals.calls.toString())),
                            DataCell(Text(_formatInt(row.totals.inputTokens))),
                            DataCell(Text(_formatInt(row.totals.outputTokens))),
                            DataCell(Text(_formatInt(row.totals.totalTokens))),
                            DataCell(Text(
                              row.totals.estimatedCostUsd.toStringAsFixed(4),
                            )),
                            DataCell(Text(row.totals.errors.toString())),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatInt(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toString();
  }
}
