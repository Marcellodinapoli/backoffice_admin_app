import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/subscription/subscription_admin_helper.dart';
import '../../../models/app_user.dart';
import '../../../services/firebase/users_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../widgets/user_card.dart';
import 'user_detail_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AppUser> _filter(List<AppUser> users) {
    if (_query.isEmpty) return users;
    final q = _query.toLowerCase();
    return users
        .where((u) =>
            u.name.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Utenti',
          subtitle: 'Gestione utenti pubblici e work',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Cerca per nome o email...',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Generici'),
            Tab(text: 'Work'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _UserList(type: 'public', query: _query, filter: _filter),
              _UserList(type: 'work', query: _query, filter: _filter),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserList extends StatefulWidget {
  final String type;
  final String query;
  final List<AppUser> Function(List<AppUser>) filter;

  const _UserList({
    required this.type,
    required this.query,
    required this.filter,
  });

  @override
  State<_UserList> createState() => _UserListState();
}

class _UserListState extends State<_UserList> {
  final Map<String, Future<SubscriptionCardInfo>> _usageFutures = {};
  final Map<String, Future<DocumentSnapshot<Map<String, dynamic>>?>>
      _companyFutures = {};

  Future<SubscriptionCardInfo> _loadPublicUsage(AppUser user) {
    final fallback =
        SubscriptionAdminHelper.fromPublicUserMap(user.subscriptionData);
    return _usageFutures.putIfAbsent(
      user.id,
      () => SubscriptionAdminHelper.loadPublicUsage(user.id).catchError(
        (_) => fallback,
      ),
    );
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _loadCompany(
    String? companyId,
  ) {
    if (companyId == null) {
      return Future.value(null);
    }
    return _companyFutures.putIfAbsent(
      companyId,
      () => UsersService.instance.getCompany(companyId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: UsersService.instance.watchByType(widget.type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const LoadingView(message: 'Caricamento utenti...');
        }
        if (snapshot.hasError) {
          return ErrorView(message: 'Errore: ${snapshot.error}');
        }

        final users = widget.filter(snapshot.data ?? []);
        if (users.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline,
            title: widget.query.isEmpty
                ? 'Nessun utente ${widget.type}'
                : 'Nessun risultato per "${widget.query}"',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              if (widget.type == 'public') {
                final baseInfo = SubscriptionAdminHelper.fromPublicUserMap(
                  user.subscriptionData,
                );
                return FutureBuilder<SubscriptionCardInfo>(
                  future: _loadPublicUsage(user),
                  builder: (context, subSnap) {
                    return UserCard(
                      user: user,
                      subscriptionInfo: subSnap.data ?? baseInfo,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserDetailPage(userId: user.id),
                        ),
                      ),
                    );
                  },
                );
              }
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                future: _loadCompany(user.companyId),
                builder: (context, companySnap) {
                  String? companyName;
                  if (companySnap.hasData && companySnap.data != null) {
                    companyName =
                        companySnap.data!.data()?['companyName']?.toString();
                  }
                  return UserCard(
                    user: user,
                    companyName: companyName,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetailPage(userId: user.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
