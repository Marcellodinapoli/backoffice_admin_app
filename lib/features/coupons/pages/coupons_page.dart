import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/firebase/coupon_admin_service.dart';
import '../widgets/coupon_edit_dialog.dart';
import '../../../shared/widgets/section_header.dart';

class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  final _codeCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  final _maxUsesCtrl = TextEditingController();
  DateTime? _expiresAt;
  DateTime? _benefitExpiresAt;
  String? _restrictedPlan;
  bool _saving = false;
  String? _formError;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _labelCtrl.dispose();
    _maxUsesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      helpText: 'Ultimo giorno per inserire il codice (opzionale)',
    );
    if (date == null || !mounted) return;
    setState(() => _expiresAt = date);
  }

  Future<void> _pickBenefitExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _benefitExpiresAt ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      helpText: 'Scadenza effetto piano/limiti *',
    );
    if (date == null || !mounted) return;
    setState(() => _benefitExpiresAt = date);
  }

  Future<void> _createCoupon() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _formError = 'Inserisci il codice coupon.');
      return;
    }

    int? maxUses;
    final maxRaw = _maxUsesCtrl.text.trim();
    if (maxRaw.isNotEmpty) {
      maxUses = int.tryParse(maxRaw);
      if (maxUses == null || maxUses < 1) {
        setState(() => _formError = 'Utilizzi massimi non valido.');
        return;
      }
    }

    if (_benefitExpiresAt == null) {
      setState(() => _formError = 'Inserisci la scadenza effetto piano/limiti.');
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      await CouponAdminService.createCoupon(
        code: code,
        label: _labelCtrl.text.trim(),
        maxUses: maxUses,
        expiresAt: _expiresAt,
        benefitExpiresAt: _benefitExpiresAt!,
        restrictedPlan: _restrictedPlan,
      );
      if (!mounted) return;
      _codeCtrl.clear();
      _labelCtrl.clear();
      _maxUsesCtrl.clear();
      setState(() {
        _expiresAt = null;
        _benefitExpiresAt = null;
        _restrictedPlan = null;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coupon ${CouponAdminService.normalizeCode(code)} creato.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = e
            .toString()
            .replaceFirst('StateError: ', '')
            .replaceFirst('ArgumentError: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SectionHeader(
          title: 'Coupon',
          subtitle:
              'Codici per azzerare limiti e attivare il piano in CreditCalc Store',
        ),
        const SizedBox(height: 12),
        _buildCreateCard(),
        const SizedBox(height: 24),
        const Text(
          'Coupon esistenti',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _buildList(),
      ],
    );
  }

  Widget _buildCreateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nuovo coupon',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Codice coupon *',
                hintText: 'Es. PROMO2026',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Nota interna (opzionale)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _maxUsesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Utilizzi massimi (vuoto = illimitati)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              value: _restrictedPlan,
              decoration: const InputDecoration(
                labelText: 'Piano vincolato',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Qualsiasi piano')),
                DropdownMenuItem(value: 'free', child: Text('Solo Gratis')),
                DropdownMenuItem(value: 'plus', child: Text('Solo Plus')),
                DropdownMenuItem(
                  value: 'enterprise',
                  child: Text('Solo Enterprise'),
                ),
              ],
              onChanged: (v) => setState(() => _restrictedPlan = v),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickBenefitExpiry,
              icon: const Icon(Icons.event_available_outlined, size: 18),
              label: Text(
                _benefitExpiresAt == null
                    ? 'Scadenza effetto piano/limiti *'
                    : 'Effetto fino al: ${_formatDate(_benefitExpiresAt!)}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickExpiry,
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(
                _expiresAt == null
                    ? 'Scadenza utilizzo codice (opzionale)'
                    : 'Codice utilizzabile fino al: ${_formatDate(_expiresAt!)}',
              ),
            ),
            if (_expiresAt != null)
              TextButton(
                onPressed: () => setState(() => _expiresAt = null),
                child: const Text('Rimuovi scadenza utilizzo codice'),
              ),
            if (_benefitExpiresAt != null)
              TextButton(
                onPressed: () => setState(() => _benefitExpiresAt = null),
                child: const Text('Rimuovi scadenza effetto'),
              ),
            if (_formError != null) ...[
              const SizedBox(height: 8),
              Text(
                _formError!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _createCoupon,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crea coupon'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<CouponRecord>>(
      stream: CouponAdminService.watchCoupons(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Text(
            'Errore: ${snap.error}',
            style: TextStyle(color: Colors.red.shade700),
          );
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Text(
            'Nessun coupon ancora creato.',
            style: TextStyle(color: AppColors.textSecondary),
          );
        }
        return Column(
          children: [
            for (final c in items) ...[
              _CouponTile(
                record: c,
                onToggle: (enabled) => CouponAdminService.setEnabled(
                  code: c.code,
                  enabled: enabled,
                ),
                onEdit: () async {
                  final saved = await CouponEditDialog.show(context, c);
                  if (saved == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Coupon ${c.code} aggiornato.')),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _CouponTile extends StatelessWidget {
  final CouponRecord record;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const _CouponTile({
    required this.record,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final status = !record.enabled
        ? 'Disattivato'
        : record.expired
            ? 'Scaduto'
            : record.exhausted
                ? 'Esaurito'
                : 'Attivo';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Switch(value: record.enabled, onChanged: onToggle),
                IconButton(
                  tooltip: 'Modifica',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
              ],
            ),
            Text(status),
            if (record.createdAt != null)
              Text('Creato il: ${_formatDate(record.createdAt!)}'),
            if (record.label != null) Text('Nota: ${record.label}'),
            Text(
              'Utilizzi: ${record.usedCount}'
              '${record.maxUses != null ? ' / ${record.maxUses}' : ''}',
            ),
            if (record.plan != null)
              Text('Piano: ${couponPlanLabel(record.plan)}'),
            if (record.benefitExpiresAt != null)
              Text(
                'Effetto fino al: ${_formatDate(record.benefitExpiresAt!)}',
              ),
            if (record.expiresAt != null)
              Text(
                'Codice utilizzabile fino al: ${_formatDate(record.expiresAt!)}',
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
