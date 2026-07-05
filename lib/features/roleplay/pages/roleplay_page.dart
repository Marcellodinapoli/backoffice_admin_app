import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/roleplay/roleplay_config_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/roleplay_simulation.dart';
import '../../../services/firebase/roleplay_admin_service.dart';
import '../../../services/firebase/roleplay_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../widgets/roleplay_card.dart';
import 'roleplay_form_page.dart';

class RoleplayPage extends StatefulWidget {
  const RoleplayPage({super.key});

  @override
  State<RoleplayPage> createState() => _RoleplayPageState();
}

class _RoleplayPageState extends State<RoleplayPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _editSimulation(RoleplaySimulation simulation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleplayFormPage(simulation: simulation),
      ),
    );
  }

  Future<void> _showPromptDialog(RoleplaySimulation simulation) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _RoleplayPromptDialog(simulation: simulation),
    );
  }

  Future<void> _confirmDelete(RoleplaySimulation simulation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Conferma eliminazione'),
        content: const Text(
          'Sei sicuro di voler eliminare questa simulazione?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await RoleplayService.instance.deleteSimulation(simulation.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simulazione eliminata')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore eliminazione: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Role Play',
          subtitle: 'Simulazioni per formazione',
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sollecito'),
            Tab(text: 'Recupero'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _RoleplayList(
                onEdit: _editSimulation,
                onDelete: _confirmDelete,
                onViewPrompt: _showPromptDialog,
              ),
              _RoleplayList(
                category: 'Recupero',
                onEdit: _editSimulation,
                onDelete: _confirmDelete,
                onViewPrompt: _showPromptDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleplayPromptDialog extends StatefulWidget {
  const _RoleplayPromptDialog({required this.simulation});

  final RoleplaySimulation simulation;

  @override
  State<_RoleplayPromptDialog> createState() => _RoleplayPromptDialogState();
}

class _RoleplayPromptDialogState extends State<_RoleplayPromptDialog> {
  final _promptCtrl = TextEditingController();
  bool _dirty = false;
  bool _saving = false;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  void _syncFromRemote(String stored) {
    if (_dirty) return;
    final text = stored.trim().isEmpty
        ? RoleplayConfigService.defaultSimulationPrompt
        : stored;
    if (_promptCtrl.text != text) {
      _promptCtrl.text = text;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await RoleplayAdminService.saveSimulationPrompt(
        widget.simulation.id,
        _promptCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prompt aggiornato')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore salvataggio: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(RoleplayConfigService.collection)
          .doc(widget.simulation.id)
          .snapshots(),
      builder: (context, snapshot) {
        final stored = RoleplayConfigService.resolveStoredSimulationPrompt(
          snapshot.data?.data() ?? {},
        );
        _syncFromRemote(stored);

        return AlertDialog(
          title: Text('Prompt OpenAI — ${widget.simulation.title}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Istruzioni per il debitore simulato. Salvato in Firestore '
                    'e condiviso tra BK app e web.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _promptCtrl,
                    minLines: 14,
                    maxLines: 28,
                    onChanged: (_) => _dirty = true,
                    decoration: const InputDecoration(
                      labelText: 'Prompt debitore (OpenAI)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving
                  ? null
                  : () {
                      setState(() {
                        _dirty = true;
                        _promptCtrl.text =
                            RoleplayConfigService.defaultSimulationPrompt;
                      });
                    },
              child: const Text('Ripristina predefinito'),
            ),
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Chiudi'),
            ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salva'),
            ),
          ],
        );
      },
    );
  }
}

class _RoleplayList extends StatelessWidget {
  final String category;
  final void Function(RoleplaySimulation simulation) onEdit;
  final Future<void> Function(RoleplaySimulation simulation) onDelete;
  final Future<void> Function(RoleplaySimulation simulation) onViewPrompt;

  const _RoleplayList({
    this.category = 'Sollecito',
    required this.onEdit,
    required this.onDelete,
    required this.onViewPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RoleplaySimulation>>(
      stream: RoleplayService.instance.watchByCategory(category),
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
          return EmptyState(
            icon: Icons.record_voice_over_outlined,
            title: 'Nessuna simulazione',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final sim = items[i];
            return RoleplayCard(
              simulation: sim,
              onEdit: () => onEdit(sim),
              onDelete: () => onDelete(sim),
              onViewPrompt: () => onViewPrompt(sim),
            );
          },
        );
      },
    );
  }
}
