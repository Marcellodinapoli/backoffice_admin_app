import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/firebase/versioned_settings_service.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import 'versioned_consent_detail_page.dart';

class VersionedConsentConfig {
  const VersionedConsentConfig({
    required this.settingsDocId,
    required this.pageTitle,
    required this.previewTitle,
    required this.description,
    required this.defaultVersion,
    required this.saveSnackMessage,
    required this.versionDialogTitle,
  });

  final String settingsDocId;
  final String pageTitle;
  final String previewTitle;
  final String description;
  final String defaultVersion;
  final String saveSnackMessage;
  final String versionDialogTitle;
}

abstract final class VersionedConsentConfigs {
  static const job = VersionedConsentConfig(
    settingsDocId: 'job_offer_rules',
    pageTitle: 'Consensi job',
    previewTitle: 'Regole pubblicazione offerte',
    description:
        'Regolamento che le aziende devono accettare prima di pubblicare un\'offerta di lavoro.',
    defaultVersion: '1.0',
    saveSnackMessage: 'Regolamento aggiornato',
    versionDialogTitle: 'Nuova versione regolamento',
  );

  static const registration = VersionedConsentConfig(
    settingsDocId: 'registration_consents',
    pageTitle: 'Consensi registrazione',
    previewTitle: 'Privacy e condizioni di registrazione',
    description:
        'Documento unico che utenti, aziende e collaboratori devono accettare '
        'in registrazione e ad ogni accesso quando la versione cambia.',
    defaultVersion: '1.0.0',
    saveSnackMessage: 'Consensi registrazione aggiornati',
    versionDialogTitle: 'Nuova versione consensi',
  );
}

class VersionedConsentPage extends StatefulWidget {
  final VersionedConsentConfig config;

  const VersionedConsentPage({super.key, required this.config});

  @override
  State<VersionedConsentPage> createState() => _VersionedConsentPageState();
}

class _VersionedConsentPageState extends State<VersionedConsentPage> {
  final _controller = TextEditingController();
  bool _loading = true;
  String _version = '1.0.0';

  VersionedConsentConfig get _config => widget.config;

  @override
  void initState() {
    super.initState();
    _version = _config.defaultVersion;
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final doc = await VersionedSettingsService.instance.load(
      docId: _config.settingsDocId,
      defaultVersion: _config.defaultVersion,
    );
    if (!mounted) return;
    setState(() {
      _controller.text = doc.text;
      _version = doc.version;
      _loading = false;
    });
  }

  Future<void> _saveNewVersion() async {
    final versionCtrl = TextEditingController();

    final newVersion = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_config.versionDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Versione attuale: $_version'),
            const SizedBox(height: 12),
            TextField(
              controller: versionCtrl,
              decoration: const InputDecoration(
                labelText: 'Nuova versione',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, versionCtrl.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    versionCtrl.dispose();
    if (newVersion == null || newVersion.isEmpty) return;

    await VersionedSettingsService.instance.saveNewVersion(
      docId: _config.settingsDocId,
      text: _controller.text,
      newVersion: newVersion,
    );

    if (!mounted) return;
    setState(() => _version = newVersion);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_config.saveSnackMessage)),
    );
  }

  void _openEditableDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VersionedConsentDetailPage(
          title: _config.previewTitle,
          controller: _controller,
          version: _version,
          readOnly: false,
          onSave: _saveNewVersion,
        ),
      ),
    ).then((_) {
      if (mounted) _load();
    });
  }

  void _openHistoryDetails(String title, String text, String version) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VersionedConsentDetailPage(
          title: title,
          controller: TextEditingController(text: text),
          version: version,
          readOnly: true,
          onSave: () async {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: _config.pageTitle,
          subtitle: _config.description,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _config.previewTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Versione: $_version'),
                  const SizedBox(height: 8),
                  Text(
                    _config.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: _openEditableDetails,
                      child: const Text('Apri dettagli'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            'Storico versioni',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: VersionedSettingsService.instance
                .watchVersions(_config.settingsDocId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LoadingView();
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Nessuna versione salvata',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final doc = docs[i];
                  final data = doc.data();
                  final text = (data['text'] ?? '').toString();
                  final version = (data['version'] ?? '').toString();
                  final ts = data['createdAt'] as Timestamp?;
                  final date = ts != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate())
                      : '—';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text('Versione $version'),
                      subtitle: Text(
                        '$date\n${text.length > 120 ? '${text.substring(0, 120)}...' : text}',
                      ),
                      isThreeLine: true,
                      trailing: TextButton(
                        onPressed: () => _openHistoryDetails(
                          'Versione $version',
                          text,
                          version,
                        ),
                        child: const Text('Apri'),
                      ),
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

class JobConsentsPage extends StatelessWidget {
  const JobConsentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const VersionedConsentPage(config: VersionedConsentConfigs.job);
  }
}

class RegistrationConsentsPage extends StatelessWidget {
  const RegistrationConsentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const VersionedConsentPage(
      config: VersionedConsentConfigs.registration,
    );
  }
}
