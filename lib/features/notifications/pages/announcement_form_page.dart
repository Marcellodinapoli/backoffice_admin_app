import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/announcement.dart';
import '../../../services/firebase/announcements_service.dart';

class AnnouncementFormPage extends StatefulWidget {
  final Announcement? existing;

  const AnnouncementFormPage({super.key, this.existing});

  @override
  State<AnnouncementFormPage> createState() => _AnnouncementFormPageState();
}

class _AnnouncementFormPageState extends State<AnnouncementFormPage> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  late String _target;
  late String _type;
  late bool _active;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleCtrl.text = existing?.title ?? '';
    _msgCtrl.text = existing?.message ?? '';
    _target = existing?.target ?? 'all';
    _type = existing?.type ?? 'avviso';
    _active = existing?.active ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un titolo')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final svc = AnnouncementsService.instance;
      final targetCount = await svc.countTargetUsers(_target);
      final existing = widget.existing;

      if (existing == null) {
        await svc.createAnnouncement(
          title: title,
          message: _msgCtrl.text.trim(),
          target: _target,
          type: _type,
          active: _active,
          targetCount: targetCount,
        );
      } else {
        await svc.updateAnnouncement(
          id: existing.id,
          title: title,
          message: _msgCtrl.text.trim(),
          target: _target,
          type: _type,
          active: _active,
          targetCount: targetCount,
          seenCount: existing.seenCount,
          createdAt: existing.createdAt,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(_isEditing ? 'Modifica annuncio' : 'Nuovo annuncio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titolo'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _msgCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Messaggio',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _target,
              decoration: const InputDecoration(labelText: 'Target'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tutti')),
                DropdownMenuItem(value: 'public', child: Text('Public')),
                DropdownMenuItem(value: 'work', child: Text('Work')),
                DropdownMenuItem(value: 'company', child: Text('Company')),
              ],
              onChanged: (v) => setState(() => _target = v ?? 'all'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: 'avviso', child: Text('Avviso')),
                DropdownMenuItem(
                  value: 'aggiornamento',
                  child: Text('Aggiornamento'),
                ),
                DropdownMenuItem(value: 'alert', child: Text('Alert')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'avviso'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Attivo'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Annulla'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Salva' : 'Pubblica'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
