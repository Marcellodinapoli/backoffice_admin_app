import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/job_offer_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/firebase/jobs_service.dart';
import '../../../shared/widgets/loading_view.dart';

class JobOfferDetailPage extends StatelessWidget {
  final String jobId;
  final String companyName;

  const JobOfferDetailPage({
    super.key,
    required this.jobId,
    required this.companyName,
  });

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

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

  String _workModeLabel(String? value) {
    switch (value) {
      case 'remote':
        return 'Da remoto';
      case 'hybrid':
        return 'Ibrido';
      case 'presence':
        return 'In presenza';
      default:
        return value ?? '';
    }
  }

  String _parseSkills(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) {
            if (e is Map && e['value'] != null) {
              final name = e['value'].toString();
              final required = e['required'] == true;
              return required ? '$name (obbligatorio)' : name;
            }
            return '';
          })
          .where((e) => e.isNotEmpty)
          .join(', ');
    }
    return raw?.toString() ?? '';
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _multilineSection(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(label),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Dettaglio offerta'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: JobsService.instance.watchJob(jobId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingView();
          if (!snapshot.data!.exists) {
            return const Center(child: Text('Offerta non trovata'));
          }

          final data = snapshot.data!.data() ?? {};
          final status = _resolveStatus(data);
          final isPending = status == 'pending';
          final isBlocked = status == 'blocked';

          final title = data['title']?.toString() ?? 'Senza titolo';
          final location = data['location']?.toString() ?? '';
          final contractType = data['contractType']?.toString() ?? '';
          final schedule = data['schedule']?.toString() ?? '';
          final workMode = _workModeLabel(data['workMode']?.toString());
          final education = data['education']?.toString() ?? '';
          final experience = data['experience']?.toString() ?? '';
          final level = data['level']?.toString() ?? '';
          final department = data['department']?.toString() ?? '';
          final role = data['role']?.toString() ?? '';
          final positions = _readInt(data['positions']);
          final benefits = data['benefits']?.toString() ?? '';
          final description = data['description']?.toString() ?? '';
          final tasks = data['tasks']?.toString() ?? '';
          final niceSkills = data['niceSkills']?.toString() ?? '';
          final referencePerson = data['referencePerson']?.toString() ?? '';
          final hrEmail = data['hrEmail']?.toString() ?? '';
          final skills = _parseSkills(data['skills']);
          final online = data['online'] as bool? ?? false;
          final applicationsCount = _readInt(data['applicationsCount']) ?? 0;
          final qualityScore = _readInt(data['qualityScore']) ?? 0;

          final salaryFrom = _readInt(data['salaryFrom']);
          final salaryTo = _readInt(data['salaryTo']);
          final salaryMin = _readInt(data['salaryMin']);
          final salaryMax = _readInt(data['salaryMax']);

          String salaryText = '';
          if (salaryFrom != null || salaryTo != null) {
            salaryText = '${salaryFrom ?? '-'} - ${salaryTo ?? '-'} €';
          } else if (salaryMin != null || salaryMax != null) {
            salaryText = 'RAL ${salaryMin ?? '-'} - ${salaryMax ?? '-'} €';
          }

          final createdTs = data['createdAt'] as Timestamp?;
          final expiryTs = data['expiryDate'] as Timestamp?;
          final createdDate =
              createdTs != null ? _formatDate(createdTs.toDate()) : '';
          final expiryDate =
              expiryTs != null ? _formatDate(expiryTs.toDate()) : '';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  JobOfferStatus.label(status),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _detailRow('Azienda', companyName),
                          _detailRow('Sede', location),
                          _sectionTitle('Inquadramento'),
                          _detailRow('Contratto', contractType),
                          _detailRow('Orario', schedule),
                          _detailRow('Modalità di lavoro', workMode),
                          if (positions != null)
                            _detailRow('Posti disponibili', '$positions'),
                          if (level.isNotEmpty) _detailRow('Livello', level),
                          if (department.isNotEmpty)
                            _detailRow('Reparto', department),
                          if (role.isNotEmpty) _detailRow('Ruolo', role),
                          _sectionTitle('Requisiti'),
                          _detailRow('Formazione richiesta', education),
                          _detailRow('Esperienza richiesta', experience),
                          if (skills.isNotEmpty)
                            _detailRow('Competenze', skills),
                          if (niceSkills.isNotEmpty)
                            _detailRow('Competenze preferite', niceSkills),
                          if (salaryText.isNotEmpty)
                            _detailRow('Retribuzione', salaryText),
                          _multilineSection('Mansioni', tasks),
                          _multilineSection('Descrizione', description),
                          _multilineSection('Benefit', benefits),
                          if (referencePerson.isNotEmpty ||
                              hrEmail.isNotEmpty) ...[
                            _sectionTitle('Contatti HR'),
                            _detailRow('Referente', referencePerson),
                            _detailRow('Email HR', hrEmail),
                          ],
                          _sectionTitle('Statistiche'),
                          _detailRow(
                            'Candidature',
                            applicationsCount.toString(),
                          ),
                          _detailRow(
                            'Qualità annuncio',
                            '$qualityScore%',
                          ),
                          _detailRow('Online', online ? 'Sì' : 'No'),
                          if (createdDate.isNotEmpty)
                            _detailRow('Pubblicato il', createdDate),
                          if (expiryDate.isNotEmpty)
                            _detailRow('Scade il', expiryDate),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (isPending)
                        FilledButton.icon(
                          onPressed: () =>
                              JobsService.instance.approveJob(jobId),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Approva'),
                        ),
                      if (isPending)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          onPressed: () =>
                              JobsService.instance.rejectJob(jobId),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Rifiuta'),
                        ),
                      if (isBlocked)
                        FilledButton.icon(
                          onPressed: () =>
                              JobsService.instance.unblockJob(jobId),
                          icon: const Icon(Icons.lock_open, size: 18),
                          label: const Text('Sblocca'),
                        )
                      else if (!isPending)
                        OutlinedButton.icon(
                          onPressed: () =>
                              JobsService.instance.blockJob(jobId),
                          icon: const Icon(Icons.block, size: 18),
                          label: const Text('Blocca'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
