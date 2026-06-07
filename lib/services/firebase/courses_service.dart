import '../../core/constants/firestore_collections.dart';
import '../../models/course.dart';
import 'firestore_service.dart';

class CoursesService {
  CoursesService._();

  static final CoursesService instance = CoursesService._();
  final _fs = FirestoreService.instance;

  Stream<List<Course>> watchByCategory(String category) {
    final normalized = category.toLowerCase();

    return _fs.collection(FirestoreCollections.courses).snapshots().map((snap) {
      final courses = snap.docs.map((d) => Course.fromFirestore(d)).where(
        (course) => course.category.toLowerCase() == normalized,
      );

      final list = courses.toList()
        ..sort((a, b) {
          final aTs = a.createdAt;
          final bTs = b.createdAt;
          if (aTs == null && bTs == null) return 0;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });

      return list;
    });
  }

  Stream<Course?> watchCourse(String courseId) {
    return _fs
        .doc(FirestoreCollections.courses, courseId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Course.fromFirestore(doc);
    });
  }
}
