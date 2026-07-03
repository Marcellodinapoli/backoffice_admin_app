import 'package:flutter/material.dart';

import '../../../core/normative/normative_search_config_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/firebase/normative_search_admin_service.dart';
import '../../../shared/widgets/section_header.dart';

class NormativeSearchPage extends StatefulWidget {
  const NormativeSearchPage({super.key});

  @override
  State<NormativeSearchPage> createState() => _NormativeSearchPageState();
}

class _NormativeSearchPageState extends State<NormativeSearchPage> {
  bool _saving = false;
  bool _dirty = false;
  String? _formError;
  final _promptCtrl = TextEditingController();

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  void _syncFromRemote(String stored) {
    if (_dirty) return;
    final text = stored.trim().isEmpty
        ? NormativeSearchConfigService.defaultSystemPrompt
        : stored;
    if (_promptCtrl.text != text) {
      _promptCtrl.text = text;
    }
  }

  Future<void> _save() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      setState(() => _formError = 'Inserisci il prompt di sistema.');
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      await NormativeSearchAdminService.savePrompt(prompt);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _dirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prompt salvato.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = e.toString().replaceFirst('StateError: ', '');
      });
    }
  }

  Future<void> _restoreDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ripristina prompt predefinito'),
        content: const Text(
          'Vuoi caricare il prompt predefinito nell\'editor? '
          'Salva per applicarlo in produzione.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ripristina'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _dirty = true;
      _promptCtrl.text = NormativeSearchConfigService.defaultSystemPrompt;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: NormativeSearchConfigService.watchStoredPrompt(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData &&
            _promptCtrl.text.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        _syncFromRemote(snapshot.data ?? '');

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const SectionHeader(
              title: 'Ricerca normativa',
              subtitle:
                  'Prompt AI per CreditCalc Store → Sviluppa → Ricerca normativa',
            ),
            const SizedBox(height: 12),
            Text(
              'Definisce il perimetro delle risposte (recupero crediti e '
              'attività stragiudiziale). Salvato in Firestore '
              'settings/normative_search.',
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.45,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _promptCtrl,
                      minLines: 14,
                      maxLines: 28,
                      onChanged: (_) => _dirty = true,
                      decoration: const InputDecoration(
                        labelText: 'Prompt di sistema',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _formError!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _saving ? null : _restoreDefault,
                          child: const Text('Ripristina predefinito'),
                        ),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _saving ? 'Salvataggio…' : 'Salva prompt',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
