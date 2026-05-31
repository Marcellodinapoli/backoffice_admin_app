import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_details_page.dart';

class BkUsersPage extends StatelessWidget {
  const BkUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
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
            child: Text('Nessun utente trovato'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final email = data['email'] ?? 'No email';
            final type = data['type'] ?? '-';
            final status = data['status'] ?? '-';

            return Card(
              child: ListTile(
                title: Text(email),
                subtitle: Text('Tipo: $type | Status: $status'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserDetailsPage(
                        userId: doc.id,
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
