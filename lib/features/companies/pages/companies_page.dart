import 'package:flutter/material.dart';

import '../../../core/subscription/subscription_admin_helper.dart';
import '../../../models/company.dart';
import '../../../services/firebase/companies_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../widgets/company_card.dart';
import 'company_detail_page.dart';

class CompaniesPage extends StatefulWidget {
  const CompaniesPage({super.key});

  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Company> _filter(List<Company> list) {
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list
        .where((c) =>
            c.companyName.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Aziende',
          subtitle: 'Gestione aziende registrate',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Cerca azienda...',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Company>>(
            stream: CompaniesService.instance.watchAll(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const LoadingView(message: 'Caricamento aziende...');
              }
              if (snapshot.hasError) {
                return ErrorView(message: 'Errore: ${snapshot.error}');
              }

              final companies = _filter(snapshot.data ?? []);
              if (companies.isEmpty) {
                return EmptyState(
                  icon: Icons.business_outlined,
                  title: _query.isEmpty
                      ? 'Nessuna azienda'
                      : 'Nessun risultato',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: companies.length,
                itemBuilder: (context, index) {
                  final company = companies[index];
                  return StreamBuilder<String?>(
                    stream: CompaniesService.instance
                        .watchLinkedUserStatus(company.id),
                    builder: (context, statusSnap) {
                      return CompanyCard(
                        company: company,
                        linkedStatus: statusSnap.data,
                        subscriptionInfo: SubscriptionAdminHelper.fromCompanyMap(
                          company.toSubscriptionMap(),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CompanyDetailPage(companyId: company.id),
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
    );
  }
}
