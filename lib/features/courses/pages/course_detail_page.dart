import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/course.dart';
import '../../../services/firebase/courses_service.dart';
import '../../../shared/widgets/loading_view.dart';

class CourseDetailPage extends StatelessWidget {
  final String courseId;

  const CourseDetailPage({super.key, required this.courseId});

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy HH:mm').format(date);

  void _copyLink(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copiato negli appunti')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Dettaglio corso'),
      ),
      body: StreamBuilder<Course?>(
        stream: CoursesService.instance.watchCourse(courseId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Errore: ${snapshot.error}'));
          }
          if (!snapshot.hasData) return const LoadingView();
          final course = snapshot.data;
          if (course == null) {
            return const Center(child: Text('Corso non trovato'));
          }

          final created = course.createdAt?.toDate();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          course.category,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (created != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Creato il ${_formatDate(created)}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (course.description.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            course.description,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (course.videoUrl != null && course.videoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _copyLink(context, course.videoUrl!),
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Copia link video'),
                  ),
                ],
                if (course.contents.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Contenuti',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...course.contents.map(
                    (item) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.article_outlined),
                        title: Text(item),
                      ),
                    ),
                  ),
                ],
                if (course.attachments.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Allegati',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...course.attachments.map((att) {
                    final name = att['name']?.toString() ?? 'Allegato';
                    final url = att['url']?.toString() ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: Text(name),
                        trailing: url.isNotEmpty
                            ? const Icon(Icons.open_in_new, size: 18)
                            : null,
                        onTap: url.isNotEmpty
                            ? () => _copyLink(context, url)
                            : null,
                      ),
                    );
                  }),
                ],
                if (course.hasQuiz) ...[
                  const SizedBox(height: 20),
                  Card(
                    color: AppColors.accentSoft,
                    child: ListTile(
                      leading: const Icon(Icons.quiz_outlined, color: AppColors.primary),
                      title: const Text(
                        'Quiz disponibile',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        course.quiz?['fileName']?.toString() ?? 'Domande incluse',
                      ),
                    ),
                  ),
                ],
                if (course.tags.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: course.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor: AppColors.surfaceVariant,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
