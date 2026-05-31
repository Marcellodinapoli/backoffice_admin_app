import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BkDashboardPage extends StatelessWidget {
  const BkDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dashboard BackOffice",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: "Utenti Totali",
                    collection: "users",
                    icon: Icons.people_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: "Corsi Totali",
                    collection: "courses",
                    icon: Icons.school_outlined,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String collection,
    required IconData icon,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final count = snapshot.data!.docs.length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40),
                const SizedBox(height: 12),
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(title),
              ],
            ),
          ),
        );
      },
    );
  }
}
