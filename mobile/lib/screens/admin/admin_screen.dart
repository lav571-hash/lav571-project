import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/courses_provider.dart';
import '../../providers/users_provider.dart';
import '../../models/booking.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import 'create_user_dialog.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);

    return userAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
      error: (_, __) => const Center(child: Text('Ошибка')),
      data: (user) {
        if (user == null ||
            (user.role != UserRole.admin && user.role != UserRole.teacher)) {
          return const Center(
            child: Text('Доступ запрещён',
                style: TextStyle(color: Colors.white)),
          );
        }
        return _AdminContent(user: user);
      },
    );
  }
}

class _AdminContent extends ConsumerWidget {
  final User user;
  const _AdminContent({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = user.role == UserRole.admin;
    final tabCount = isAdmin ? 4 : 2;

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAdmin ? 'Администратор' : 'Преподаватель'),
          bottom: TabBar(
            indicatorColor: AppTheme.gold,
            labelColor: AppTheme.gold,
            unselectedLabelColor: const Color(0xFF888888),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              const Tab(text: 'Записи'),
              const Tab(text: 'Курсы'),
              if (isAdmin) const Tab(text: 'Пользователи'),
              if (isAdmin) const Tab(text: 'Настройки'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookingsTab(),
            _CoursesTab(),
            if (isAdmin) _UsersTab(),
            if (isAdmin) _SettingsTab(),
          ],
        ),
      ),
    );
  }
}

// ── Вкладка Записи ───────────────────────────────────────────────────────────

class _BookingsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(allBookingsProvider);

    return bookingsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
      data: (bookings) {
        if (bookings.isEmpty) {
          return const Center(
            child: Text('Записей нет',
                style: TextStyle(color: Color(0xFF888888))),
          );
        }
        final pending = bookings
            .where((b) => b.status == BookingStatus.pendingPayment)
            .toList();
        final others = bookings
            .where((b) => b.status != BookingStatus.pendingPayment)
            .toList();

        return RefreshIndicator(
          color: AppTheme.gold,
          onRefresh: () async => ref.refresh(allBookingsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                _SectionHeader(title: 'Ожидают оплаты (${pending.length})'),
                const SizedBox(height: 8),
                ...pending.map((b) => _AdminBookingCard(booking: b)),
                const SizedBox(height: 20),
              ],
              if (others.isNotEmpty) ...[
                const _SectionHeader(title: 'Остальные'),
                const SizedBox(height: 8),
                ...others.map((b) => _AdminBookingCard(booking: b)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AdminBookingCard extends ConsumerWidget {
  final Booking booking;
  const _AdminBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.student?.fullName ?? 'Ученик',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    Text(
                      booking.student?.email ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  booking.statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Курс: ${booking.course?.title ?? booking.courseId}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
          if (booking.status == BookingStatus.pendingPayment) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmPayment(context, ref),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Подтвердить оплату'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => _cancelBooking(context, ref),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.error),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Отменить',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ] else if (booking.status == BookingStatus.confirmed) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: () => _cancelBooking(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side:
                      BorderSide(color: Theme.of(context).colorScheme.error),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Отменить запись',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmPayment(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(bookingActionsProvider).confirmPayment(booking.id);
      // ignore: unused_result
      ref.refresh(allBookingsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Оплата подтверждена'),
              backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _cancelBooking(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(bookingActionsProvider).cancelBooking(booking.id);
      // ignore: unused_result
      ref.refresh(allBookingsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Color _statusColor(BookingStatus s) {
    switch (s) {
      case BookingStatus.pendingPayment:
        return const Color(0xFFE5A84C);
      case BookingStatus.confirmed:
        return const Color(0xFF4CAF7D);
      case BookingStatus.cancelled:
        return const Color(0xFFCF6679);
      case BookingStatus.expired:
        return const Color(0xFF888888);
    }
  }
}

// ── Вкладка Курсы ────────────────────────────────────────────────────────────

class _CoursesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(allCoursesProvider);

    return Scaffold(
      body: coursesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (courses) => RefreshIndicator(
          color: AppTheme.gold,
          onRefresh: () async => ref.refresh(allCoursesProvider),
          child: courses.isEmpty
              ? const Center(
                  child: Text('Курсов нет. Создайте первый!',
                      style: TextStyle(color: Color(0xFF888888))),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final c = courses[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.title,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  '${c.levelLabel} · ${c.priceLabel} · ${c.sessions?.length ?? 0} зан.',
                                  style: const TextStyle(
                                      color: Color(0xFF888888),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          _StatusBadge(status: c.status.name),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/courses/create'),
        backgroundColor: AppTheme.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Новый курс',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Вкладка Пользователи ─────────────────────────────────────────────────────

class _UsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      body: usersAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (users) {
          final admins =
              users.where((u) => u.role == UserRole.admin).toList();
          final teachers =
              users.where((u) => u.role == UserRole.teacher).toList();
          final students =
              users.where((u) => u.role == UserRole.student).toList();

          return RefreshIndicator(
            color: AppTheme.gold,
            onRefresh: () async => ref.refresh(allUsersProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              children: [
                if (admins.isNotEmpty) ...[
                  _SectionHeader(title: 'Администраторы (${admins.length})'),
                  const SizedBox(height: 8),
                  ...admins.map((u) => _UserCard(user: u)),
                  const SizedBox(height: 20),
                ],
                if (teachers.isNotEmpty) ...[
                  _SectionHeader(
                      title: 'Преподаватели (${teachers.length})'),
                  const SizedBox(height: 8),
                  ...teachers.map((u) => _UserCard(user: u)),
                  const SizedBox(height: 20),
                ],
                if (students.isNotEmpty) ...[
                  _SectionHeader(title: 'Ученики (${students.length})'),
                  const SizedBox(height: 8),
                  ...students.map((u) => _UserCard(user: u)),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await showDialog<User>(
            context: context,
            builder: (_) => const CreateUserDialog(),
          );
          if (result != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('Пользователь «${result.fullName}» создан'),
              backgroundColor: AppTheme.success,
            ));
          }
        },
        backgroundColor: AppTheme.gold,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Добавить',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final User user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleColor = _roleColor(user.role);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: roleColor.withAlpha(30),
            child: Text(
              user.fullName.isNotEmpty
                  ? user.fullName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(user.email,
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: roleColor.withAlpha(20),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              user.displayRole,
              style: TextStyle(
                  color: roleColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(UserRole r) {
    switch (r) {
      case UserRole.admin:
        return AppTheme.gold;
      case UserRole.teacher:
        return const Color(0xFF4CAF7D);
      case UserRole.student:
        return const Color(0xFF6B9EE5);
    }
  }
}

// ── Вкладка Настройки ────────────────────────────────────────────────────────

class _SettingsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  final _hoursCtrl = TextEditingController(text: '24');
  bool _saving = false;

  @override
  void dispose() {
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiClientProvider).put('/settings/booking_hold_hours',
          data: {'value': _hoursCtrl.text.trim()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Настройки сохранены'),
            backgroundColor: AppTheme.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Автоснятие брони',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              const SizedBox(height: 4),
              const Text(
                'Через сколько часов неоплаченная бронь снимается автоматически',
                style: TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _hoursCtrl,
                decoration: const InputDecoration(
                  labelText: 'Часов до снятия',
                  suffixText: 'ч',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44)),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black)))
                    : const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Общие виджеты ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final data = {
      'draft': ('Черновик', const Color(0xFF888888)),
      'published': ('Опубликован', const Color(0xFF4CAF7D)),
      'archived': ('Архив', const Color(0xFF555555)),
    };
    final (label, color) =
        data[status] ?? (status, const Color(0xFF888888));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
