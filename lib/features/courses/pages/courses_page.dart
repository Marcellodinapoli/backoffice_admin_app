import 'package:flutter/material.dart';

import '../../../models/course.dart';
import '../../../services/firebase/courses_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/section_header.dart';
import '../widgets/course_card.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Corsi',
          subtitle: 'Formazione Sollecito e Recupero',
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sollecito'),
            Tab(text: 'Recupero'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _CourseList(category: 'Sollecito'),
              _CourseList(category: 'Recupero'),
            ],
          ),
        ),
      ],
    );
  }
}

class _CourseList extends StatelessWidget {
  final String category;

  const _CourseList({required this.category});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Course>>(
      stream: CoursesService.instance.watchByCategory(category),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const LoadingView(message: 'Caricamento corsi...');
        }
        if (snapshot.hasError) {
          return ErrorView(message: 'Errore: ${snapshot.error}');
        }

        final courses = snapshot.data ?? [];
        if (courses.isEmpty) {
          return EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'Nessun corso in $category',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: courses.length,
          itemBuilder: (_, i) => CourseCard(course: courses[i]),
        );
      },
    );
  }
}
