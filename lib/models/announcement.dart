import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String message;
  final String target;
  final String type;
  final bool active;
  final int targetCount;
  final int seenCount;
  final Timestamp? createdAt;
  final Timestamp? expiresAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.target,
    required this.type,
    required this.active,
    this.targetCount = 0,
    this.seenCount = 0,
    this.createdAt,
    this.expiresAt,
  });

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Announcement(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      target: data['target']?.toString() ?? 'all',
      type: data['type']?.toString() ?? 'avviso',
      active: data['active'] as bool? ?? true,
      targetCount: data['targetCount'] as int? ?? 0,
      seenCount: data['seenCount'] as int? ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
      expiresAt: data['expiresAt'] as Timestamp?,
    );
  }
}
