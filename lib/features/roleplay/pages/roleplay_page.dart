import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/roleplay_ai_provider.dart';
import '../../../models/roleplay_simulation.dart';
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

  Future<void> _setAiProvider(String simulationId, String provider) async {
    try {
      await RoleplayService.instance.updateAiProvider(simulationId, provider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Motore AI: ${RoleplayAiProvider.label(provider)}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore salvataggio AI: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
    final promptCtrl = TextEditingController(text: simulation.prompt);
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Prompt - ${simulation.title}'),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: promptCtrl,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Nessun prompt',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Chiudi'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      try {
                        await RoleplayService.instance.updatePrompt(
                          simulation.id,
                          promptCtrl.text.trim(),
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Prompt aggiornato')),
                        );
                      } catch (e) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() => saving = false);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text('Errore salvataggio: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salva'),
            ),
          ],
        ),
      ),
    );

    promptCtrl.dispose();
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
                onAiProviderChanged: _setAiProvider,
                onEdit: _editSimulation,
                onDelete: _confirmDelete,
                onViewPrompt: _showPromptDialog,
              ),
              _RoleplayList(
                category: 'Recupero',
                onAiProviderChanged: _setAiProvider,
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

class _RoleplayList extends StatelessWidget {
  final String category;
  final Future<void> Function(String simulationId, String provider)
      onAiProviderChanged;
  final void Function(RoleplaySimulation simulation) onEdit;
  final Future<void> Function(RoleplaySimulation simulation) onDelete;
  final void Function(RoleplaySimulation simulation) onViewPrompt;

  const _RoleplayList({
    this.category = 'Sollecito',
    required this.onAiProviderChanged,
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
              onAiProviderChanged: (provider) =>
                  onAiProviderChanged(sim.id, provider),
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
