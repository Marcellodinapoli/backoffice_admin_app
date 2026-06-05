import 'package:cloud_firestore/cloud_firestore.dart';

/// Accesso centralizzato a Firestore (progetto creditform-d505d).
class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  FirebaseFirestore get db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String name) {
    return db.collection(name);
  }

  DocumentReference<Map<String, dynamic>> doc(String collection, String id) {
    return db.collection(collection).doc(id);
  }
}
