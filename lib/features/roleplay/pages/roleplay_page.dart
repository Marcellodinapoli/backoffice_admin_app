import 'package:flutter/material.dart';

import '../../../models/roleplay_simulation.dart';
import '../../../services/firebase/roleplay_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../widgets/roleplay_card.dart';

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

  void _showPrompt(RoleplaySimulation sim) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sim.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  child: Text(sim.prompt.isEmpty ? 'Nessun prompt' : sim.prompt),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              _RoleplayList(category: 'Sollecito', onTap: _showPrompt),
              _RoleplayList(category: 'Recupero', onTap: _showPrompt),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleplayList extends StatelessWidget {
  final String category;
  final void Function(RoleplaySimulation) onTap;

  const _RoleplayList({required this.category, required this.onTap});

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
          itemBuilder: (_, i) => RoleplayCard(
            simulation: items[i],
            onTap: () => onTap(items[i]),
          ),
        );
      },
    );
  }
}
