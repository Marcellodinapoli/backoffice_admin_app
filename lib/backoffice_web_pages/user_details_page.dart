import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailsPage extends StatelessWidget {
  final String userId;

  const UserDetailsPage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dettaglio Utente"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
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
              child: Text("Utente non trovato"),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                _buildField("Email", data['email']),
                _buildField("Tipo", data['type']),
                _buildField("Status", data['status']),
                _buildField("UID", data['uid']),
                _buildField("User Code", data['userCode']),
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
