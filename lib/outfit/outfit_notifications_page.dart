import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'outfit_firebase.dart';
import 'outfit_pages.dart';

/// Notifiche campanella MOODFIT (`in_app_notifications`).
/// Separate dagli avvisi banner (`in_app_alerts`).
class OutfitNotificationsPage extends StatefulWidget {
  const OutfitNotificationsPage({super.key});

  @override
  State<OutfitNotificationsPage> createState() => _OutfitNotificationsPageState();
}

class _OutfitNotificationsPageState extends State<OutfitNotificationsPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _priorityCtrl = TextEditingController(text: '10');

  bool _active = true;
  DateTime? _expiresAt;
  bool _saving = false;
  String? _formError;
  String? _editingId;

  CollectionReference<Map<String, dynamic>> get _col =>
      OutfitFirebase.firestore!.collection('in_app_notifications');

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _priorityCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _editingId = null;
    _titleCtrl.clear();
    _bodyCtrl.clear();
    _priorityCtrl.text = '10';
    _active = true;
    _expiresAt = null;
    _formError = null;
  }

  void _loadIntoForm(String id, Map<String, dynamic> data) {
    _editingId = id;
    _titleCtrl.text = '${data['title'] ?? ''}';
    _bodyCtrl.text = '${data['body'] ?? ''}';
    _priorityCtrl.text = '${data['priority'] ?? 10}';
    _active = data['active'] != false;
    final exp = data['expiresAt'];
    _expiresAt = exp is Timestamp ? exp.toDate() : null;
    _formError = null;
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      helpText: 'Scadenza notifica (opzionale)',
    );
    if (date == null || !mounted) return;
    setState(() => _expiresAt = date);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty && body.isEmpty) {
      setState(() => _formError = 'Inserisci titolo o testo.');
      return;
    }
    final priority = int.tryParse(_priorityCtrl.text.trim()) ?? 0;

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      final payload = <String, dynamic>{
        'title': title,
        'body': body,
        'priority': priority,
        'active': _active,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (_expiresAt != null) {
        payload['expiresAt'] = Timestamp.fromDate(
          DateTime(_expiresAt!.year, _expiresAt!.month, _expiresAt!.day, 23, 59, 59),
        );
      } else {
        payload['expiresAt'] = FieldValue.delete();
      }

      if (_editingId == null) {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await _col.add(payload);
      } else {
        await _col.doc(_editingId).set(payload, SetOptions(merge: true));
      }

      if (!mounted) return;
      _resetForm();
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifica salvata. Visibile nella campanella dell\'app.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = e.toString();
      });
    }
  }

  Future<void> _toggleActive(String id, bool current) async {
    await _col.doc(id).update({
      'active': !current,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina notifica'),
        content: const Text('Eliminare definitivamente questa notifica?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Elimina')),
        ],
      ),
    );
    if (ok != true) return;
    await _col.doc(id).delete();
    if (_editingId == id) {
      setState(_resetForm);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return OutfitAvailability(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Notifiche Outfit',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Notifiche della campanella nell\'app (badge e lista in Esplora → Avvisi). '
              'Separate dai banner sotto i riquadri (pagina Avvisi).',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.45),
            ),
            const SizedBox(height: 20),
            _buildFormCard(),
            const SizedBox(height: 28),
            const Text(
              'Notifiche esistenti',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _buildList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _editingId == null ? 'Nuova notifica' : 'Modifica notifica',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Titolo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyCtrl,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Testo',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priorityCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Priorità (più alta = prima)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Attiva'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _expiresAt == null
                    ? 'Scadenza: nessuna'
                    : 'Scadenza: ${_formatDate(_expiresAt!)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_expiresAt != null)
                    TextButton(
                      onPressed: () => setState(() => _expiresAt = null),
                      child: const Text('Rimuovi'),
                    ),
                  TextButton(onPressed: _pickExpiry, child: const Text('Scegli')),
                ],
              ),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 8),
              Text(_formError!, style: TextStyle(color: Colors.red.shade700)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (_editingId != null)
                  TextButton(
                    onPressed: _saving ? null : () => setState(_resetForm),
                    child: const Text('Annulla modifica'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Salvataggio…' : 'Salva notifica'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _col.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Text('Errore: ${snap.error}');
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = [...snap.data!.docs]
          ..sort((a, b) {
            final pa = (a.data()['priority'] as num?)?.toInt() ?? 0;
            final pb = (b.data()['priority'] as num?)?.toInt() ?? 0;
            return pb.compareTo(pa);
          });
        if (docs.isEmpty) {
          return Text(
            'Nessuna notifica. Creane una sopra.',
            style: TextStyle(color: Colors.grey.shade600),
          );
        }
        return Column(
          children: [
            for (final doc in docs)
              _NotificationTile(
                id: doc.id,
                data: doc.data(),
                onEdit: () => setState(() => _loadIntoForm(doc.id, doc.data())),
                onToggle: () => _toggleActive(doc.id, doc.data()['active'] != false),
                onDelete: () => _delete(doc.id),
                formatDate: _formatDate,
              ),
          ],
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.id,
    required this.data,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.formatDate,
  });

  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final active = data['active'] != false;
    final exp = data['expiresAt'];
    final expLabel = exp is Timestamp ? formatDate(exp.toDate()) : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          '${data['title'] ?? '(senza titolo)'}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: active ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          '${data['body'] ?? ''}\n'
          'Priorità: ${data['priority'] ?? 0} · '
          'Scadenza: $expLabel · ${active ? 'Attiva' : 'Disattiva'}',
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: active ? 'Disattiva' : 'Attiva',
              onPressed: onToggle,
              icon: Icon(active ? Icons.visibility : Icons.visibility_off),
            ),
            IconButton(
              tooltip: 'Modifica',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Elimina',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
