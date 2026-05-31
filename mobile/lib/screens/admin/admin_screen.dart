import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/courses_provider.dart';
import '../../models/booking.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';

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
        if (user == null || (user.role != UserRole.admin && user.role != UserRole.teacher)) {
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
    return DefaultTabController(
      length: user.role == UserRole.admin ? 3 : 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(user.role == UserRole.admin
              ? 'Панель администратора'
              : 'Панель преподавателя'),
          bottom: TabBar(
            indicatorColor: AppTheme.gold,
            labelColor: AppTheme.gold,
            unselectedLabelColor: const Color(0xFF888888),
            isScrollable: user.role == UserRole.admin,
            tabs: [
              const Tab(text: 'Записи'),
              const Tab(text: 'Курсы'),
              if (user.role == UserRole.admin) const Tab(text: 'Настройки'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookingsTab(),
            _CoursesTab(),
            if (user.role == UserRole.admin) _SettingsTab(),
          ],
        ),
      ),
    );
  }
}

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
        final others =
            bookings.where((b) => b.status != BookingStatus.pendingPayment).toList();

        return RefreshIndicator(
          color: AppTheme.gold,
          onRefresh: () async => ref.refresh(allBookingsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                _SectionHeader(
                    title: 'Ожидают оплаты (${pending.length})'),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    child: const Text('Отменить', style: TextStyle(fontSize: 13)),
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
                  side: BorderSide(
                      color: Theme.of(context).colorScheme.error),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text('Отменить запись', style: TextStyle(fontSize: 13)),
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
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
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

class _CoursesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(allCoursesProvider);

    return coursesAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppTheme.gold)),
      error: (e, _) => Center(child: Text('Ошибка: $e')),
      data: (courses) => RefreshIndicator(
        color: AppTheme.gold,
        onRefresh: () async => ref.refresh(allCoursesProvider),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
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
                                fontWeight: FontWeight.w600)),
                        Text(
                          '${c.levelLabel} · ${c.priceLabel}',
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 12),
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
    );
  }
}

class _SettingsTab extends StatelessWidget {
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
              const Text(
                'Автоснятие брони',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
              const SizedBox(height: 4),
              const Text(
                'Количество часов, через которые неоплаченная бронь снимается автоматически',
                style: TextStyle(color: Color(0xFF888888), fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: '24',
                decoration: const InputDecoration(
                  labelText: 'Часов',
                  suffixText: 'ч',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF888888),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final labels = {
      'draft': ('Черновик', const Color(0xFF888888)),
      'published': ('Опубликован', const Color(0xFF4CAF7D)),
      'archived': ('Архив', const Color(0xFF555555)),
    };
    final (label, color) = labels[status] ?? (status, const Color(0xFF888888));

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
