import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/firebase/platform_costs_service.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/section_header.dart';

class BkCostsPage extends StatefulWidget {
  const BkCostsPage({super.key});

  @override
  State<BkCostsPage> createState() => _BkCostsPageState();
}

class _BkCostsPageState extends State<BkCostsPage> {
  late String _selectedMonthKey;

  @override
  void initState() {
    super.initState();
    _selectedMonthKey = PlatformCostsService.recentMonthKeys().first;
  }

  Future<void> _editPlatform(
    PlatformMonthCosts costs,
    _PlatformCostKind kind,
  ) async {
    final result = await showDialog<PlatformMonthCosts>(
      context: context,
      builder: (_) => _PlatformCostEditDialog(kind: kind, initial: costs),
    );
    if (result == null) return;

    await PlatformCostsService.saveMonth(_selectedMonthKey, result);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Costi aggiornati')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Costi',
          subtitle: 'Monitoraggio Bunny.net, Hetzner, OpenAI, Firebase',
          trailing: DropdownButton<String>(
            value: _selectedMonthKey,
            underline: const SizedBox.shrink(),
            items: PlatformCostsService.recentMonthKeys()
                .map(
                  (key) => DropdownMenuItem(
                    value: key,
                    child: Text(PlatformCostsService.monthLabel(key)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedMonthKey = value);
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<PlatformMonthCosts>(
            stream: PlatformCostsService.watchMonth(_selectedMonthKey),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LoadingView();
              }

              final costs = snapshot.data ?? const PlatformMonthCosts();
              final total = costs.total();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  Card(
                    color: AppColors.infoBg,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Totale mese',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '€${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PlatformCostCard(
                    title: 'Bunny.net',
                    icon: Icons.cloud_outlined,
                    color: const Color(0xFFFF6F00),
                    usage:
                        'Storage: ${costs.bunnyStorageGb.toStringAsFixed(1)} GB · '
                        'Traffico: ${costs.bunnyTrafficGb.toStringAsFixed(1)} GB',
                    amount: costs.costBunny(),
                    onEdit: () => _editPlatform(costs, _PlatformCostKind.bunny),
                  ),
                  _PlatformCostCard(
                    title: 'Hetzner',
                    icon: Icons.dns_outlined,
                    color: const Color(0xFFD32F2F),
                    usage:
                        'Abbonamento €${costs.hetznerMonthlyEur.toStringAsFixed(2)}/mese',
                    amount: costs.costHetzner(),
                    onEdit: () => _editPlatform(costs, _PlatformCostKind.hetzner),
                  ),
                  _PlatformCostCard(
                    title: 'OpenAI API',
                    icon: Icons.auto_awesome_outlined,
                    color: const Color(0xFF2E7D32),
                    usage: 'Importo da dashboard OpenAI',
                    amount: costs.costOpenAi(),
                    onEdit: () => _editPlatform(costs, _PlatformCostKind.openai),
                  ),
                  _PlatformCostCard(
                    title: 'Firebase',
                    icon: Icons.local_fire_department_outlined,
                    color: const Color(0xFFFF9800),
                    usage:
                        'Letture: ${_formatInt(costs.firebaseReads)} · '
                        'Scritture: ${_formatInt(costs.firebaseWrites)} · '
                        'Storage: ${(costs.firebaseStorageMb / 1024).toStringAsFixed(2)} GB',
                    amount: costs.costFirebase(),
                    onEdit: () => _editPlatform(costs, _PlatformCostKind.firebase),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatInt(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toString();
  }
}

enum _PlatformCostKind { bunny, hetzner, openai, firebase }

class _PlatformCostCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String usage;
  final double amount;
  final VoidCallback onEdit;

  const _PlatformCostCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.usage,
    required this.amount,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(usage, style: const TextStyle(fontSize: 12, height: 1.35)),
              const SizedBox(height: 6),
              Text(
                '€${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _PlatformCostEditDialog extends StatefulWidget {
  final _PlatformCostKind kind;
  final PlatformMonthCosts initial;

  const _PlatformCostEditDialog({
    required this.kind,
    required this.initial,
  });

  @override
  State<_PlatformCostEditDialog> createState() =>
      _PlatformCostEditDialogState();
}

class _PlatformCostEditDialogState extends State<_PlatformCostEditDialog> {
  late final TextEditingController _c1;
  late final TextEditingController _c2;
  late final TextEditingController _c3;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    switch (widget.kind) {
      case _PlatformCostKind.bunny:
        _c1 = TextEditingController(text: c.bunnyStorageGb.toString());
        _c2 = TextEditingController(text: c.bunnyTrafficGb.toString());
        _c3 = TextEditingController();
      case _PlatformCostKind.hetzner:
        _c1 = TextEditingController(text: c.hetznerMonthlyEur.toString());
        _c2 = TextEditingController();
        _c3 = TextEditingController();
      case _PlatformCostKind.openai:
        _c1 = TextEditingController(text: c.openAiAmountEur.toString());
        _c2 = TextEditingController();
        _c3 = TextEditingController();
      case _PlatformCostKind.firebase:
        _c1 = TextEditingController(text: c.firebaseReads.toString());
        _c2 = TextEditingController(text: c.firebaseWrites.toString());
        _c3 = TextEditingController(text: c.firebaseStorageMb.toString());
    }
  }

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    _c3.dispose();
    super.dispose();
  }

  double _parseDouble(String raw, {double fallback = 0}) {
    return double.tryParse(raw.replaceAll(',', '.')) ?? fallback;
  }

  int _parseInt(String raw) => int.tryParse(raw.trim()) ?? 0;

  PlatformMonthCosts _buildResult() {
    final c = widget.initial;
    switch (widget.kind) {
      case _PlatformCostKind.bunny:
        return PlatformMonthCosts(
          bunnyStorageGb: _parseDouble(_c1.text),
          bunnyTrafficGb: _parseDouble(_c2.text),
          hetznerMonthlyEur: c.hetznerMonthlyEur,
          openAiAmountEur: c.openAiAmountEur,
          firebaseReads: c.firebaseReads,
          firebaseWrites: c.firebaseWrites,
          firebaseStorageMb: c.firebaseStorageMb,
        );
      case _PlatformCostKind.hetzner:
        return PlatformMonthCosts(
          bunnyStorageGb: c.bunnyStorageGb,
          bunnyTrafficGb: c.bunnyTrafficGb,
          hetznerMonthlyEur: _parseDouble(_c1.text, fallback: 17),
          openAiAmountEur: c.openAiAmountEur,
          firebaseReads: c.firebaseReads,
          firebaseWrites: c.firebaseWrites,
          firebaseStorageMb: c.firebaseStorageMb,
        );
      case _PlatformCostKind.openai:
        return PlatformMonthCosts(
          bunnyStorageGb: c.bunnyStorageGb,
          bunnyTrafficGb: c.bunnyTrafficGb,
          hetznerMonthlyEur: c.hetznerMonthlyEur,
          openAiAmountEur: _parseDouble(_c1.text),
          firebaseReads: c.firebaseReads,
          firebaseWrites: c.firebaseWrites,
          firebaseStorageMb: c.firebaseStorageMb,
        );
      case _PlatformCostKind.firebase:
        return PlatformMonthCosts(
          bunnyStorageGb: c.bunnyStorageGb,
          bunnyTrafficGb: c.bunnyTrafficGb,
          hetznerMonthlyEur: c.hetznerMonthlyEur,
          openAiAmountEur: c.openAiAmountEur,
          firebaseReads: _parseInt(_c1.text),
          firebaseWrites: _parseInt(_c2.text),
          firebaseStorageMb: _parseInt(_c3.text),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.kind) {
      _PlatformCostKind.bunny => 'Bunny.net',
      _PlatformCostKind.hetzner => 'Hetzner',
      _PlatformCostKind.openai => 'OpenAI API',
      _PlatformCostKind.firebase => 'Firebase',
    };

    return AlertDialog(
      title: Text('Aggiorna $title'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: switch (widget.kind) {
            _PlatformCostKind.bunny => [
              TextField(
                controller: _c1,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Storage (GB)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _c2,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Traffico (GB)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            _PlatformCostKind.hetzner => [
              TextField(
                controller: _c1,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Abbonamento mensile (€)',
                  border: OutlineInputBorder(),
                  helperText: 'Default: 17,00 €',
                ),
              ),
            ],
            _PlatformCostKind.openai => [
              TextField(
                controller: _c1,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Importo mese (€)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            _PlatformCostKind.firebase => [
              TextField(
                controller: _c1,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Letture',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _c2,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Scritture',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _c3,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Storage (MB)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _buildResult()),
          child: const Text('Salva'),
        ),
      ],
    );
  }
}
