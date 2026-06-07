import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/company.dart';
import '../../../services/firebase/companies_service.dart';
import '../../../services/firebase/jobs_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import 'company_jobs_page.dart';

class CreditJobPage extends StatelessWidget {
  const CreditJobPage({super.key});

  static const _expiringWithinDays = 7;

  String _resolveJobStatus(Map<String, dynamic> data) {
    String status = data['status']?.toString() ?? 'pending';
    final Timestamp? expiryTs = data['expiryDate'] as Timestamp?;
    final DateTime? expiryDateRaw = expiryTs?.toDate();
    final bool isExpired =
        expiryDateRaw != null && expiryDateRaw.isBefore(DateTime.now());

    if (isExpired && status == 'approved') {
      status = 'expired';
    }
    return status;
  }

  _CompanyJobStats _statsForCompany(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allJobs,
    String companyId,
  ) {
    final stats = _CompanyJobStats();
    final now = DateTime.now();
    final expiringThreshold = now.add(
      const Duration(days: _expiringWithinDays),
    );

    for (final doc in allJobs) {
      final data = doc.data();
      if ((data['companyId'] ?? '').toString() != companyId) continue;

      final status = _resolveJobStatus(data);
      final Timestamp? expiryTs = data['expiryDate'] as Timestamp?;
      final DateTime? expiry = expiryTs?.toDate();

      switch (status) {
        case 'pending':
          stats.pending++;
          break;
        case 'approved':
          stats.approved++;
          if (expiry != null &&
              expiry.isAfter(now) &&
              !expiry.isAfter(expiringThreshold)) {
            stats.expiring++;
          }
          break;
        case 'blocked':
          stats.blocked++;
          break;
        case 'expired':
          stats.expired++;
          break;
        case 'rejected':
          stats.rejected++;
          break;
      }
    }

    return stats;
  }

  Widget _statChip({
    required String label,
    required int value,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'CreditJob',
          subtitle: 'Gestione offerte lavoro per azienda',
        ),
        Expanded(
          child: StreamBuilder<List<Company>>(
            stream: CompaniesService.instance.watchAll(),
            builder: (context, companiesSnap) {
              if (!companiesSnap.hasData) return const LoadingView();
              final companies = companiesSnap.data ?? [];
              if (companies.isEmpty) {
                return const EmptyState(
                  icon: Icons.business_outlined,
                  title: 'Nessuna azienda',
                  subtitle: 'Non risultano aziende in piattaforma.',
                );
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: JobsService.instance.watchAllJobs(),
                builder: (context, jobsSnap) {
                  if (!jobsSnap.hasData) return const LoadingView();
                  final allJobs = jobsSnap.data!.docs;

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: companies.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final company = companies[index];
                      final stats = _statsForCompany(allJobs, company.id);

                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CompanyJobsPage(
                                  companyId: company.id,
                                  companyName: company.companyName,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.business_outlined,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        company.companyName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  company.email,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _statChip(
                                      label: 'In attesa',
                                      value: stats.pending,
                                      color: AppColors.warning,
                                      background: AppColors.warningBg,
                                    ),
                                    _statChip(
                                      label: 'Approvate',
                                      value: stats.approved,
                                      color: AppColors.success,
                                      background: AppColors.successBg,
                                    ),
                                    _statChip(
                                      label: 'Bloccate',
                                      value: stats.blocked,
                                      color: AppColors.textSecondary,
                                      background: AppColors.surfaceVariant,
                                    ),
                                    _statChip(
                                      label: 'Scadute',
                                      value: stats.expired,
                                      color: AppColors.error,
                                      background: AppColors.errorBg,
                                    ),
                                    _statChip(
                                      label: 'Rifiutate',
                                      value: stats.rejected,
                                      color: AppColors.error,
                                      background: AppColors.errorBg,
                                    ),
                                    _statChip(
                                      label: 'In scadenza (7g)',
                                      value: stats.expiring,
                                      color: AppColors.warning,
                                      background: AppColors.warningBg,
                                    ),
                                  ],
                                ),
                              ],
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
    );
  }
}

class _CompanyJobStats {
  int pending = 0;
  int approved = 0;
  int blocked = 0;
  int expired = 0;
  int rejected = 0;
  int expiring = 0;
}

