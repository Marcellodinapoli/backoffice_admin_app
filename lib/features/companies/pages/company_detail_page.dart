import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/company.dart';
import '../../../services/firebase/companies_service.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/status_badge.dart';

class CompanyDetailPage extends StatelessWidget {
  final String companyId;

  const CompanyDetailPage({super.key, required this.companyId});

  Future<void> _block(BuildContext context, Company company) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Blocca azienda'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Motivazione'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Conferma'),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty && company.companyCode != null) {
      await CompaniesService.instance.blockCompany(
        company.id,
        company.companyCode!,
        ctrl.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Dettaglio azienda'),
      ),
      body: StreamBuilder<Company?>(
        stream: CompaniesService.instance.watchCompany(companyId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingView();
          final company = snapshot.data;
          if (company == null) {
            return const Center(child: Text('Azienda non trovata'));
          }

          return StreamBuilder<String?>(
            stream: CompaniesService.instance.watchLinkedUserStatus(companyId),
            builder: (context, statusSnap) {
              final status = statusSnap.data ?? company.status;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    company.companyName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                StatusBadge.fromStatus(status),
                              ],
                            ),
                            const Divider(height: 24),
                            _row('Email', company.email),
                            _row('Telefono', company.phone ?? 'N/D'),
                            _row('P.IVA', company.piva ?? 'N/D'),
                            _row('Sito web', company.website ?? 'N/D'),
                            _row('Referente', company.referencePerson ?? 'N/D'),
                            _row('Ruolo ref.', company.referenceRole ?? 'N/D'),
                            _row('Codice', company.companyCode ?? 'N/D'),
                            if (company.blockedAt != null)
                              _row(
                                'Bloccata il',
                                DateFormat('dd/MM/yyyy')
                                    .format(company.blockedAt!.toDate()),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (company.companyCode != null)
                      StreamBuilder(
                        stream: CompaniesService.instance
                            .watchLinkedWorkUsers(company.companyCode!),
                        builder: (context, usersSnap) {
                          final count = usersSnap.data?.length ?? 0;
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.people_outline),
                              title: Text('$count utenti work collegati'),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: status == 'blocked'
                                ? () => CompaniesService.instance
                                    .activateCompany(
                                      company.id,
                                      company.companyCode ?? '',
                                    )
                                : () => _block(context, company),
                            icon: Icon(
                              status == 'blocked'
                                  ? Icons.lock_open
                                  : Icons.block,
                            ),
                            label: Text(
                              status == 'blocked' ? 'Attiva' : 'Blocca',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
