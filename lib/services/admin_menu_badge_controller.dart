import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/bk_local_storage.dart';
import 'admin_menu_badge_notifier.dart';

/// Ascolta messaggi utente su support/community e aggiorna i badge del drawer.
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

  Timer? _recomputeTimer;
  String? _adminUid;
  int _firestoreSupportSeen = 0;
  int _firestoreCommunitySeen = 0;

  void start() {
    if (_authSub != null) return;

    _authSub = _auth.authStateChanges().listen((user) {
      if (user == null) {
        _stopDataListeners();
        _notifier.badges.value = const AdminMenuBadges();
        return;
      }
      if (_adminUid == user.uid) return;
      _stopDataListeners();
      _adminUid = user.uid;
      _loadSeenFromFirestore(user.uid);
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      unawaited(
        FirebaseFirestore.instance.collection('users').doc(uid).set({
          'adminLastSeenSupport': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );
      instance._firestoreSupportSeen = now;
    }
    instance.scheduleRefresh();
  }

  static void markCommunityVisited() {
    final now = DateTime.now().millisecondsSinceEpoch;
    bkLocalStorageSet('lastSeenCommunity', now.toString());
    bkLocalStorageSet('lastSeen', now.toString());
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      unawaited(
        FirebaseFirestore.instance.collection('users').doc(uid).set({
          'adminLastSeenCommunity': FieldValue.serverTimestamp(),
          'adminLastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );
      instance._firestoreCommunitySeen = now;
    }
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
      _scheduleRecompute();
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
    _supportMessages.clear();
    _communityMessages.clear();
  }

  void _attachListeners() {
    _subs.add(
      _firestore.collection('support').snapshots().listen((snap) {
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
    if (_adminUid == null) {
      _notifier.badges.value = const AdminMenuBadges();
      return;
    }

    _notifier.badges.value = AdminMenuBadges(
      community: _hasCommunityUnread(_adminUid!),
      support: _hasSupportUnread(),
    );
  }

  bool _hasSupportUnread() {
    final lastSeen = _readLastSeenSupportMs();
    for (final messages in _supportMessages.values) {
      for (final doc in messages.docs) {
        final data = doc.data();
        if (data['sender'] != 'user') continue;
        final millis = _docMillis(data['timestamp']);
        if (millis == null) continue;
        if (lastSeen <= 0 || millis > lastSeen) return true;
      }
    }
    return false;
  }

  bool _hasCommunityUnread(String adminUid) {
    final lastSeen = _readLastSeenCommunityMs();

    for (final messages in _communityMessages.values) {
      for (final doc in messages.docs) {
        final data = doc.data();
        final authorUid = (data['userId'] ?? '').toString();
        if (authorUid.isEmpty || authorUid == adminUid) continue;
        final millis = _docMillis(data['timestamp']);
        if (millis == null) continue;
        if (lastSeen <= 0 || millis > lastSeen) return true;
      }
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
