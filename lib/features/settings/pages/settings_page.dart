import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/dashboard_stats.dart';
import '../../../services/firebase/settings_service.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/settings_cleanup_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _saving = false;

  static const _sections = [
    'Tutto',
    'CreditForm',
    'CreditJob',
    'CreditCalc',
    'Area riservata',
  ];

  Future<void> _saveNotifications(bool enabled) async {
    setState(() => _saving = true);
    try {
      await SettingsService.instance.saveNotifications(enabled: enabled);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Notifiche push attivate per tutti gli utenti'
                : 'Notifiche push disattivate',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Salvataggio notifiche non riuscito. '
            'Verifica di essere loggato come admin Firebase.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save(MaintenanceSettings maintenance) async {
    setState(() => _saving = true);
    try {
      await SettingsService.instance.saveMaintenance(
        enabled: maintenance.enabled,
        section: maintenance.section,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impostazioni manutenzione salvate')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Salvataggio manutenzione non riuscito. '
            'Verifica di essere loggato come admin Firebase.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildNotificationsCard(NotificationSettings notifications) {
    return Card(
      child: SwitchListTile(
        title: const Text('Notifiche push attive'),
        subtitle: const Text(
          'Abilita o disabilita l\'invio push a tutti gli utenti '
          '(salvato su Firestore)',
        ),
        value: notifications.enabled,
        onChanged: _saving ? null : _saveNotifications,
      ),
    );
  }

  Widget _buildMaintenanceCard(MaintenanceSettings maintenance) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Sezione da bloccare'),
            subtitle: Text(maintenance.section),
            trailing: DropdownButton<String>(
              value: _sections.contains(maintenance.section)
                  ? maintenance.section
                  : 'Tutto',
              items: _sections
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                _save(
                  MaintenanceSettings(
                    enabled: maintenance.enabled,
                    section: v ?? 'Tutto',
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Modalità manutenzione'),
            subtitle: Text('Blocca accesso a: ${maintenance.section}'),
            value: maintenance.enabled,
            onChanged: (v) {
              _save(
                MaintenanceSettings(
                  enabled: v,
                  section: maintenance.section,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Impostazioni',
          subtitle: 'Manutenzione, notifiche push e sistema',
        ),
        Expanded(
          child: StreamBuilder<MaintenanceSettings>(
            stream: SettingsService.instance.watchMaintenance(),
            builder: (context, maintenanceSnap) {
              if (maintenanceSnap.connectionState == ConnectionState.waiting &&
                  !maintenanceSnap.hasData) {
                return const LoadingView();
              }

              final maintenance = maintenanceSnap.data ??
                  const MaintenanceSettings(enabled: false, section: 'Tutto');

              return StreamBuilder<NotificationSettings>(
                stream: SettingsService.instance.watchNotifications(),
                builder: (context, notificationsSnap) {
                  final notifications = notificationsSnap.data ??
                      const NotificationSettings(enabled: false);

                  final bottomInset =
                      MediaQuery.viewPaddingOf(context).bottom;

                  return ListView(
                    padding:
                        EdgeInsets.fromLTRB(16, 0, 16, 24 + bottomInset),
                    children: [
                      _buildMaintenanceCard(maintenance),
                      const SizedBox(height: 12),
                      _buildNotificationsCard(notifications),
                      const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.errorBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.cleaning_services,
                          color: AppColors.error,
                        ),
                      ),
                      title: const Text('Pulizia database'),
                      subtitle: const Text(
                        'Rimuove pendingLogins scaduti e collezioni test/debug',
                      ),
                      trailing: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const SettingsCleanupButton(compact: true),
                    ),
                  ),
                  const SizedBox(height: 12),
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('Versione app'),
                          subtitle: Text('1.0.0 · BackOffice Admin Mobile'),
                        ),
                      ),
                    ],
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
