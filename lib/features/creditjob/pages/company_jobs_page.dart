import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/job_offer_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/firebase/jobs_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import 'job_offer_detail_page.dart';

class CompanyJobsPage extends StatelessWidget {
  final String companyId;
  final String companyName;

  const CompanyJobsPage({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  String _resolveStatus(Map<String, dynamic> data) {
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

  Color _statusBg(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warningBg;
      case 'approved':
        return AppColors.successBg;
      case 'blocked':
        return AppColors.surfaceVariant;
      case 'expired':
        return AppColors.errorBg;
      case 'rejected':
        return AppColors.errorBg;
      default:
        return AppColors.surfaceVariant;
    }
  }

  Color _statusFg(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'approved':
        return AppColors.success;
      case 'blocked':
        return AppColors.textSecondary;
      case 'expired':
        return AppColors.error;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _openDetail(BuildContext context, String jobId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobOfferDetailPage(
          jobId: jobId,
          companyName: companyName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(companyName),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: JobsService.instance.watchCompanyJobs(companyId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(
              message:
                  'Impossibile caricare le offerte di lavoro.\n${snapshot.error}',
            );
          }
          if (!snapshot.hasData) return const LoadingView();
          final docs = [...snapshot.data!.docs];
          docs.sort((a, b) {
            final aTs = a.data()['createdAt'] as Timestamp?;
            final bTs = b.data()['createdAt'] as Timestamp?;
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs);
          });
          if (docs.isEmpty) {
            return const EmptyState(
              icon: Icons.work_outline,
              title: 'Nessuna offerta di lavoro',
              subtitle: 'Questa azienda non ha offerte di lavoro.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();
              final id = doc.id;

              final title = data['title']?.toString() ?? 'Senza titolo';
              final location = data['location']?.toString() ?? '';
              final online = data['online'] as bool? ?? false;
              final applicationsCount = _readInt(data['applicationsCount']);
              final contractType = data['contractType']?.toString() ?? '';

              final status = _resolveStatus(data);

              final Timestamp? createdTs = data['createdAt'] as Timestamp?;
              final String createdDate =
                  createdTs != null ? _formatDate(createdTs.toDate()) : '';

              final Timestamp? expiryTs = data['expiryDate'] as Timestamp?;
              final DateTime? expiryDateRaw = expiryTs?.toDate();
              final String expiryDate =
                  expiryDateRaw != null ? _formatDate(expiryDateRaw) : '';

              final isPending = status == 'pending';
              final isBlocked = status == 'blocked';

              return Card(
                color: _statusBg(status),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _openDetail(context, id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: AppColors.divider),
                                    ),
                                    child: Text(
                                      JobOfferStatus.label(status),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _statusFg(status),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                              if (location.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  location,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              if (contractType.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  contractType,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                'Online: ${online ? "Sì" : "No"} · Candidature: $applicationsCount',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tocca per vedere l\'inserzione completa',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (createdDate.isNotEmpty ||
                                  expiryDate.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  [
                                    if (createdDate.isNotEmpty)
                                      'Pubblicato: $createdDate',
                                    if (expiryDate.isNotEmpty)
                                      'Scade: $expiryDate',
                                  ].join(' · '),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (isPending)
                            FilledButton.icon(
                              onPressed: () => JobsService.instance.approveJob(id),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Approva'),
                            ),
                          if (isPending)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.error,
                              ),
                              onPressed: () => JobsService.instance.rejectJob(id),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Rifiuta'),
                            ),
                          if (isBlocked)
                            FilledButton.icon(
                              onPressed: () =>
                                  JobsService.instance.unblockJob(id),
                              icon: const Icon(Icons.lock_open, size: 18),
                              label: const Text('Sblocca'),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: () => JobsService.instance.blockJob(id),
                              icon: const Icon(Icons.block, size: 18),
                              label: const Text('Blocca'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

