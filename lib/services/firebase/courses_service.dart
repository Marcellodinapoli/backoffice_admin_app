import '../../core/constants/firestore_collections.dart';
import '../../models/course.dart';
import 'firestore_service.dart';

class CoursesService {
  CoursesService._();

  static final CoursesService instance = CoursesService._();
  final _fs = FirestoreService.instance;

  Stream<List<Course>> watchByCategory(String category) {
    return _fs
        .collection(FirestoreCollections.courses)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Course.fromFirestore(d)).toList());
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
