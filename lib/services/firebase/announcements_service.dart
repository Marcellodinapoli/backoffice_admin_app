import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../../models/announcement.dart';
import 'firestore_service.dart';

class AnnouncementsService {
  AnnouncementsService._();

  static final AnnouncementsService instance = AnnouncementsService._();
  final _fs = FirestoreService.instance;

  Stream<List<Announcement>> watchAll() {
    return _fs
        .collection(FirestoreCollections.announcements)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Announcement.fromFirestore(d)).toList());
  }

  Future<void> toggleActive(String id, bool current) {
    return _fs.doc(FirestoreCollections.announcements, id).update({
      'active': !current,
    });
  }

  Future<void> deleteAnnouncement(String id) {
    return _fs.doc(FirestoreCollections.announcements, id).delete();
  }

  Future<int> countTargetUsers(String target) async {
    final usersRef = _fs.collection(FirestoreCollections.users);
    if (target == 'all') {
      return (await usersRef.count().get()).count ?? 0;
    }
    return (await usersRef.where('type', isEqualTo: target).count().get())
            .count ??
        0;
  }

  Future<void> createAnnouncement({
    required String title,
    required String message,
    required String target,
    required String type,
    required bool active,
    DateTime? expiresAt,
    required int targetCount,
  }) {
    return _fs.collection(FirestoreCollections.announcements).add({
      'title': title,
      'message': message,
      'target': target,
      'type': type,
      'active': active,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      'targetCount': targetCount,
      'seenCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String message,
    required String target,
    required String type,
    required bool active,
    DateTime? expiresAt,
    required int targetCount,
    int seenCount = 0,
    Timestamp? createdAt,
  }) {
    return _fs.doc(FirestoreCollections.announcements, id).update({
      'title': title,
      'message': message,
      'target': target,
      'type': type,
      'active': active,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      'targetCount': targetCount,
      'seenCount': seenCount,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    });
  }
}
