import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../shared/widgets/section_header.dart';
import 'outfit_firebase.dart';
import 'outfit_repository.dart';

const _plans = ['free', 'plus', 'pro'];
const _defaultPlanLimits = {
  'free': {
    'maxWardrobeItems': 40,
    'maxAiAnalyzePerMonth': 15,
    'maxOutfitRegenerationsPerDay': 1,
    'canChangeSinglePiece': false,
    'calendarScope': 'today',
    'canPlanWeek': false,
    'canReminders': false,
    'maxShoppingCheckPerMonth': 5,
    'maxInsights': 1,
    'maxTripsPerMonth': 1,
    'maxTripDays': 3,
    'maxTripOutfits': 3,
    'canCapsuleWardrobe': false,
    'prioritySupport': false,
  },
  'plus': {
    'maxWardrobeItems': null,
    'maxAiAnalyzePerMonth': 200,
    'maxOutfitRegenerationsPerDay': null,
    'canChangeSinglePiece': true,
    'calendarScope': 'full',
    'canPlanWeek': true,
    'canReminders': true,
    'maxShoppingCheckPerMonth': 100,
    'maxInsights': 3,
    'maxTripsPerMonth': null,
    'maxTripDays': 7,
    'maxTripOutfits': 5,
    'canCapsuleWardrobe': false,
    'prioritySupport': false,
  },
  'pro': {
    'maxWardrobeItems': null,
    'maxAiAnalyzePerMonth': null,
    'fairUseAiAnalyzePerMonth': 500,
    'maxOutfitRegenerationsPerDay': null,
    'canChangeSinglePiece': true,
    'calendarScope': 'full',
    'canPlanWeek': true,
    'canReminders': true,
    'maxShoppingCheckPerMonth': null,
    'maxInsights': null,
    'maxTripsPerMonth': null,
    'maxTripDays': 14,
    'maxTripOutfits': 7,
    'canCapsuleWardrobe': true,
    'prioritySupport': true,
  },
};

const _planFields = <_PlanField>[
  _PlanField('maxWardrobeItems', _PlanFieldType.nullableInt),
  _PlanField('maxAiAnalyzePerMonth', _PlanFieldType.nullableInt),
  _PlanField('fairUseAiAnalyzePerMonth', _PlanFieldType.nullableInt),
  _PlanField('maxOutfitRegenerationsPerDay', _PlanFieldType.nullableInt),
  _PlanField('canChangeSinglePiece', _PlanFieldType.boolean),
  _PlanField('calendarScope', _PlanFieldType.calendarScope),
  _PlanField('canPlanWeek', _PlanFieldType.boolean),
  _PlanField('canReminders', _PlanFieldType.boolean),
  _PlanField('maxShoppingCheckPerMonth', _PlanFieldType.nullableInt),
  _PlanField('maxInsights', _PlanFieldType.nullableInt),
  _PlanField('maxTripsPerMonth', _PlanFieldType.nullableInt),
  _PlanField('maxTripDays', _PlanFieldType.nullableInt),
  _PlanField('maxTripOutfits', _PlanFieldType.nullableInt),
  _PlanField('canCapsuleWardrobe', _PlanFieldType.boolean),
  _PlanField('prioritySupport', _PlanFieldType.boolean),
];

enum _PlanFieldType { nullableInt, boolean, calendarScope }

class _PlanField {
  const _PlanField(this.name, this.type);
  final String name;
  final _PlanFieldType type;
}

String _safeJson(dynamic value) {
  String render(dynamic item, [int indent = 0]) {
    final pad = ' ' * indent;
    final childPad = ' ' * (indent + 2);
    if (item is Timestamp) return '"${item.toDate().toIso8601String()}"';
    if (item is GeoPoint) {
      return '{"latitude": ${item.latitude}, "longitude": ${item.longitude}}';
    }
    if (item is DocumentReference) return '"${item.path}"';
    if (item is DateTime) return '"${item.toIso8601String()}"';
    if (item is Map) {
      if (item.isEmpty) return '{}';
      final entries = item.entries
          .map((entry) => '$childPad"${entry.key}": ${render(entry.value, indent + 2)}')
          .join(',\n');
      return '{\n$entries\n$pad}';
    }
    if (item is Iterable) {
      if (item.isEmpty) return '[]';
      final entries =
          item.map((entry) => '$childPad${render(entry, indent + 2)}').join(',\n');
      return '[\n$entries\n$pad]';
    }
    if (item is String) {
      return '"${item.replaceAll('\\', '\\\\').replaceAll('"', r'\"').replaceAll('\n', r'\n')}"';
    }
    if (item == null || item is num || item is bool) return '$item';
    return '"${item.toString().replaceAll('"', r'\"')}"';
  }

  return render(value);
}

class OutfitAvailability extends StatelessWidget {
  const OutfitAvailability({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: OutfitFirebase.unavailableReason,
      builder: (_, reason, __) {
        if (!OutfitFirebase.isAvailable) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Outfit non disponibile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(reason ?? 'Sessione amministrativa Outfit non attiva.'),
                ],
              ),
            ),
          );
        }
        return child;
      },
    );
  }
}

class OutfitUsersPage extends StatefulWidget {
  const OutfitUsersPage({super.key});

  @override
  State<OutfitUsersPage> createState() => _OutfitUsersPageState();
}

class _OutfitUsersPageState extends State<OutfitUsersPage> {
  final _repo = const OutfitRepository();
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OutfitAvailability(
      child: Column(
        children: [
          const SectionHeader(
            title: 'Utenti Outfit',
            subtitle: 'Account consumer, piano, coupon, utilizzi e consensi',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Cerca nome, email o UID',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _repo.users(),
              builder: (_, snapshot) {
                if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final query = _search.text.trim().toLowerCase();
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  return query.isEmpty ||
                      doc.id.toLowerCase().contains(query) ||
                      '${data['displayName'] ?? data['name'] ?? ''}'.toLowerCase().contains(query) ||
                      '${data['email'] ?? ''}'.toLowerCase().contains(query);
                }).toList()
                  ..sort((a, b) => '${a.data()['email'] ?? ''}'
                      .compareTo('${b.data()['email'] ?? ''}'));
                if (docs.isEmpty) return const Center(child: Text('Nessun utente'));
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final name = '${data['displayName'] ?? data['name'] ?? 'Utente'}';
                    final status =
                        '${data['status'] ?? data['accountStatus'] ?? 'active'}';
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(name.isEmpty ? '?' : name[0].toUpperCase())),
                        title: Text(name),
                        subtitle: Text(
                          '${data['email'] ?? doc.id}\n${data['subscriptionPlan'] ?? 'free'} · $status',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OutfitUserDetailPage(uid: doc.id),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class OutfitUserDetailPage extends StatefulWidget {
  const OutfitUserDetailPage({super.key, required this.uid});
  final String uid;

  @override
  State<OutfitUserDetailPage> createState() => _OutfitUserDetailPageState();
}

class _OutfitUserDetailPageState extends State<OutfitUserDetailPage> {
  final _repo = const OutfitRepository();

  Future<void> _edit(Map<String, dynamic> data) async {
    var plan = '${data['subscriptionPlan'] ?? 'free'}';
    final coupon = TextEditingController(text: '${data['couponCode'] ?? ''}');
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Piano e coupon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _plans.contains(plan) ? plan : 'free',
                items: _plans
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase())))
                    .toList(),
                onChanged: (value) => setDialogState(() => plan = value ?? 'free'),
                decoration: const InputDecoration(labelText: 'Piano'),
              ),
              TextField(
                controller: coupon,
                decoration: const InputDecoration(labelText: 'Coupon'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salva')),
          ],
        ),
      ),
    );
    if (save == true) {
      await _repo.updateUser(uid: widget.uid, plan: plan, couponCode: coupon.text);
    }
    coupon.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Utente Outfit')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _repo.user(widget.uid),
        builder: (_, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data();
          if (data == null) return const Center(child: Text('Utente non trovato'));
          final status = '${data['status'] ?? data['accountStatus'] ?? 'active'}';
          final rawLegal = data['legalConsent'];
          final legal = rawLegal is Map
              ? Map<String, dynamic>.from(rawLegal)
              : <String, dynamic>{};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['displayName'] ?? data['name'] ?? 'Utente'}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text('${data['email'] ?? '—'}'),
                      const Divider(),
                      _row('UID', widget.uid),
                      _row('Stato', status),
                      _row('Piano', '${data['subscriptionPlan'] ?? 'free'}'),
                      _row('Coupon', '${data['couponCode'] ?? '—'}'),
                    ],
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _edit(data),
                    icon: const Icon(Icons.workspace_premium_outlined),
                    label: const Text('Piano / coupon'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _repo.setUserStatus(
                      widget.uid,
                      status == 'blocked' ? 'active' : 'blocked',
                    ),
                    icon: Icon(status == 'blocked' ? Icons.check_circle : Icons.block),
                    label: Text(status == 'blocked' ? 'Riattiva' : 'Blocca'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _repo.resetUsage(widget.uid),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset usage'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Utilizzi mensili',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _repo.usage(widget.uid),
                builder: (_, usageSnapshot) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      _safeJson(usageSnapshot.data?.data() ?? {}),
                    ),
                  ),
                ),
              ),
              const Text(
                'Profilo completo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(_safeJson(data)),
                ),
              ),
              const Text('Consensi correnti', style: TextStyle(fontWeight: FontWeight.bold)),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(_safeJson(legal)),
                ),
              ),
              const Text('Storico consensi', style: TextStyle(fontWeight: FontWeight.bold)),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _repo.consentHistory(widget.uid),
                builder: (_, consentSnapshot) {
                  if (consentSnapshot.hasError) {
                    return Text('Storico non disponibile: ${consentSnapshot.error}');
                  }
                  final docs = consentSnapshot.data?.docs ?? [];
                  if (docs.isEmpty) return const ListTile(title: Text('Nessuna voce storica'));
                  return Column(
                    children: docs
                        .map(
                          (doc) => Card(
                            child: ListTile(
                              title: Text(
                                '${doc.data()['documentType'] ?? doc.id}',
                              ),
                              subtitle: Text(_safeJson(doc.data())),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 80, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: SelectableText(value)),
          ],
        ),
      );
}

class OutfitPrivacyPage extends StatelessWidget {
  const OutfitPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) => const OutfitAvailability(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              SectionHeader(
                title: 'Privacy e Termini Outfit',
                subtitle: 'Documenti legali versionati pubblicati ai consumer',
              ),
              TabBar(tabs: [Tab(text: 'Privacy'), Tab(text: 'Termini')]),
              Expanded(
                child: TabBarView(
                  children: [
                    _LegalEditor(id: 'moodfit_privacy', fallbackTitle: 'Privacy Policy'),
                    _LegalEditor(id: 'moodfit_terms', fallbackTitle: 'Termini e condizioni'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _LegalEditor extends StatefulWidget {
  const _LegalEditor({required this.id, required this.fallbackTitle});
  final String id;
  final String fallbackTitle;

  @override
  State<_LegalEditor> createState() => _LegalEditorState();
}

class _LegalEditorState extends State<_LegalEditor> {
  final _repo = const OutfitRepository();
  final _version = TextEditingController();
  final _title = TextEditingController();
  final _content = {
    for (final locale in const ['it', 'en', 'fr', 'de'])
      locale: TextEditingController(),
  };
  bool _initialized = false;
  String? _error;

  @override
  void dispose() {
    _version.dispose();
    _title.dispose();
    for (final controller in _content.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _repo.legal(widget.id),
      builder: (_, snapshot) {
        final data = snapshot.data?.data() ?? {};
        if (!_initialized && snapshot.hasData) {
          _initialized = true;
          _version.text = '${data['activeVersion'] ?? '1.0.0'}';
          _title.text = '${data['title'] ?? widget.fallbackTitle}';
          _repo.legalVersion(widget.id, _version.text).then((version) {
            if (!mounted || version == null) return;
            final value = version['content'];
            if (value is Map) {
              for (final locale in _content.keys) {
                _content[locale]!.text = '${value[locale] ?? ''}';
              }
            } else if (value is String) {
              _content['it']!.text = value;
            }
            setState(() {});
          });
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(controller: _version, decoration: const InputDecoration(labelText: 'Nuova versione')),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Titolo')),
            const SizedBox(height: 12),
            DefaultTabController(
              length: _content.length,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'IT'),
                      Tab(text: 'EN'),
                      Tab(text: 'FR'),
                      Tab(text: 'DE'),
                    ],
                  ),
                  SizedBox(
                    height: 360,
                    child: TabBarView(
                      children: _content.entries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: TextField(
                                controller: entry.value,
                                minLines: 12,
                                maxLines: 16,
                                decoration: InputDecoration(
                                  labelText: 'Contenuto ${entry.key.toUpperCase()}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final version = _version.text.trim();
                final title = _title.text.trim();
                final content = {
                  for (final entry in _content.entries)
                    entry.key: entry.value.text.trim(),
                };
                if (version.isEmpty ||
                    title.isEmpty ||
                    content.values.any((value) => value.isEmpty)) {
                  setState(() {
                    _error =
                        'Versione, titolo e contenuti IT/EN/FR/DE sono obbligatori.';
                  });
                  return;
                }
                await _repo.publishLegal(
                  id: widget.id,
                  version: version,
                  title: title,
                  content: content,
                );
                if (context.mounted) {
                  setState(() => _error = null);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Versione pubblicata')));
                }
              },
              child: const Text('Pubblica nuova versione'),
            ),
            const SizedBox(height: 20),
            const Text('Storico versioni', style: TextStyle(fontWeight: FontWeight.bold)),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _repo.legalVersions(widget.id),
              builder: (_, versions) {
                final docs = versions.data?.docs ?? [];
                if (versions.hasError) return Text('${versions.error}');
                return Column(
                  children: docs.map((doc) {
                    final value = doc.data();
                    return Card(
                      child: ExpansionTile(
                        title: Text('${value['version'] ?? doc.id} · ${value['title'] ?? ''}'),
                        subtitle: Text(_date(value['publishedAt'])),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: SelectableText(_safeJson(value['content'])),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class OutfitCouponsPage extends StatefulWidget {
  const OutfitCouponsPage({super.key});

  @override
  State<OutfitCouponsPage> createState() => _OutfitCouponsPageState();
}

class _OutfitCouponsPageState extends State<OutfitCouponsPage> {
  final _repo = const OutfitRepository();

  Future<void> _edit([QueryDocumentSnapshot<Map<String, dynamic>>? doc]) async {
    final data = doc?.data() ?? {};
    final code = TextEditingController(text: doc?.id ?? '');
    final label = TextEditingController(text: '${data['label'] ?? ''}');
    final maxUses = TextEditingController(text: '${data['maxUses'] ?? ''}');
    var tier = '${data['tier'] ?? data['plan'] ?? 'plus'}';
    if (!const ['plus', 'pro'].contains(tier)) tier = 'plus';
    var active = (data['active'] ?? data['enabled']) == true;
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(doc == null ? 'Nuovo coupon' : 'Modifica coupon'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: code, enabled: doc == null, decoration: const InputDecoration(labelText: 'Codice')),
                TextField(controller: label, decoration: const InputDecoration(labelText: 'Nota')),
                TextField(controller: maxUses, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Utilizzi massimi')),
                DropdownButtonFormField<String>(
                  initialValue: tier,
                  items: const ['plus', 'pro']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => tier = value ?? 'plus'),
                  decoration: const InputDecoration(labelText: 'Piano'),
                ),
                SwitchListTile(
                  value: active,
                  onChanged: (value) => setDialogState(() => active = value),
                  title: const Text('Attivo'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salva')),
          ],
        ),
      ),
    );
    if (save == true && code.text.trim().isNotEmpty) {
      await _repo.saveCoupon(code.text, {
        'active': active,
        'type': 'reset_limits',
        'tier': tier,
        'label': label.text.trim(),
        'maxUses': int.tryParse(maxUses.text),
        'usedCount': data['usedCount'] ?? 0,
        if (doc == null) 'createdAt': FieldValue.serverTimestamp(),
        if (doc == null) 'createdBy': _repo.adminUid,
      });
    }
    code.dispose();
    label.dispose();
    maxUses.dispose();
  }

  @override
  Widget build(BuildContext context) => OutfitAvailability(
        child: Column(
          children: [
            SectionHeader(
              title: 'Coupon Outfit',
              subtitle: 'Schema condiviso CreditCore · destinatario users',
              trailing: IconButton(onPressed: _edit, icon: const Icon(Icons.add_circle_outline)),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _repo.coupons(),
                builder: (_, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs.toList()..sort((a, b) => a.id.compareTo(b.id));
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: docs.map((doc) {
                      final data = doc.data();
                      return Card(
                        child: ListTile(
                          title: Text(doc.id),
                          subtitle: Text(
                            '${data['tier'] ?? data['plan'] ?? '—'} · users · '
                            '${data['usedCount'] ?? 0}/${data['maxUses'] ?? '∞'}',
                          ),
                          leading: Icon(
                            (data['active'] ?? data['enabled']) == true
                                ? Icons.check_circle
                                : Icons.pause_circle_outline,
                            color: (data['active'] ?? data['enabled']) == true
                                ? Colors.green
                                : Colors.grey,
                          ),
                          onTap: () => _edit(doc),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _confirmDelete(doc.id),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      );

  Future<void> _confirmDelete(String code) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare il coupon?'),
        content: Text('$code verrà eliminato definitivamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _repo.deleteCoupon(code);
  }
}

class OutfitPlansPage extends StatefulWidget {
  const OutfitPlansPage({super.key});

  @override
  State<OutfitPlansPage> createState() => _OutfitPlansPageState();
}

class _OutfitPlansPageState extends State<OutfitPlansPage> {
  final _repo = const OutfitRepository();
  final _controllers = <String, Map<String, TextEditingController>>{};
  bool _initialized = false;
  String? _error;

  @override
  void dispose() {
    for (final plan in _controllers.values) {
      for (final controller in plan.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _load(Map<String, dynamic>? remote) {
    for (final plan in _plans) {
      final defaults = _defaultPlanLimits[plan]!;
      final remotePlan = remote?[plan];
      final values = remotePlan is Map
          ? {...defaults, ...Map<String, dynamic>.from(remotePlan)}
          : defaults;
      _controllers[plan] = {
        for (final field in defaults.keys)
          field: TextEditingController(
            text: values[field] == null ? '' : '${values[field]}',
          ),
      };
    }
  }

  _PlanField _field(String name) =>
      _planFields.firstWhere((field) => field.name == name);

  Map<String, dynamic> _validatedPlans() {
    final result = <String, dynamic>{};
    for (final plan in _plans) {
      final values = <String, dynamic>{};
      for (final entry in _controllers[plan]!.entries) {
        final raw = entry.value.text.trim();
        switch (_field(entry.key).type) {
          case _PlanFieldType.nullableInt:
            if (raw.isEmpty) {
              if (_defaultPlanLimits[plan]![entry.key] != null) {
                throw FormatException('$plan.${entry.key}: valore obbligatorio');
              }
              values[entry.key] = null;
            } else {
              final parsed = int.tryParse(raw);
              if (parsed == null || parsed < 0) {
                throw FormatException('$plan.${entry.key}: intero >= 0 o vuoto');
              }
              values[entry.key] = parsed;
            }
            break;
          case _PlanFieldType.boolean:
            if (raw != 'true' && raw != 'false') {
              throw FormatException('$plan.${entry.key}: true o false');
            }
            values[entry.key] = raw == 'true';
            break;
          case _PlanFieldType.calendarScope:
            if (raw != 'today' && raw != 'full') {
              throw FormatException('$plan.${entry.key}: today o full');
            }
            values[entry.key] = raw;
            break;
        }
      }
      result[plan] = values;
    }
    return result;
  }

  void _restoreDefaults() {
    for (final plan in _plans) {
      for (final entry in _defaultPlanLimits[plan]!.entries) {
        _controllers[plan]![entry.key]!.text =
            entry.value == null ? '' : '${entry.value}';
      }
    }
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) => OutfitAvailability(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _repo.plans(),
          builder: (_, snapshot) {
            if (!_initialized && snapshot.hasData) {
              _initialized = true;
              final plans = snapshot.data!.data()?['plans'];
              _load(plans is Map<String, dynamic> ? plans : null);
            }
            if (!_initialized) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionHeader(
                  title: 'Piani Outfit',
                  subtitle: 'Limiti correnti Free, Plus e Pro · settings/moodfit_plan_limits',
                ),
                for (final plan in _plans)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final entry in _controllers[plan]!.entries)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _planField(
                                entry.key,
                                entry.value,
                                _field(entry.key).type,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    try {
                      await _repo.savePlans(_validatedPlans());
                      if (!mounted) return;
                      setState(() => _error = null);
                    } catch (error) {
                      if (!mounted) return;
                      setState(() => _error = 'JSON non valido: $error');
                    }
                  },
                  child: const Text('Salva piani'),
                ),
                OutlinedButton(
                  onPressed: _restoreDefaults,
                  child: const Text('Ripristina valori Outfit correnti'),
                ),
              ],
            );
          },
        ),
      );

  Widget _planField(
    String name,
    TextEditingController controller,
    _PlanFieldType type,
  ) {
    if (type == _PlanFieldType.boolean) {
      return DropdownButtonFormField<String>(
        initialValue: controller.text == 'true' ? 'true' : 'false',
        decoration: InputDecoration(labelText: name),
        items: const [
          DropdownMenuItem(value: 'true', child: Text('true')),
          DropdownMenuItem(value: 'false', child: Text('false')),
        ],
        onChanged: (value) => controller.text = value ?? 'false',
      );
    }
    if (type == _PlanFieldType.calendarScope) {
      return DropdownButtonFormField<String>(
        initialValue: controller.text == 'full' ? 'full' : 'today',
        decoration: InputDecoration(labelText: name),
        items: const [
          DropdownMenuItem(value: 'today', child: Text('today')),
          DropdownMenuItem(value: 'full', child: Text('full')),
        ],
        onChanged: (value) => controller.text = value ?? 'today',
      );
    }
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: name,
        helperText: 'Intero >= 0; vuoto = null/illimitato',
      ),
    );
  }
}

class OutfitPromptsPage extends StatelessWidget {
  const OutfitPromptsPage({super.key});

  static const prompts = [
    (
      'moodfit_prompt_outfit_generation',
      'Generazione outfit',
      'You are MOODFIT, a professional fashion stylist AI. '
          'Pick a coherent outfit ONLY from the provided wardrobe item ids. '
          'Reply with JSON only: '
          '{"pieceIds":["id1","id2"],"title":"","description":"","suggestion":"","advice":""}. '
          'description = short look summary joining the chosen pieces. '
          'suggestion = one stylish sentence for the user. '
          'advice = optional short weather/style tip, or empty string. '
          'Write title, description, suggestion and advice in {{language}}.',
    ),
    (
      'moodfit_prompt_outfit_copy',
      'Copy outfit',
      'You are MOODFIT, a professional fashion stylist AI. '
          'Given a fixed outfit, write polished copy. JSON only: '
          '{"title":"","description":"","suggestion":"","advice":""}. '
          'Write all text fields in {{language}}.',
    ),
    (
      'moodfit_prompt_vision',
      'Vision',
      'Classify a clothing item from a photo. Reply with JSON only: '
          '{"category":"","color":""}. category must be one of: {{categories}}. '
          'color in {{colorLanguage}}, lowercase, using labels similar to: '
          '{{paletteLabels}}.',
    ),
  ];

  @override
  Widget build(BuildContext context) => OutfitAvailability(
        child: DefaultTabController(
          length: prompts.length,
          child: Column(
            children: [
              const SectionHeader(
                title: 'Prompt AI Outfit',
                subtitle: 'Prompt versionati, autore e ripristino predefiniti',
              ),
              TabBar(isScrollable: true, tabs: prompts.map((p) => Tab(text: p.$2)).toList()),
              Expanded(
                child: TabBarView(
                  children: prompts.map((p) => _PromptEditor(id: p.$1, defaultPrompt: p.$3)).toList(),
                ),
              ),
            ],
          ),
        ),
      );
}

class _PromptEditor extends StatefulWidget {
  const _PromptEditor({required this.id, required this.defaultPrompt});
  final String id;
  final String defaultPrompt;

  @override
  State<_PromptEditor> createState() => _PromptEditorState();
}

class _PromptEditorState extends State<_PromptEditor> {
  final _repo = const OutfitRepository();
  final _controller = TextEditingController();
  bool _initialized = false;
  int _version = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _repo.prompt(widget.id),
      builder: (_, snapshot) {
        final data = snapshot.data?.data() ?? {};
        if (!_initialized && snapshot.hasData) {
          _initialized = true;
          _controller.text = '${data['prompt'] ?? widget.defaultPrompt}';
          final version = data['version'];
          _version = version is num
              ? version.toInt()
              : int.tryParse('$version') ?? 0;
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Documento: settings/${widget.id}'),
            Text('Versione: $_version · aggiornato: ${_date(data['updatedAt'])}'),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              minLines: 14,
              maxLines: 28,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Prompt'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                await _repo.savePrompt(id: widget.id, prompt: _controller.text, version: _version + 1);
                if (mounted) setState(() => _version++);
              },
              child: const Text('Salva nuova versione'),
            ),
            OutlinedButton(
              onPressed: () {
                setState(() => _controller.text = widget.defaultPrompt);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Default ripristinato nell’editor. Premi Salva per pubblicarlo.',
                    ),
                  ),
                );
              },
              child: const Text('Ripristina predefinito'),
            ),
          ],
        );
      },
    );
  }
}

String _date(dynamic value) {
  if (value is Timestamp) return DateFormat('dd/MM/yyyy HH:mm').format(value.toDate());
  return '—';
}
