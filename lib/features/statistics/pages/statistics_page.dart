import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/dashboard_stats.dart';
import '../../../services/firebase/stats_service.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../widgets/stat_card.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
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
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Statistiche',
          subtitle: 'Panoramica piattaforma CreditPlanet',
          trailing: IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Aggiorna',
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingView(message: 'Calcolo statistiche...')
              : _error != null
                  ? ErrorView(
                      message: 'Errore: $_error',
                      onRetry: _load,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _StatsGrid(stats: _stats!),
                    ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cards = [
      StatCard(
        title: 'Utenti totali',
        value: '${stats.totalUsers}',
        icon: Icons.people_outline,
        color: AppColors.primary,
        background: AppColors.accentSoft,
      ),
      StatCard(
        title: 'Utenti attivi',
        value: '${stats.activeUsers}',
        icon: Icons.verified_user_outlined,
        color: AppColors.success,
        background: AppColors.successBg,
      ),
      StatCard(
        title: 'Utenti bloccati',
        value: '${stats.blockedUsers}',
        icon: Icons.block,
        color: AppColors.error,
        background: AppColors.errorBg,
      ),
      StatCard(
        title: 'Nuovi (mese)',
        value: '${stats.newUsersThisMonth}',
        icon: Icons.person_add_outlined,
        color: AppColors.info,
        background: AppColors.infoBg,
      ),
      StatCard(
        title: 'Aziende',
        value: '${stats.totalCompanies}',
        icon: Icons.business_outlined,
        color: AppColors.primary,
        background: AppColors.accentSoft,
      ),
      StatCard(
        title: 'Corsi',
        value: '${stats.totalCourses}',
        icon: Icons.menu_book_outlined,
        color: AppColors.warning,
        background: AppColors.warningBg,
      ),
      StatCard(
        title: 'Offerte attive',
        value: '${stats.activeJobOffers}',
        icon: Icons.work_outline,
        color: AppColors.success,
        background: AppColors.successBg,
      ),
      StatCard(
        title: 'Candidature',
        value: '${stats.totalApplications}',
        icon: Icons.assignment_outlined,
        color: AppColors.info,
        background: AppColors.infoBg,
      ),
      StatCard(
        title: 'Role Play',
        value: '${stats.totalRoleplay}',
        icon: Icons.record_voice_over_outlined,
        color: AppColors.primaryLight,
        background: AppColors.accentSoft,
      ),
      StatCard(
        title: 'Offerte in attesa',
        value: '${stats.pendingJobOffers}',
        icon: Icons.hourglass_empty,
        color: AppColors.warning,
        background: AppColors.warningBg,
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => cards[i],
    );
  }
}
