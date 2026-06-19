import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/roleplay_ai_provider.dart';
import '../../../models/roleplay_simulation.dart';
import '../../../services/firebase/roleplay_service.dart';

class RoleplayFormPage extends StatefulWidget {
  final RoleplaySimulation simulation;

  const RoleplayFormPage({super.key, required this.simulation});

  @override
  State<RoleplayFormPage> createState() => _RoleplayFormPageState();
}

class _PracticeRow {
  final TextEditingController label;
  final TextEditingController value;

  _PracticeRow({String labelText = '', String valueText = ''})
      : label = TextEditingController(text: labelText),
        value = TextEditingController(text: valueText);

  void dispose() {
    label.dispose();
    value.dispose();
  }
}

class _RoleplayFormPageState extends State<RoleplayFormPage> {
  final _titleCtrl = TextEditingController();
  final _promptCtrl = TextEditingController();
  final _gptPromptCtrl = TextEditingController();

  late String _category;
  late String _aiProvider;
  final List<_PracticeRow> _practiceRows = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final sim = widget.simulation;
    _titleCtrl.text = sim.title;
    _promptCtrl.text = sim.prompt;
    _gptPromptCtrl.text = sim.gptPrompt;
    _category =
        sim.category == 'Recupero' ? 'Recupero' : 'Sollecito';
    _aiProvider = sim.aiProvider;

    if (sim.practiceData.isEmpty) {
      _practiceRows.add(_PracticeRow());
    } else {
      for (final row in sim.practiceData) {
        _practiceRows.add(
          _PracticeRow(
            labelText: row['label']?.toString() ?? '',
            valueText: row['value']?.toString() ?? '',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _promptCtrl.dispose();
    _gptPromptCtrl.dispose();
    for (final row in _practiceRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addPracticeRow() {
    setState(() => _practiceRows.add(_PracticeRow()));
  }

  void _removePracticeRow(int index) {
    setState(() {
      _practiceRows[index].dispose();
      _practiceRows.removeAt(index);
      if (_practiceRows.isEmpty) {
        _practiceRows.add(_PracticeRow());
      }
    });
  }

  List<Map<String, String>> _formattedPracticeData() {
    return _practiceRows
        .where(
          (row) =>
              row.label.text.trim().isNotEmpty &&
              row.value.text.trim().isNotEmpty,
        )
        .map(
          (row) => {
            'label': row.label.text.trim(),
            'value': row.value.text.trim(),
          },
        )
        .toList();
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
      await RoleplayService.instance.updateSimulation(
        id: widget.simulation.id,
        title: title,
        category: _category,
        prompt: _promptCtrl.text.trim(),
        gptPrompt: _gptPromptCtrl.text.trim(),
        practiceData: _formattedPracticeData(),
        aiProvider: _aiProvider,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simulazione aggiornata')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore salvataggio: $e'),
          backgroundColor: AppColors.error,
        ),
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
        title: const Text('Modifica simulazione'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Sollecito', child: Text('Sollecito')),
                DropdownMenuItem(value: 'Recupero', child: Text('Recupero')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Motore AI (Planet)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 8),
            RoleplayAiProvider.selector(
              current: _aiProvider,
              onChanged: (value) => setState(() => _aiProvider = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Titolo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Dati pratica',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 12),
            ..._practiceRows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: row.label,
                        decoration: const InputDecoration(
                          labelText: 'Etichetta',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: row.value,
                        decoration: const InputDecoration(
                          labelText: 'Valore',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Rimuovi riga',
                      onPressed: () => _removePracticeRow(index),
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    ),
                  ],
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addPracticeRow,
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi riga'),
              ),
            ),
            const SizedBox(height: 8),
            RoleplayAiProvider.promptEditor(
              aiProvider: _aiProvider,
              hetznerPrompt: _promptCtrl,
              gptPrompt: _gptPromptCtrl,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salva'),
          ),
        ),
      ),
    );
  }
}
