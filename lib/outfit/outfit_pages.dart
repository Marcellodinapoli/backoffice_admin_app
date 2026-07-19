import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../shared/widgets/section_header.dart';
import '../widgets/admin_subpage_scaffold.dart';
import 'outfit_coupon_admin_service.dart';
import 'outfit_coupon_edit_dialog.dart';
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
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      '${data['displayName'] ?? data['name'] ?? ''}'
                          .toLowerCase()
                          .contains(query) ||
                      '${data['firstName'] ?? ''}'.toLowerCase().contains(query) ||
                      '${data['lastName'] ?? ''}'.toLowerCase().contains(query) ||
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
                    final name = _outfitUserName(data);
                    final status =
                        '${data['accountStatus'] ?? data['status'] ?? 'active'}';
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(name.isEmpty ? '?' : name[0].toUpperCase())),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${data['email'] ?? doc.id}'),
                            Text('${data['subscriptionPlan'] ?? 'free'} · $status'),
                            Text('Registrato: ${_registrationDate(data)}'),
                          ],
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

  @override
  Widget build(BuildContext context) {
    return AdminSubPageScaffold(
      title: 'Utente Outfit',
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _repo.user(widget.uid),
        builder: (_, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data();
          if (data == null) return const Center(child: Text('Utente non trovato'));
          final status = '${data['accountStatus'] ?? data['status'] ?? 'active'}';
          final rawLegal = data['legalConsent'];
          final legal = rawLegal is Map
              ? Map<String, dynamic>.from(rawLegal)
              : <String, dynamic>{};
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _outfitUserName(data),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text('${data['email'] ?? '—'}'),
                      const Divider(),
                      _row('UID', widget.uid),
                      _row('Registrato', _registrationDate(data)),
                      _row('Stato', status),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: OutfitFirebase.firestore!
                            .collection('users')
                            .doc(widget.uid)
                            .collection('private')
                            .doc('main')
                            .snapshots(),
                        builder: (_, privateSnap) {
                          final private = privateSnap.data?.data() ?? const <String, dynamic>{};
                          final plan = _outfitPlanLabel(
                            private['subscriptionTier'] ??
                                data['subscriptionTier'] ??
                                data['subscriptionPlan'],
                          );
                          final coupon = (private['couponCode'] ?? data['couponCode'])
                              ?.toString()
                              .trim();
                          final appliedAt =
                              private['couponAppliedAt'] ?? data['couponAppliedAt'];
                          final expiresAt = private['subscriptionExpiresAt'] ??
                              data['subscriptionExpiresAt'];
                          final lifetime = private['lifetimeAccess'] == true ||
                              data['lifetimeAccess'] == true;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _row('Piano', plan),
                              if (coupon != null && coupon.isNotEmpty) ...[
                                _row('Coupon', coupon),
                                _row('Inserito', _outfitFormatDate(appliedAt)),
                                _row(
                                  'Effetto limiti',
                                  lifetime
                                      ? 'Senza scadenza'
                                      : 'Fino al ${_outfitFormatDate(expiresAt)}',
                                ),
                              ] else
                                _row('Coupon', '—'),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _repo.setUserStatus(
                  widget.uid,
                  status == 'blocked' ? 'active' : 'blocked',
                ),
                icon: Icon(status == 'blocked' ? Icons.check_circle : Icons.block),
                label: Text(status == 'blocked' ? 'Riattiva' : 'Blocca'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Utilizzo mensile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _repo.usage(widget.uid),
                builder: (_, usageSnapshot) {
                  final u = usageSnapshot.data?.data();
                  if (u == null || u.isEmpty) {
                    return const Card(
                      child: ListTile(title: Text('Nessun utilizzo registrato.')),
                    );
                  }
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (u['monthKey'] != null) Text('Mese: ${u['monthKey']}'),
                          Text('Analisi AI: ${u['aiAnalyze'] ?? 0}'),
                          Text('Shopping check: ${u['shoppingCheck'] ?? 0}'),
                          Text('Viaggi: ${u['trips'] ?? 0}'),
                          Text(
                            'Rigenerazioni outfit oggi: ${u['outfitRegenerationsToday'] ?? 0}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Storico consensi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: _outfitConsentTiles(legal),
                  ),
                ),
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
            SizedBox(
              width: 110,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(child: SelectableText(value)),
          ],
        ),
      );
}

class OutfitPrivacyPage extends StatelessWidget {
  const OutfitPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) => const OutfitAvailability(
        child: SafeArea(
          top: false,
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
  final _codeCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  final _maxUsesCtrl = TextEditingController();
  DateTime? _expiresAt;
  DateTime? _benefitExpiresAt;
  String? _restrictedPlan;
  bool _saving = false;
  String? _formError;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _labelCtrl.dispose();
    _maxUsesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      helpText: 'Ultimo giorno per inserire il codice (opzionale)',
    );
    if (date == null || !mounted) return;
    setState(() => _expiresAt = date);
  }

  Future<void> _pickBenefitExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _benefitExpiresAt ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
      helpText: 'Scadenza effetto piano/limiti *',
    );
    if (date == null || !mounted) return;
    setState(() => _benefitExpiresAt = date);
  }

  Future<void> _createCoupon() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _formError = 'Inserisci il codice coupon.');
      return;
    }

    int? maxUses;
    final maxRaw = _maxUsesCtrl.text.trim();
    if (maxRaw.isNotEmpty) {
      maxUses = int.tryParse(maxRaw);
      if (maxUses == null || maxUses < 1) {
        setState(() => _formError = 'Utilizzi massimi non valido.');
        return;
      }
    }

    if (_benefitExpiresAt == null) {
      setState(() => _formError = 'Inserisci la scadenza effetto piano/limiti.');
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    try {
      await OutfitCouponAdminService.createCoupon(
        code: code,
        label: _labelCtrl.text.trim(),
        maxUses: maxUses,
        expiresAt: _expiresAt,
        benefitExpiresAt: _benefitExpiresAt!,
        restrictedPlan: _restrictedPlan,
      );
      if (!mounted) return;
      _codeCtrl.clear();
      _labelCtrl.clear();
      _maxUsesCtrl.clear();
      setState(() {
        _expiresAt = null;
        _benefitExpiresAt = null;
        _restrictedPlan = null;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coupon ${OutfitCouponAdminService.normalizeCode(code)} creato.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = e
            .toString()
            .replaceFirst('StateError: ', '')
            .replaceFirst('ArgumentError: ', '');
      });
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) => OutfitAvailability(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const SectionHeader(
                title: 'Coupon Outfit',
                subtitle:
                    'Codici per azzerare limiti e attivare il piano · solo utenti',
              ),
              const SizedBox(height: 12),
              _buildCreateCard(),
              const SizedBox(height: 24),
              const Text(
                'Coupon esistenti',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _buildList(),
            ],
          ),
        ),
      );

  Widget _buildCreateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nuovo coupon',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Codice coupon *',
                hintText: 'Es. PROMO2026',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Nota interna (opzionale)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _maxUsesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Utilizzi massimi (vuoto = illimitati)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              value: _restrictedPlan,
              decoration: const InputDecoration(
                labelText: 'Piano vincolato',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Qualsiasi piano')),
                DropdownMenuItem(value: 'free', child: Text('Solo Gratis')),
                DropdownMenuItem(value: 'plus', child: Text('Solo Plus')),
                DropdownMenuItem(value: 'pro', child: Text('Solo Pro')),
              ],
              onChanged: (v) => setState(() => _restrictedPlan = v),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickBenefitExpiry,
              icon: const Icon(Icons.event_available_outlined, size: 18),
              label: Text(
                _benefitExpiresAt == null
                    ? 'Scadenza effetto piano/limiti *'
                    : 'Effetto fino al: ${_formatDate(_benefitExpiresAt!)}',
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickExpiry,
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(
                _expiresAt == null
                    ? 'Scadenza utilizzo codice (opzionale)'
                    : 'Codice utilizzabile fino al: ${_formatDate(_expiresAt!)}',
              ),
            ),
            if (_expiresAt != null)
              TextButton(
                onPressed: () => setState(() => _expiresAt = null),
                child: const Text('Rimuovi scadenza utilizzo codice'),
              ),
            if (_benefitExpiresAt != null)
              TextButton(
                onPressed: () => setState(() => _benefitExpiresAt = null),
                child: const Text('Rimuovi scadenza effetto'),
              ),
            if (_formError != null) ...[
              const SizedBox(height: 8),
              Text(
                _formError!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _createCoupon,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crea coupon'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<OutfitCouponRecord>>(
      stream: OutfitCouponAdminService.watchCoupons(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Text(
            'Errore: ${snap.error}',
            style: TextStyle(color: Colors.red.shade700),
          );
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Text(
            'Nessun coupon ancora creato.',
            style: TextStyle(color: AppColors.textSecondary),
          );
        }
        return Column(
          children: [
            for (final c in items) ...[
              _OutfitCouponTile(
                record: c,
                onToggle: (enabled) => OutfitCouponAdminService.setEnabled(
                  code: c.code,
                  enabled: enabled,
                ),
                onEdit: () async {
                  final saved = await OutfitCouponEditDialog.show(context, c);
                  if (saved == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Coupon ${c.code} aggiornato.')),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

class _OutfitCouponTile extends StatelessWidget {
  final OutfitCouponRecord record;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const _OutfitCouponTile({
    required this.record,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final status = !record.enabled
        ? 'Disattivato'
        : record.expired
            ? 'Scaduto'
            : record.exhausted
                ? 'Esaurito'
                : 'Attivo';
    final statusColor = status == 'Scaduto'
        ? Colors.red
        : status == 'Attivo'
            ? Colors.green
            : AppColors.textSecondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    record.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Switch(value: record.enabled, onChanged: onToggle),
                IconButton(
                  tooltip: 'Modifica',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
              ],
            ),
            Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (record.createdAt != null)
              Text('Creato il: ${_formatDate(record.createdAt!)}'),
            if (record.label != null) Text('Nota: ${record.label}'),
            Text(
              'Utilizzi: ${record.usedCount}'
              '${record.maxUses != null ? ' / ${record.maxUses}' : ''}',
            ),
            if (record.plan != null)
              Text('Piano: ${outfitCouponPlanLabel(record.plan)}'),
            if (record.benefitExpiresAt != null)
              Text(
                'Effetto fino al: ${_formatDate(record.benefitExpiresAt!)}',
              ),
            if (record.expiresAt != null)
              Text(
                'Codice utilizzabile fino al: ${_formatDate(record.expiresAt!)}',
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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
        child: SafeArea(
          top: false,
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
                const SizedBox(height: 24),
              ],
            );
          },
        ),
        ),
      );

  Widget _planField(
    String name,
    TextEditingController controller,
    _PlanFieldType type,
  ) {
    if (type == _PlanFieldType.boolean) {
      return DropdownButtonFormField<String>(
        value: controller.text == 'true' ? 'true' : 'false',
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
        value: controller.text == 'full' ? 'full' : 'today',
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
        child: SafeArea(
          top: false,
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

String _outfitPlanLabel(dynamic raw) {
  final plan = (raw ?? 'free').toString().trim().toLowerCase();
  if (plan == 'plus') return 'Plus';
  if (plan == 'pro' || plan == 'enterprise') return 'Pro';
  return 'Free';
}

String _outfitFormatDate(dynamic raw) {
  if (raw is Timestamp) {
    return DateFormat('dd/MM/yyyy').format(raw.toDate());
  }
  if (raw is String && raw.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return DateFormat('dd/MM/yyyy').format(parsed);
  }
  return '—';
}

List<Widget> _outfitConsentTiles(Map<String, dynamic> legal) {
  final tiles = <Widget>[];
  void add(String key, String description) {
    final raw = legal[key];
    if (raw is! Map) return;
    final entry = Map<String, dynamic>.from(raw);
    final version = '${entry['version'] ?? '—'}';
    final accepted = _outfitFormatDate(entry['acceptedAt'] ?? entry['readCompletedAt']);
    tiles.add(
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(description, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Versione $version · Accettato: $accepted'),
      ),
    );
  }

  add('privacy', 'Informativa privacy MOODFIT');
  add('terms', 'Termini e condizioni MOODFIT');
  if (tiles.isEmpty) {
    return const [ListTile(title: Text('Nessun consenso registrato.'))];
  }
  return tiles;
}

String _outfitUserName(Map<String, dynamic> data) {
  final direct = data['displayName'] ?? data['name'];
  if (direct != null && direct.toString().trim().isNotEmpty) {
    return direct.toString();
  }
  final parts = [data['firstName'], data['lastName']]
      .where((e) => e != null && e.toString().trim().isNotEmpty)
      .join(' ');
  return parts.isEmpty ? 'Utente' : parts;
}

String _registrationDate(Map<String, dynamic> data) {
  final raw = data['registeredAt'] ?? data['createdAt'];
  if (raw is Timestamp) {
    return DateFormat('dd/MM/yyyy').format(raw.toDate());
  }
  if (raw is String && raw.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return DateFormat('dd/MM/yyyy').format(parsed);
    return raw;
  }
  return '—';
}

String _date(dynamic value) {
  if (value is Timestamp) return DateFormat('dd/MM/yyyy HH:mm').format(value.toDate());
  return '—';
}
