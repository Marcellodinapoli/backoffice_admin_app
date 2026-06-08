import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/cleanup_result.dart';
import '../../services/firebase/settings_service.dart';

/// Conferma ed esegue la pulizia database (stesso flusso app + web).
class SettingsCleanupButton extends StatefulWidget {
  final bool compact;

  const SettingsCleanupButton({super.key, this.compact = false});

  @override
  State<SettingsCleanupButton> createState() => _SettingsCleanupButtonState();
}

class _SettingsCleanupButtonState extends State<SettingsCleanupButton> {
  bool _running = false;

  Future<void> _runCleanup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pulizia database'),
        content: const Text(SettingsService.cleanupConfirmMessage),
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

    if (confirm != true || !mounted) return;

    setState(() => _running = true);

    CleanupResult result;
    try {
      result = await SettingsService.instance.cleanupObsoleteData();
    } catch (e) {
      if (!mounted) return;
      setState(() => _running = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Errore durante la pulizia: $e'),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _running = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: result.hasErrors ? AppColors.warning : null,
        content: Text(result.summaryMessage()),
        duration: Duration(seconds: result.hasErrors ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_running) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (widget.compact) {
      return OutlinedButton(
        onPressed: _runCleanup,
        child: const Text('Pulisci'),
      );
    }

    return ElevatedButton.icon(
      icon: const Icon(Icons.cleaning_services),
      label: const Text('Pulisci tutto'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
      onPressed: _runCleanup,
    );
  }
}
