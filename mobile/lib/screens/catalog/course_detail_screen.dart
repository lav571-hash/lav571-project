import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/courses_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() =>
      _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _book() async {
    final user = ref.read(authProvider).value;
    if (user == null) {
      context.push('/login');
      return;
    }
    if (user.role != UserRole.student) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Только ученики могут записываться на курсы')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Подтверждение записи'),
        content: const Text(
          'После записи место будет забронировано. Оплату необходимо произвести вне приложения и подтвердить у администратора.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Записаться'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(bookingActionsProvider).createBooking(widget.courseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы успешно записались! Ожидайте подтверждения оплаты.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка записи: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));

    return Scaffold(
      body: courseAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (course) => CustomScrollView(
          slivers: [
            _AppBar(course: course),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _CourseHeader(course: course),
                  _TabBar(controller: _tab),
                  _TabViews(tab: _tab, course: course),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: courseAsync.maybeWhen(
        data: (course) => _BookingBar(course: course, onBook: _book),
        orElse: () => null,
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final Course course;

  const _AppBar({required this.course});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 16),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: course.photoUrl != null
            ? Image.network(course.photoUrl!, fit: BoxFit.cover)
            : Container(
                color: AppTheme.surfaceVariant,
                child: const Center(
                  child: Icon(Icons.content_cut,
                      size: 64, color: Color(0xFF444444)),
                ),
              ),
      ),
    );
  }
}

class _CourseHeader extends StatelessWidget {
  final Course course;

  const _CourseHeader({required this.course});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _chip(course.levelLabel,
                  _levelColor(course.level)),
              const SizedBox(width: 8),
              _chip(course.typeLabel, const Color(0xFF888888)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            course.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (course.teacher != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 16, color: Color(0xFF888888)),
                const SizedBox(width: 4),
                Text(
                  course.teacher!.fullName,
                  style: const TextStyle(
                      color: Color(0xFF888888), fontSize: 14),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(
                  icon: Icons.payments_outlined,
                  value: course.priceLabel,
                  label: 'Стоимость',
                ),
                _divider(),
                _stat(
                  icon: Icons.people_outline,
                  value: '${course.capacity}',
                  label: 'Мест в группе',
                ),
                _divider(),
                _stat(
                  icon: Icons.calendar_month_outlined,
                  value: '${course.sessions?.length ?? 0}',
                  label: 'Занятий',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _stat({required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.gold, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF888888))),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 40,
      width: 1,
      color: const Color(0xFF2A2A2A),
    );
  }

  Color _levelColor(CourseLevel l) {
    switch (l) {
      case CourseLevel.beginner:
        return const Color(0xFF4CAF7D);
      case CourseLevel.intermediate:
        return const Color(0xFFE5A84C);
      case CourseLevel.advanced:
        return const Color(0xFFCF6679);
    }
  }
}

class _TabBar extends StatelessWidget {
  final TabController controller;

  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      indicatorColor: AppTheme.gold,
      labelColor: AppTheme.gold,
      unselectedLabelColor: const Color(0xFF888888),
      tabs: const [
        Tab(text: 'Описание'),
        Tab(text: 'Расписание'),
        Tab(text: 'Программа'),
      ],
    );
  }
}

class _TabViews extends StatelessWidget {
  final TabController tab;
  final Course course;

  const _TabViews({required this.tab, required this.course});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: TabBarView(
        controller: tab,
        children: [
          _DescriptionTab(course: course),
          _ScheduleTab(sessions: course.sessions ?? []),
          _ProgramTab(program: course.program),
        ],
      ),
    );
  }
}

class _DescriptionTab extends StatelessWidget {
  final Course course;

  const _DescriptionTab({required this.course});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Text(
        course.description ?? 'Описание отсутствует',
        style: const TextStyle(
          color: Color(0xFFCCCCCC),
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  final List<Session> sessions;

  const _ScheduleTab({required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const Center(
        child: Text('Расписание ещё не добавлено',
            style: TextStyle(color: Color(0xFF888888))),
      );
    }

    final fmt = DateFormat('d MMMM yyyy, HH:mm', 'ru');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final s = sessions[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fmt.format(s.startsAt.toLocal()),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${s.durationMin} мин${s.location != null ? ' · ${s.location}' : ''}',
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgramTab extends StatelessWidget {
  final String? program;

  const _ProgramTab({this.program});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Text(
        program ?? 'Программа курса ещё не добавлена',
        style: const TextStyle(
          color: Color(0xFFCCCCCC),
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }
}

class _BookingBar extends StatelessWidget {
  final Course course;
  final VoidCallback onBook;

  const _BookingBar({required this.course, required this.onBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.priceLabel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.gold,
                ),
              ),
              const Text(
                'Оплата вне приложения',
                style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: onBook,
              child: const Text('Записаться'),
            ),
          ),
        ],
      ),
    );
  }
}
