import 'package:flutter/material.dart';

import '../../../models/announcement.dart';
import '../../../services/firebase/announcements_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import 'announcement_form_page.dart';
import '../widgets/announcement_card.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  Future<void> _openForm(
    BuildContext context, {
    Announcement? existing,
  }) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AnnouncementFormPage(existing: existing),
      ),
    );
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
            onPressed: () => _openForm(context),
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

              return StreamBuilder<Map<String, int>>(
                stream:
                    AnnouncementsService.instance.watchSeenCountsByAnnouncement(),
                builder: (context, seenSnap) {
                  final seenCounts = seenSnap.data ?? const {};

                  if (seenSnap.hasError && items.isNotEmpty) {
                    // Fallback: mostra almeno seenCount salvato sul documento.
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final ann = items[i];
                        return AnnouncementCard(
                          announcement: ann,
                          seenCount: 0,
                          onEdit: () => _openForm(context, existing: ann),
                          onToggle: () =>
                              AnnouncementsService.instance.toggleActive(
                            ann.id,
                            ann.active,
                          ),
                          onDelete: () => AnnouncementsService.instance
                              .deleteAnnouncement(ann.id),
                        );
                      },
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final ann = items[i];
                      return AnnouncementCard(
                        announcement: ann,
                        seenCount: seenCounts[ann.id] ?? 0,
                        onEdit: () => _openForm(context, existing: ann),
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
              );
            },
          ),
        ),
      ],
    );
  }
}
