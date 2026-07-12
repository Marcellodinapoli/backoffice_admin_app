import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/bk_local_storage.dart';
import 'admin_menu_badge_notifier.dart';

/// Ascolta aggiornamenti utente su support/community/warm-up/job e aggiorna i badge.
final class AdminMenuBadgeController {
  AdminMenuBadgeController._();

  static final AdminMenuBadgeController instance = AdminMenuBadgeController._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _notifier = AdminMenuBadgeNotifier.instance;

  StreamSubscription<User?>? _authSub;
  final _subs = <StreamSubscription<dynamic>>[];
  final _messageSubs =
      <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};

  final Map<String, QuerySnapshot<Map<String, dynamic>>> _supportMessages = {};
  final Map<String, QuerySnapshot<Map<String, dynamic>>> _communityMessages = {};
  QuerySnapshot<Map<String, dynamic>>? _supportTicketsSnap;
  QuerySnapshot<Map<String, dynamic>>? _communityTopicsSnap;
  QuerySnapshot<Map<String, dynamic>>? _warmupPendingSnap;
  QuerySnapshot<Map<String, dynamic>>? _jobOffersSnap;

  Timer? _recomputeTimer;
  String? _adminUid;
  int _firestoreSupportSeen = 0;
  int _firestoreCommunitySeen = 0;
  int _firestoreWarmupSeen = 0;
  int _firestoreCreditJobSeen = 0;
  bool _seenLoaded = false;

  void start() {
    if (_authSub != null) return;

    _authSub = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        _stopDataListeners();
        _notifier.badges.value = const AdminMenuBadges();
        return;
      }
      if (_adminUid == user.uid && _seenLoaded) return;
      _stopDataListeners();
      _adminUid = user.uid;
      _seenLoaded = false;
      await _loadSeenFromFirestore(user.uid);
      _seenLoaded = true;
      _attachListeners();
    });
  }

  void stop() {
    unawaited(_authSub?.cancel());
    _authSub = null;
    _stopDataListeners();
    _notifier.badges.value = const AdminMenuBadges();
  }

  static void markSupportVisited() {
    final now = DateTime.now().millisecondsSinceEpoch;
    bkLocalStorageSet('lastSeenSupport', now.toString());
    instance._firestoreSupportSeen = now;
    instance._persistSeen(supportMs: now);
    instance.scheduleRefresh();
  }

  static void markCommunityVisited() {
    final now = DateTime.now().millisecondsSinceEpoch;
    bkLocalStorageSet('lastSeenCommunity', now.toString());
    bkLocalStorageSet('lastSeen', now.toString());
    instance._firestoreCommunitySeen = now;
    instance._persistSeen(communityMs: now);
    instance.scheduleRefresh();
  }

  static void markWarmupVisited() {
    final now = DateTime.now().millisecondsSinceEpoch;
    bkLocalStorageSet('lastSeenWarmup', now.toString());
    instance._firestoreWarmupSeen = now;
    instance._persistSeen(warmupMs: now);
    instance.scheduleRefresh();
  }

  static void markCreditJobVisited() {
    final now = DateTime.now().millisecondsSinceEpoch;
    bkLocalStorageSet('lastSeenCreditJob', now.toString());
    instance._firestoreCreditJobSeen = now;
    instance._persistSeen(creditJobMs: now);
    instance.scheduleRefresh();
  }

  void scheduleRefresh() => _scheduleRecompute();

  Future<void> _loadSeenFromFirestore(String uid) async {
    try {
      final snap = await _firestore.collection('users').doc(uid).get();
      final data = snap.data();
      _firestoreSupportSeen = _timestampToMs(data?['adminLastSeenSupport']);
      final community = _timestampToMs(data?['adminLastSeenCommunity']);
      final topics = _timestampToMs(data?['adminLastSeen']);
      _firestoreCommunitySeen = max(community, topics);
      _firestoreWarmupSeen = _timestampToMs(data?['adminLastSeenWarmup']);
      _firestoreCreditJobSeen = _timestampToMs(data?['adminLastSeenCreditJob']);

      final localSupport =
          int.tryParse(bkLocalStorageGet('lastSeenSupport') ?? '') ?? 0;
      final localCommunity = max(
        int.tryParse(bkLocalStorageGet('lastSeenCommunity') ?? '') ?? 0,
        int.tryParse(bkLocalStorageGet('lastSeen') ?? '') ?? 0,
      );
      final localWarmup =
          int.tryParse(bkLocalStorageGet('lastSeenWarmup') ?? '') ?? 0;
      final localCreditJob =
          int.tryParse(bkLocalStorageGet('lastSeenCreditJob') ?? '') ?? 0;

      if (_firestoreSupportSeen <= 0 && localSupport > 0) {
        _firestoreSupportSeen = localSupport;
        unawaited(_persistSeen(supportMs: localSupport));
      }
      if (_firestoreCommunitySeen <= 0 && localCommunity > 0) {
        _firestoreCommunitySeen = localCommunity;
        unawaited(_persistSeen(communityMs: localCommunity));
      }
      if (_firestoreWarmupSeen <= 0 && localWarmup > 0) {
        _firestoreWarmupSeen = localWarmup;
        unawaited(_persistSeen(warmupMs: localWarmup));
      }
      if (_firestoreCreditJobSeen <= 0 && localCreditJob > 0) {
        _firestoreCreditJobSeen = localCreditJob;
        unawaited(_persistSeen(creditJobMs: localCreditJob));
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      if (_firestoreSupportSeen <= 0) {
        _firestoreSupportSeen = now;
        bkLocalStorageSet('lastSeenSupport', now.toString());
        unawaited(_persistSeen(supportMs: now));
      }
      if (_firestoreCommunitySeen <= 0) {
        _firestoreCommunitySeen = now;
        bkLocalStorageSet('lastSeenCommunity', now.toString());
        bkLocalStorageSet('lastSeen', now.toString());
        unawaited(_persistSeen(communityMs: now));
      }
      if (_firestoreCreditJobSeen <= 0) {
        _firestoreCreditJobSeen = now;
        bkLocalStorageSet('lastSeenCreditJob', now.toString());
        unawaited(_persistSeen(creditJobMs: now));
      }
    } catch (_) {}
    _scheduleRecompute();
  }

  Future<void> _persistSeen({
    int? supportMs,
    int? communityMs,
    int? warmupMs,
    int? creditJobMs,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final patch = <String, dynamic>{};
    if (supportMs != null) {
      patch['adminLastSeenSupport'] =
          Timestamp.fromMillisecondsSinceEpoch(supportMs);
    }
    if (communityMs != null) {
      patch['adminLastSeenCommunity'] =
          Timestamp.fromMillisecondsSinceEpoch(communityMs);
      patch['adminLastSeen'] =
          Timestamp.fromMillisecondsSinceEpoch(communityMs);
    }
    if (warmupMs != null) {
      patch['adminLastSeenWarmup'] =
          Timestamp.fromMillisecondsSinceEpoch(warmupMs);
    }
    if (creditJobMs != null) {
      patch['adminLastSeenCreditJob'] =
          Timestamp.fromMillisecondsSinceEpoch(creditJobMs);
    }
    if (patch.isEmpty) return;

    try {
      await _firestore.collection('users').doc(uid).set(
            patch,
            SetOptions(merge: true),
          );
    } catch (_) {}
  }

  void _stopDataListeners() {
    _recomputeTimer?.cancel();
    _recomputeTimer = null;
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    _subs.clear();
    for (final sub in _messageSubs.values) {
      unawaited(sub.cancel());
    }
    _messageSubs.clear();
    _adminUid = null;
    _firestoreSupportSeen = 0;
    _firestoreCommunitySeen = 0;
    _firestoreWarmupSeen = 0;
    _firestoreCreditJobSeen = 0;
    _seenLoaded = false;
    _supportMessages.clear();
    _communityMessages.clear();
    _supportTicketsSnap = null;
    _communityTopicsSnap = null;
    _warmupPendingSnap = null;
    _jobOffersSnap = null;
  }

  void _attachListeners() {
    _subs.add(
      _firestore.collection('support').snapshots().listen((snap) {
        _supportTicketsSnap = snap;
        _syncChildListeners(
          currentIds: snap.docs.map((doc) => doc.id).toSet(),
          prefix: 'support:',
          attach: (ticketId) {
            _messageSubs['support:$ticketId'] = _firestore
                .collection('support')
                .doc(ticketId)
                .collection('messages')
                .snapshots(includeMetadataChanges: true)
                .listen((messages) {
              _supportMessages[ticketId] = messages;
              _scheduleRecompute();
            });
          },
          onRemove: (ticketId) => _supportMessages.remove(ticketId),
        );
        _scheduleRecompute();
      }),
    );

    _subs.add(
      _firestore.collection('community').snapshots().listen((snap) {
        _communityTopicsSnap = snap;
        _syncChildListeners(
          currentIds: snap.docs.map((doc) => doc.id).toSet(),
          prefix: 'community:',
          attach: (topicId) {
            _messageSubs['community:$topicId'] = _firestore
                .collection('community')
                .doc(topicId)
                .collection('messages')
                .snapshots(includeMetadataChanges: true)
                .listen((messages) {
              _communityMessages[topicId] = messages;
              _scheduleRecompute();
            });
          },
          onRemove: (topicId) => _communityMessages.remove(topicId),
        );
        _scheduleRecompute();
      }),
    );

    _subs.add(
      _firestore
          .collection('warmup_contestations')
          .where('status', isEqualTo: 'pending_review')
          .snapshots()
          .listen((snap) {
        _warmupPendingSnap = snap;
        _scheduleRecompute();
      }),
    );

    _subs.add(
      _firestore.collection('job_offers').snapshots().listen((snap) {
        _jobOffersSnap = snap;
        _scheduleRecompute();
      }),
    );
  }

  void _syncChildListeners({
    required Set<String> currentIds,
    required String prefix,
    required void Function(String id) attach,
    required void Function(String id) onRemove,
  }) {
    final stale = _messageSubs.keys
        .where((key) =>
            key.startsWith(prefix) &&
            !currentIds.contains(key.substring(prefix.length)))
        .toList();
    for (final key in stale) {
      unawaited(_messageSubs.remove(key)?.cancel());
      onRemove(key.substring(prefix.length));
    }

    for (final id in currentIds) {
      final key = '$prefix$id';
      if (_messageSubs.containsKey(key)) continue;
      attach(id);
    }
  }

  void _scheduleRecompute() {
    _recomputeTimer?.cancel();
    _recomputeTimer = Timer(const Duration(milliseconds: 120), _recompute);
  }

  void _recompute() {
    if (_adminUid == null || !_seenLoaded) {
      _notifier.badges.value = const AdminMenuBadges();
      return;
    }

    _notifier.badges.value = AdminMenuBadges(
      community: _hasCommunityUnread(_adminUid!),
      support: _hasSupportUnread(),
      warmup: _hasWarmupUnread(),
      creditJob: _hasCreditJobUnread(),
    );
  }

  bool _hasSupportUnread() {
    final lastSeen = _readLastSeenSupportMs();
    if (lastSeen <= 0) return false;

    for (final messages in _supportMessages.values) {
      for (final doc in messages.docs) {
        final data = doc.data();
        if (data['sender'] != 'user') continue;
        final millis = _docMillis(data['timestamp']);
        if (millis == null) continue;
        if (millis > lastSeen) return true;
      }
    }

    final tickets = _supportTicketsSnap?.docs ?? const [];
    for (final doc in tickets) {
      final data = doc.data();
      final millis = _docMillis(data['createdAt']);
      if (millis == null) continue;
      if (millis > lastSeen) return true;
    }
    return false;
  }

  bool _hasCommunityUnread(String adminUid) {
    final lastSeen = _readLastSeenCommunityMs();
    if (lastSeen <= 0) return false;

    for (final messages in _communityMessages.values) {
      for (final doc in messages.docs) {
        final data = doc.data();
        final authorUid = (data['userId'] ?? '').toString();
        if (authorUid.isEmpty || authorUid == adminUid) continue;
        final millis = _docMillis(data['timestamp']);
        if (millis == null) continue;
        if (millis > lastSeen) return true;
      }
    }

    final topics = _communityTopicsSnap?.docs ?? const [];
    for (final doc in topics) {
      final data = doc.data();
      final authorUid = (data['userId'] ?? '').toString();
      if (authorUid.isEmpty || authorUid == adminUid) continue;
      final millis = _docMillis(data['createdAt']);
      if (millis == null) continue;
      if (millis > lastSeen) return true;
    }
    return false;
  }

  bool _hasWarmupUnread() {
    final lastSeen = _readLastSeenWarmupMs();
    final docs = _warmupPendingSnap?.docs ?? const [];
    if (docs.isEmpty) return false;
    if (lastSeen <= 0) return true;

    for (final doc in docs) {
      final millis = _docMillis(doc.data()['createdAt']);
      if (millis == null) continue;
      if (millis > lastSeen) return true;
    }
    return false;
  }

  bool _hasCreditJobUnread() {
    final lastSeen = _readLastSeenCreditJobMs();
    if (lastSeen <= 0) return false;

    final docs = _jobOffersSnap?.docs ?? const [];
    for (final doc in docs) {
      final data = doc.data();
      if ((data['status'] ?? 'pending').toString() != 'pending') continue;
      final millis = _docMillis(data['createdAt']);
      if (millis == null) continue;
      if (millis > lastSeen) return true;
    }
    return false;
  }

  int _readLastSeenSupportMs() {
    final local = int.tryParse(bkLocalStorageGet('lastSeenSupport') ?? '') ?? 0;
    return max(local, _firestoreSupportSeen);
  }

  int _readLastSeenCommunityMs() {
    final menuSeen =
        int.tryParse(bkLocalStorageGet('lastSeenCommunity') ?? '') ?? 0;
    final topicSeen = int.tryParse(bkLocalStorageGet('lastSeen') ?? '') ?? 0;
    final local = max(menuSeen, topicSeen);
    return max(local, _firestoreCommunitySeen);
  }

  int _readLastSeenWarmupMs() {
    final local = int.tryParse(bkLocalStorageGet('lastSeenWarmup') ?? '') ?? 0;
    return max(local, _firestoreWarmupSeen);
  }

  int _readLastSeenCreditJobMs() {
    final local =
        int.tryParse(bkLocalStorageGet('lastSeenCreditJob') ?? '') ?? 0;
    return max(local, _firestoreCreditJobSeen);
  }

  int _timestampToMs(dynamic raw) {
    if (raw is Timestamp) return raw.millisecondsSinceEpoch;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return 0;
  }

  int? _docMillis(dynamic raw) {
    if (raw is Timestamp) return raw.millisecondsSinceEpoch;
    if (raw is String) return DateTime.tryParse(raw)?.millisecondsSinceEpoch;
    return null;
  }
}
