import 'package:flutter/material.dart';

import '../../../models/announcement.dart';
import '../../../services/firebase/announcements_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../widgets/announcement_card.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Future<void> _showForm(
    BuildContext context, {
    Announcement? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final msgCtrl = TextEditingController(text: existing?.message ?? '');
    var target = existing?.target ?? 'all';
    var type = existing?.type ?? 'avviso';
    var active = existing?.active ?? true;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (_, setModal) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null ? 'Nuovo annuncio' : 'Modifica annuncio',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titolo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: msgCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Messaggio'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: target,
                  decoration: const InputDecoration(labelText: 'Target'),
                  items: ['all', 'public', 'work', 'company']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setModal(() => target = v ?? 'all'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: ['avviso', 'aggiornamento', 'alert']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setModal(() => type = v ?? 'avviso'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Attivo'),
                  value: active,
                  onChanged: (v) => setModal(() => active = v),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(existing == null ? 'Pubblica' : 'Salva'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;
    if (titleCtrl.text.trim().isEmpty) return;

    final svc = AnnouncementsService.instance;
    final targetCount = await svc.countTargetUsers(target);

    if (existing == null) {
      await svc.createAnnouncement(
        title: titleCtrl.text.trim(),
        message: msgCtrl.text.trim(),
        target: target,
        type: type,
        active: active,
        targetCount: targetCount,
      );
    } else {
      await svc.updateAnnouncement(
        id: existing.id,
        title: titleCtrl.text.trim(),
        message: msgCtrl.text.trim(),
        target: target,
        type: type,
        active: active,
        targetCount: targetCount,
        seenCount: existing.seenCount,
        createdAt: existing.createdAt,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Notifiche',
          subtitle: 'Popup e annunci in-app',
          trailing: FilledButton.icon(
            onPressed: () => _showForm(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nuovo'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Announcement>>(
            stream: AnnouncementsService.instance.watchAll(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const LoadingView();
              }
              if (snapshot.hasError) {
                return ErrorView(message: 'Errore: ${snapshot.error}');
              }

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const EmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'Nessun annuncio',
                  subtitle: 'Crea il primo annuncio per gli utenti',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final ann = items[i];
                  return AnnouncementCard(
                    announcement: ann,
                    onEdit: () => _showForm(context, existing: ann),
                    onToggle: () =>
                        AnnouncementsService.instance.toggleActive(
                      ann.id,
                      ann.active,
                    ),
                    onDelete: () =>
                        AnnouncementsService.instance.deleteAnnouncement(
                      ann.id,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
