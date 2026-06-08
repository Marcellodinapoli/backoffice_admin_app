import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/dashboard_stats.dart';
import '../../../services/firebase/stats_service.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../widgets/dashboard_detail_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardStats? _stats;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await StatsService.instance.loadStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Dashboard',
          subtitle: 'KPI principali della piattaforma',
          trailing: IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Aggiorna',
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingView(message: 'Caricamento KPI...')
              : _error != null
                  ? ErrorView(
                      message: 'Errore: $_error',
                      onRetry: _load,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _DashboardContent(stats: _stats!),
                    ),
        ),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardStats stats;

  const _DashboardContent({required this.stats});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        DashboardDetailCard(
          title: 'Utenti',
          value: '${stats.totalUsers}',
          accentColor: AppColors.primary,
          details: [
            DashboardDetailItem('Attivi', stats.activeUsers, AppColors.success),
            DashboardDetailItem(
              'Bloccati/Standby',
              stats.blockedUsers,
              AppColors.warning,
            ),
            DashboardDetailItem(
              'Cancellati',
              stats.deletedUsers,
              AppColors.error,
            ),
            DashboardDetailItem(
              'Mese',
              stats.newUsersThisMonth,
              AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 12),
        DashboardDetailCard(
          title: 'Aziende',
          value: '${stats.totalCompanies}',
          accentColor: AppColors.primary,
        ),
        const SizedBox(height: 12),
        DashboardDetailCard(
          title: 'Corsi',
          value: '${stats.totalCourses}',
          accentColor: AppColors.primary,
        ),
        const SizedBox(height: 12),
        DashboardDetailCard(
          title: 'Candidature',
          value: '${stats.totalApplications}',
          accentColor: AppColors.primary,
        ),
        const SizedBox(height: 12),
        DashboardDetailCard(
          title: 'Offerte Job',
          value: '${stats.totalJobOffers}',
          accentColor: AppColors.primary,
          details: [
            DashboardDetailItem(
              'Attive',
              stats.activeJobOffers,
              AppColors.success,
            ),
            DashboardDetailItem(
              'In attesa',
              stats.pendingJobOffers,
              AppColors.warning,
            ),
            DashboardDetailItem(
              'Bloccate',
              stats.blockedJobOffers,
              AppColors.error,
            ),
            DashboardDetailItem(
              'Mese',
              stats.newJobOffersThisMonth,
              AppColors.warning,
            ),
            DashboardDetailItem(
              'Scadute',
              stats.expiredJobOffers,
              AppColors.textMuted,
            ),
          ],
        ),
        const SizedBox(height: 12),
        DashboardDetailCard(
          title: 'Role Play',
          value: '${stats.totalRoleplay}',
          accentColor: AppColors.primary,
        ),
      ],
    );
  }
}
