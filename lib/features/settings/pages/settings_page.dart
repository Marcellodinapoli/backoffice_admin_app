import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/dashboard_stats.dart';
import '../../../services/firebase/settings_service.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';

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

  Future<void> _cleanup() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pulizia database'),
        content: const Text(
          'Verranno eliminati solo pendingLogins scaduti (>2 min) '
          'e dati test/debug. I dati reali non verranno toccati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pulisci'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final count = await SettingsService.instance.cleanupObsoleteData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pulizia completata: $count elementi')),
      );
    }
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
          subtitle: 'Manutenzione e manutenzione sistema',
        ),
        Expanded(
          child: StreamBuilder<MaintenanceSettings>(
            stream: SettingsService.instance.watchMaintenance(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return const LoadingView();
              }

              final maintenance = snap.data ??
                  const MaintenanceSettings(enabled: false, section: 'Tutto');

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _buildMaintenanceCard(maintenance),
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
                      subtitle: const Text('Rimuove dati scaduti e debug'),
                      trailing: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : OutlinedButton(
                              onPressed: _cleanup,
                              child: const Text('Pulisci'),
                            ),
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
          ),
        ),
      ],
    );
  }
}
