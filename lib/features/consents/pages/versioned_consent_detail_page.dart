import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class VersionedConsentDetailPage extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final String version;
  final bool readOnly;
  final Future<void> Function() onSave;

  const VersionedConsentDetailPage({
    super.key,
    required this.title,
    required this.controller,
    required this.version,
    required this.readOnly,
    required this.onSave,
  });

  @override
  State<VersionedConsentDetailPage> createState() =>
      _VersionedConsentDetailPageState();
}

class _VersionedConsentDetailPageState
    extends State<VersionedConsentDetailPage> {
  late String _initialText;
  bool _hasChanges = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initialText = widget.controller.text;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final changed = widget.controller.text != _initialText;
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    try {
      await widget.onSave();
      _initialText = widget.controller.text;
      if (!mounted) return;
      Navigator.pop(context);
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
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Versione: ${widget.version}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.readOnly
                  ? SingleChildScrollView(
                      child: Text(
                        widget.controller.text.isEmpty
                            ? 'Nessun testo.'
                            : widget.controller.text,
                        style: const TextStyle(height: 1.45),
                      ),
                    )
                  : TextField(
                      controller: widget.controller,
                      expands: true,
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                        hintText: 'Testo del documento (markdown supportato)',
                      ),
                    ),
            ),
            if (!widget.readOnly) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _hasChanges && !_saving ? _handleSave : null,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salva nuova versione'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
