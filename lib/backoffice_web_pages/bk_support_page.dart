import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ================================================================
// PAGE ROOT
// ================================================================
class BkSupportPage extends StatefulWidget {
  const BkSupportPage({super.key});

  @override
  State<BkSupportPage> createState() => _BkSupportPageState();
}

// ================================================================
// STATE
// ================================================================
class _BkSupportPageState extends State<BkSupportPage> {
  final user = FirebaseAuth.instance.currentUser;
  late final Future<bool> _isAdminFuture;
  final Map<String, TextEditingController> _replyControllers = {};

  // ================================================================
  // LIFECYCLE
  // ================================================================
  @override
  void initState() {
    super.initState();
    _isAdminFuture = _resolveIsAdmin();
  }

  @override
  void dispose() {
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<bool> _resolveIsAdmin() async {
    final token = await user?.getIdTokenResult();
    return token?.claims?['admin'] == true;
  }

  // ================================================================
  // LOCAL STORAGE
  // ================================================================
// ================================================================
// BUILD
// ================================================================
  @override
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.of(context).size.width < 600;

    return FutureBuilder<bool>(
      future: _isAdminFuture,
      builder: (context, tokenSnap) {

        if (tokenSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAdmin = tokenSnap.data ?? false;

        final stream = isAdmin
            ? FirebaseFirestore.instance
            .collection('support')
            .snapshots()
            : FirebaseFirestore.instance
            .collection('support')
            .where(
          'userId',
          isEqualTo: user?.uid,
        )
            .snapshots();

        return Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: stream,
                    builder: (context, snapshot) {

                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "Nessun ticket ancora inviato",
                          ),
                        );
                      }

                      final tickets = snapshot.data!.docs.toList()
                        ..sort((a, b) {
                          final ta = (a['createdAt'] as Timestamp?)
                                  ?.toDate() ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          final tb = (b['createdAt'] as Timestamp?)
                                  ?.toDate() ??
                              DateTime.fromMillisecondsSinceEpoch(0);
                          return ta.compareTo(tb);
                        });

                      return ListView.builder(
                        itemCount: tickets.length,
                        itemBuilder: (context, index) {

                          final ticket =
                          tickets[index];

                          final subject =
                              ticket['subject'] ?? '';

                          final status =
                              ticket['status'] ?? 'open';

                          final createdAt =
                          (ticket['createdAt']
                          as Timestamp?)
                              ?.toDate()
                              .toLocal();

                          final replyCtrl = _replyControllers.putIfAbsent(
                            ticket.id,
                            TextEditingController.new,
                          );

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore
                                .instance
                                .collection('users')
                                .doc(ticket['userId'])
                                .get(),
                            builder:
                                (context, userSnap) {

                              String firstName = "";
                              String lastName = "";
                              String userEmail =
                                  ticket['userEmail'] ?? "";

                              if (userSnap.hasData &&
                                  userSnap.data!.exists) {
                                final data =
                                userSnap.data!.data()
                                as Map<String, dynamic>;

                                firstName =
                                    data['firstName'] ??
                                        data['name'] ??
                                        "";

                                lastName =
                                    data['lastName'] ??
                                        "";

                                userEmail =
                                    data['email'] ??
                                        userEmail;
                              }

                              return Container(
                                margin:
                                const EdgeInsets.symmetric(
                                    vertical: 8),
                                child: Align(
                                  alignment:
                                  Alignment.topCenter,
                                  child:
                                  ConstrainedBox(
                                    constraints:
                                    const BoxConstraints(
                                        maxWidth:
                                        1300),
                                    child: Card(
                                      color: const Color(
                                          0xFFF5F5F5),
                                      shape:
                                      RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                            12),
                                      ),
                                      child: Padding(
                                        padding:
                                        const EdgeInsets
                                            .all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                          children: [

                                            // HEADER
                                            Row(
                                              children: [
                                                Expanded(
                                                  child:
                                                  Text(
                                                    subject,
                                                    style:
                                                    TextStyle(
                                                      fontSize:
                                                      isMobile
                                                          ? 14
                                                          : 16,
                                                      fontWeight:
                                                      FontWeight
                                                          .bold,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal:
                                                      8,
                                                      vertical:
                                                      4),
                                                  decoration:
                                                  BoxDecoration(
                                                    color: status ==
                                                        'closed'
                                                        ? Colors.grey
                                                        : Colors.green,
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        8),
                                                  ),
                                                  child: Text(
                                                    status ==
                                                        'closed'
                                                        ? 'CHIUSO'
                                                        : 'APERTO',
                                                    style:
                                                    const TextStyle(
                                                      color:
                                                      Colors
                                                          .white,
                                                      fontSize:
                                                      12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(
                                                height: 4),

                                            Text(
                                              "Da: $lastName $firstName — $userEmail",
                                              style:
                                              const TextStyle(
                                                fontSize:
                                                13,
                                                fontWeight:
                                                FontWeight
                                                    .w500,
                                                color: Colors
                                                    .black87,
                                              ),
                                            ),

                                            if (createdAt !=
                                                null)
                                              Text(
                                                "Inviato il ${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}",
                                                style:
                                                const TextStyle(
                                                  fontSize:
                                                  12,
                                                  color: Colors
                                                      .black54,
                                                ),
                                              ),

                                            const Divider(),

                                            // MESSAGGI
                                            StreamBuilder<QuerySnapshot>(
                                              stream: ticket
                                                  .reference
                                                  .collection(
                                                  'messages')
                                                  .orderBy(
                                                  'timestamp')
                                                  .snapshots(
                                                  includeMetadataChanges:
                                                      true),
                                              builder: (context,
                                                  msgSnap) {

                                                if (msgSnap.connectionState ==
                                                        ConnectionState
                                                            .waiting &&
                                                    !msgSnap.hasData) {
                                                  return const SizedBox();
                                                }

                                                if (!msgSnap
                                                    .hasData) {
                                                  return const SizedBox();
                                                }

                                                final msgs =
                                                    msgSnap
                                                        .data!
                                                        .docs
                                                        .toList()
                                                  ..sort((a, b) {
                                                    final ta =
                                                        _messageTimestamp(
                                                            a);
                                                    final tb =
                                                        _messageTimestamp(
                                                            b);
                                                    return ta.compareTo(tb);
                                                  });

                                                return Column(
                                                  children:
                                                  msgs.map(
                                                          (m) {
                                                        final data =
                                                        m.data()
                                                        as Map<String,
                                                            dynamic>;

                                                        final sender =
                                                        data['sender'];

                                                        final text =
                                                            data['text'] ??
                                                                '';

                                                        final isUser =
                                                            sender ==
                                                                'user';

                                                        return Container(
                                                          margin:
                                                          const EdgeInsets.symmetric(
                                                              vertical:
                                                              4),
                                                          padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                          decoration:
                                                          BoxDecoration(
                                                            color: isUser
                                                                ? Colors.white
                                                                : Colors.blue.shade50,
                                                            borderRadius:
                                                            BorderRadius.circular(
                                                                8),
                                                            border:
                                                            Border.all(
                                                              color: Colors.grey
                                                                  .shade300,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            crossAxisAlignment:
                                                            CrossAxisAlignment.start,
                                                            children: [
                                                              Icon(
                                                                isUser
                                                                    ? Icons.person_outline
                                                                    : Icons.support_agent,
                                                                size:
                                                                18,
                                                                color: isUser
                                                                    ? Colors.grey
                                                                    : Colors.blue,
                                                              ),
                                                              const SizedBox(
                                                                  width:
                                                                  8),
                                                              Expanded(
                                                                child:
                                                                Column(
                                                                  crossAxisAlignment:
                                                                  CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text(
                                                                      isUser
                                                                          ? "Utente"
                                                                          : "Assistenza",
                                                                      style:
                                                                      TextStyle(
                                                                        fontWeight:
                                                                        FontWeight.bold,
                                                                        color: isUser
                                                                            ? Colors.black87
                                                                            : Colors.blue,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                        text),
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

                                            if (isAdmin &&
                                                status !=
                                                    'closed') ...[
                                              const SizedBox(
                                                  height: 12),

                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .end,
                                                children: [
                                                  Expanded(
                                                    child: TextField(
                                                      controller:
                                                          replyCtrl,
                                                      decoration:
                                                          const InputDecoration(
                                                        hintText:
                                                            'Scrivi una risposta...',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    tooltip: 'Invia',
                                                    icon: const Icon(
                                                        Icons.send),
                                                    onPressed:
                                                        () async {
                                                      final text = replyCtrl
                                                          .text
                                                          .trim();
                                                      if (text.isEmpty) {
                                                        return;
                                                      }

                                                      replyCtrl.clear();

                                                      await ticket.reference
                                                          .collection(
                                                              'messages')
                                                          .add({
                                                        'text': text,
                                                        'sender':
                                                            'admin',
                                                        'timestamp':
                                                            Timestamp.now(),
                                                      });

                                                      await ticket.reference
                                                          .update({
                                                        'lastMessageAt':
                                                            Timestamp.now(),
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(
                                                  height: 8),

                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red,
                                                  ),
                                                  onPressed:
                                                      () async {
                                                    await ticket
                                                        .reference
                                                        .update({
                                                      'status':
                                                          'closed'
                                                    });
                                                  },
                                                  child:
                                                      const Text(
                                                          'Chiudi ticket'),
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
          ),
        );
      },
    );
  }

  DateTime _messageTimestamp(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    final ts = data?['timestamp'];
    if (ts is Timestamp) return ts.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}