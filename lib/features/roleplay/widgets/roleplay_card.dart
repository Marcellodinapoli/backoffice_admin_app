import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/roleplay_ai_provider.dart';
import '../../../models/roleplay_simulation.dart';

class RoleplayCard extends StatelessWidget {
  final RoleplaySimulation simulation;
  final ValueChanged<String>? onAiProviderChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onViewPrompt;

  const RoleplayCard({
    super.key,
    required this.simulation,
    this.onAiProviderChanged,
    this.onEdit,
    this.onDelete,
    this.onViewPrompt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.record_voice_over_outlined,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    simulation.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (onEdit != null || onDelete != null || onViewPrompt != null)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      } else if (value == 'prompt') {
                        onViewPrompt?.call();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifica'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Elimina'),
                      ),
                      PopupMenuItem(
                        value: 'prompt',
                        child: Text('Vedi/Modifica Prompt'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              simulation.category,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            if (simulation.practiceData.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...simulation.practiceData.take(2).map(
                    (row) => Text(
                      '${row['label']}: ${row['value']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            ],
            const SizedBox(height: 12),
            Text(
              'Motore AI su Planet: ${RoleplayAiProvider.label(simulation.aiProvider)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            RoleplayAiProvider.selector(
              current: simulation.aiProvider,
              onChanged: onAiProviderChanged ?? (_) {},
            ),
            const SizedBox(height: 8),
            Text(
              simulation.aiProvider == RoleplayAiProvider.gpt
                  ? 'Prompt GPT: menu ⋮ → Vedi/Modifica Prompt'
                  : 'Prompt Hetzner: menu ⋮ → Vedi/Modifica Prompt',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
