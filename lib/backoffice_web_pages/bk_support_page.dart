import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../services/admin_menu_badge_controller.dart';
import '../shared/widgets/section_header.dart';

class BkSupportPage extends StatefulWidget {
  const BkSupportPage({super.key});

  @override
  State<BkSupportPage> createState() => _BkSupportPageState();
}

class _BkSupportPageState extends State<BkSupportPage> {
  final Map<String, TextEditingController> _replyControllers = {};
  bool _isAdmin = false;
  bool _checkingAdmin = true;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdminMenuBadgeController.markSupportVisited();
    });
  }

  @override
  void dispose() {
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdTokenResult(true);
    if (!mounted) return;
    setState(() {
      _isAdmin = token?.claims?['admin'] == true;
      _checkingAdmin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    if (_checkingAdmin) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final stream = _isAdmin
        ? FirebaseFirestore.instance.collection('support').snapshots()
        : FirebaseFirestore.instance
            .collection('support')
            .where('userId', isEqualTo: user?.uid)
            .snapshots();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            title: 'Assistenza',
            subtitle: 'Ticket e messaggi utenti',
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Errore caricamento assistenza:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nessun ticket ancora inviato'),
                  );
                }

                final tickets = snapshot.data!.docs.toList()
                  ..sort((a, b) {
                    final ta = _ticketSortTime(a);
                    final tb = _ticketSortTime(b);
                    return tb.compareTo(ta);
                  });

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    final data = ticket.data();
                    final subject = data['subject']?.toString() ?? '';
                    final status = data['status']?.toString() ?? 'open';
                    final createdAt = _readTimestamp(data['createdAt']);
                    final userId = data['userId']?.toString() ?? '';
                    final replyCtrl = _replyControllers.putIfAbsent(
                      ticket.id,
                      TextEditingController.new,
                    );

                    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                      future: userId.isEmpty
                          ? Future<DocumentSnapshot<Map<String, dynamic>>?>.value(null)
                          : FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .get(),
                      builder: (context, userSnap) {
                        var firstName = '';
                        var lastName = '';
                        var userEmail = data['userEmail']?.toString() ?? '';

                        if (userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
                          final userData = userSnap.data!.data();
                          if (userData != null) {
                            firstName = userData['firstName']?.toString() ??
                                userData['name']?.toString() ??
                                '';
                            lastName = userData['lastName']?.toString() ?? '';
                            userEmail =
                                userData['email']?.toString() ?? userEmail;
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1300),
                              child: Card(
                                color: const Color(0xFFF5F5F5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              subject,
                                              style: TextStyle(
                                                fontSize: isMobile ? 14 : 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: status == 'closed'
                                                  ? Colors.grey
                                                  : Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              status == 'closed'
                                                  ? 'CHIUSO'
                                                  : 'APERTO',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Da: $lastName $firstName — $userEmail',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (createdAt != null)
                                        Text(
                                          'Inviato il ${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      const Divider(),
                                      StreamBuilder<
                                          QuerySnapshot<Map<String, dynamic>>>(
                                        stream: ticket.reference
                                            .collection('messages')
                                            .orderBy('timestamp',
                                                descending: true)
                                            .snapshots(
                                                includeMetadataChanges: true),
                                        builder: (context, msgSnap) {
                                          if (msgSnap.hasError) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              child: Text(
                                                'Errore messaggi: ${msgSnap.error}',
                                                style: TextStyle(
                                                  color: Colors.red.shade700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            );
                                          }

                                          if (msgSnap.connectionState ==
                                                  ConnectionState.waiting &&
                                              !msgSnap.hasData) {
                                            return const SizedBox(
                                              height: 24,
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            );
                                          }

                                          if (!msgSnap.hasData) {
                                            return const SizedBox.shrink();
                                          }

                                          final msgs =
                                              msgSnap.data!.docs.toList()
                                                ..sort((a, b) {
                                                  final ta =
                                                      _messageTimestamp(a);
                                                  final tb =
                                                      _messageTimestamp(b);
                                                  return tb.compareTo(ta);
                                                });

                                          return Column(
                                            children: msgs.map((m) {
                                              final msg = m.data();
                                              final sender =
                                                  msg['sender']?.toString();
                                              final text =
                                                  msg['text']?.toString() ??
                                                      '';
                                              final isUser = sender == 'user';

                                              return Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 4),
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: isUser
                                                      ? Colors.white
                                                      : Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color:
                                                        Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      isUser
                                                          ? Icons.person_outline
                                                          : Icons
                                                              .support_agent,
                                                      size: 18,
                                                      color: isUser
                                                          ? Colors.grey
                                                          : Colors.blue,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            isUser
                                                                ? 'Utente'
                                                                : 'Assistenza',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: isUser
                                                                  ? Colors
                                                                      .black87
                                                                  : Colors.blue,
                                                            ),
                                                          ),
                                                          Text(text),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                      if (_isAdmin && status != 'closed') ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller: replyCtrl,
                                                decoration:
                                                    const InputDecoration(
                                                  hintText:
                                                      'Scrivi una risposta...',
                                                  border: OutlineInputBorder(),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Invia',
                                              icon: const Icon(Icons.send),
                                              onPressed: () async {
                                                final text =
                                                    replyCtrl.text.trim();
                                                if (text.isEmpty) return;

                                                replyCtrl.clear();

                                                await ticket.reference
                                                    .collection('messages')
                                                    .add({
                                                  'text': text,
                                                  'sender': 'admin',
                                                  'timestamp': Timestamp.now(),
                                                });

                                                await ticket.reference.update({
                                                  'lastMessageAt':
                                                      Timestamp.now(),
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.error,
                                            ),
                                            onPressed: () async {
                                              await ticket.reference
                                                  .update({'status': 'closed'});
                                            },
                                            child: const Text('Chiudi ticket'),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _readTimestamp(dynamic raw) {
    if (raw is Timestamp) return raw.toDate().toLocal();
    if (raw is DateTime) return raw.toLocal();
    if (raw is String) return DateTime.tryParse(raw)?.toLocal();
    return null;
  }

  DateTime _ticketSortTime(
      QueryDocumentSnapshot<Map<String, dynamic>> ticket) {
    return _readTimestamp(ticket.data()['lastMessageAt']) ??
        _readTimestamp(ticket.data()['createdAt']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime _messageTimestamp(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return _readTimestamp(doc.data()['timestamp']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
