import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CourseDetailsPage extends StatelessWidget {
  final String courseId;

  const CourseDetailsPage({
    super.key,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dettaglio Corso"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('courses')
            .doc(courseId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Errore: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("Corso non trovato"),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                _buildField("Titolo", data['title']),
                _buildField("Descrizione", data['description']),
                _buildField("Categoria", data['category']),
                _buildField("Difficoltà", data['difficulty']),
                _buildField("Tempo limite", data['timeLimit']),
                _buildField("Creato il", data['createdAt']),
                _buildField("Course ID", courseId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        "$label: ${value ?? '-'}",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
