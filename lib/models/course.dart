import 'package:cloud_firestore/cloud_firestore.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? videoUrl;
  final List<String> tags;
  final List<String> contents;
  final List<Map<String, dynamic>> attachments;
  final Map<String, dynamic>? quiz;
  final Timestamp? createdAt;

  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.videoUrl,
    this.tags = const [],
    this.contents = const [],
    this.attachments = const [],
    this.quiz,
    this.createdAt,
  });

  factory Course.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawAttachments = data['attachments'] as List? ?? [];
    final attachments = rawAttachments.map((e) {
      if (e is Map) {
        return Map<String, dynamic>.from(e);
      }
      return {'name': e.toString(), 'url': e.toString()};
    }).toList();

    return Course(
      id: doc.id,
      title: data['title']?.toString() ?? 'Senza titolo',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Sollecito',
      videoUrl: data['videoUrl']?.toString(),
      tags: (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      contents:
          (data['contents'] as List?)?.map((e) => e.toString()).toList() ?? [],
      attachments: attachments,
      quiz: data['quiz'] as Map<String, dynamic>?,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  bool get hasQuiz =>
      quiz != null && (quiz!['fileName'] != null || quiz!['questions'] != null);

  int get attachmentCount => attachments.length;
}
