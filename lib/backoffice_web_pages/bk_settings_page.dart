import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dashboard_stats.dart';
import '../services/firebase/settings_service.dart';
import '../shared/widgets/settings_cleanup_button.dart';

class BkSettingsPage extends StatefulWidget {
  const BkSettingsPage({super.key});

  @override
  State<BkSettingsPage> createState() => _BkSettingsPageState();
}

class _BkSettingsPageState extends State<BkSettingsPage> {
  bool maintenanceMode = false;
  String selectedSection = 'Tutto';

  final List<String> sections = [
    'Tutto',
    'CreditForm',
    'CreditJob',
    'CreditCalc',
    'Area riservata',
  ];

  @override
  void initState() {
    super.initState();
    _loadMaintenanceSettings(); // ✅ FIX
  }

  // ✅ CARICAMENTO DA FIRESTORE
  Future<void> _loadMaintenanceSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('maintenance')
          .get();

      if (!doc.exists) return;

      final data = doc.data()!;

      if (!mounted) return;

      setState(() {
        maintenanceMode = data['enabled'] ?? false;
        selectedSection = data['section'] ?? 'Tutto';
      });
    } catch (e) {
      debugPrint("❌ Errore load maintenance: $e");
    }
  }

  // 🔧 Salvataggio manutenzione
  Future<void> _saveMaintenanceSettings() async {
    try {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc('maintenance')
          .set({
        'section': selectedSection,
        'enabled': maintenanceMode,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("❌ Errore salvataggio maintenance: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFFF5F5F5),
          child: Column(
            children: [
              ListTile(
                title: const Text('Seleziona sezione da bloccare'),
                subtitle:
                const Text('Applica la manutenzione solo a questa sezione o pagina'),
                trailing: DropdownButton<String>(
                  value: selectedSection,
                  items: sections
                      .map(
                        (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSection = value ?? 'Tutto';
                    });
                    _saveMaintenanceSettings();
                  },
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Modalità manutenzione'),
                subtitle: Text(
                  'Blocca temporaneamente l’accesso a: $selectedSection',
                ),
                value: maintenanceMode,
                onChanged: (value) {
                  setState(() {
                    maintenanceMode = value;
                  });
                  _saveMaintenanceSettings();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<NotificationSettings>(
          stream: SettingsService.instance.watchNotifications(),
          builder: (context, snap) {
            final notifications = snap.data ??
                const NotificationSettings(enabled: false);

            return Card(
              color: const Color(0xFFF5F5F5),
              child: SwitchListTile(
                title: const Text('Notifiche push attive'),
                subtitle: const Text(
                  'Abilita o disabilita l\'invio push a tutti gli utenti '
                  '(salvato su Firestore)',
                ),
                value: notifications.enabled,
                onChanged: (value) async {
                  try {
                    await SettingsService.instance.saveNotifications(
                      enabled: value,
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red.shade700,
                        content: Text('Errore salvataggio notifiche: $e'),
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        Card(
          color: const Color(0xFFF5F5F5),
          child: ListTile(
            title: const Text('Pulizia database'),
            subtitle: const Text(
              'Rimuove pendingLogins scaduti e collezioni test/debug',
            ),
            trailing: const SettingsCleanupButton(),
          ),
        ),

        const SizedBox(height: 12),
        const Divider(),
        const Card(
          color: Color(0xFFF5F5F5),
          child: ListTile(
            title: Text('Versione applicazione'),
            subtitle: Text('-'),
          ),
        ),
      ],
    );
  }
}