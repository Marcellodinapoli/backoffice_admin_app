import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'course_details_page.dart';

class BkCoursesPage extends StatelessWidget {
  const BkCoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('courses').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Errore: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text('Nessun corso trovato'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data =
            docs[index].data() as Map<String, dynamic>;
            final courseId = docs[index].id;

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                title: Text(
                  data['title'] ?? 'Titolo non disponibile',
                ),
                subtitle: Text('ID: $courseId'),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CourseDetailsPage(
                            courseId: courseId,
                          ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
