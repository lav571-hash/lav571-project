import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../providers/courses_provider.dart';
import '../../providers/users_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/loading_button.dart';

class CreateCourseScreen extends ConsumerStatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  ConsumerState<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends ConsumerState<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _programCtrl = TextEditingController();

  CourseLevel _level = CourseLevel.beginner;
  CourseType _type = CourseType.single;
  String? _teacherId;
  bool _loading = false;
  String? _error;

  // Добавленные занятия
  final List<_SessionDraft> _sessions = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _capacityCtrl.dispose();
    _programCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_teacherId == null) {
      setState(() => _error = 'Выберите преподавателя');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      final svc = ref.read(coursesServiceProvider);

      // 1. Создать курс
      final course = await svc.createCourse({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'level': _level.name,
        'type': _type.name,
        'teacherId': _teacherId,
        'capacity': int.parse(_capacityCtrl.text.trim()),
        'price': double.parse(_priceCtrl.text.trim().replaceAll(',', '.')),
        if (_programCtrl.text.isNotEmpty) 'program': _programCtrl.text.trim(),
      });

      // 2. Добавить занятия
      for (final s in _sessions) {
        await svc.addSession(course.id, {
          'startsAt': s.startsAt.toUtc().toIso8601String(),
          'durationMin': s.durationMin,
          if (s.location.isNotEmpty) 'location': s.location,
        });
      }

      // 3. Опубликовать если есть занятия
      if (_sessions.isNotEmpty) {
        await svc.publishCourse(course.id);
      }

      // ignore: unused_result
      ref.refresh(allCoursesProvider);
      // ignore: unused_result
      ref.refresh(publishedCoursesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_sessions.isNotEmpty
              ? 'Курс «${course.title}» создан и опубликован!'
              : 'Курс «${course.title}» создан (черновик). Добавьте занятия и опубликуйте.'),
          backgroundColor: AppTheme.success,
        ));
        context.pop();
      }
    } catch (e) {
      setState(() => _error = 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addSession() async {
    final result = await showDialog<_SessionDraft>(
      context: context,
      builder: (_) => _AddSessionDialog(index: _sessions.length + 1),
    );
    if (result != null) setState(() => _sessions.add(result));
  }

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(teachersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый курс'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                _ErrorBox(message: _error!),
                const SizedBox(height: 16),
              ],

              // ── Основная информация ──────────────────────────
              _SectionTitle(title: 'Основная информация'),
              const SizedBox(height: 12),

              AppTextField(
                controller: _titleCtrl,
                label: 'Название курса',
                prefixIcon: Icons.title,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Введите название'
                    : null,
              ),
              const SizedBox(height: 14),

              AppTextField(
                controller: _descCtrl,
                label: 'Описание',
                maxLines: 3,
                validator: null,
              ),
              const SizedBox(height: 14),

              AppTextField(
                controller: _programCtrl,
                label: 'Программа курса',
                maxLines: 4,
                hint: 'Темы, которые будут изучены...',
                validator: null,
              ),
              const SizedBox(height: 20),

              // ── Параметры ────────────────────────────────────
              _SectionTitle(title: 'Параметры'),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: AppTextField(
                    controller: _priceCtrl,
                    label: 'Цена (₽)',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.payments_outlined,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Введите цену';
                      if (double.tryParse(v.replaceAll(',', '.')) == null)
                        return 'Неверный формат';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _capacityCtrl,
                    label: 'Мест в группе',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.people_outline,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Укажите кол-во';
                      if (int.tryParse(v) == null || int.parse(v) < 1)
                        return 'Минимум 1';
                      return null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              // ── Уровень ──────────────────────────────────────
              _SectionTitle(title: 'Уровень подготовки'),
              const SizedBox(height: 10),
              _SegmentedSelector<CourseLevel>(
                options: const [
                  (CourseLevel.beginner, 'Начинающий'),
                  (CourseLevel.intermediate, 'Средний'),
                  (CourseLevel.advanced, 'Продвинутый'),
                ],
                selected: _level,
                onChanged: (v) => setState(() => _level = v),
              ),
              const SizedBox(height: 20),

              // ── Тип ──────────────────────────────────────────
              _SectionTitle(title: 'Тип курса'),
              const SizedBox(height: 10),
              _SegmentedSelector<CourseType>(
                options: const [
                  (CourseType.single, 'Разовое занятие'),
                  (CourseType.program, 'Программа'),
                ],
                selected: _type,
                onChanged: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: 20),

              // ── Преподаватель ─────────────────────────────────
              _SectionTitle(title: 'Преподаватель'),
              const SizedBox(height: 10),
              teachersAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppTheme.gold)),
                error: (e, _) => Text('Ошибка загрузки: $e',
                    style: const TextStyle(color: Color(0xFF888888))),
                data: (teachers) => teachers.isEmpty
                    ? _EmptyTeachersHint()
                    : _TeacherDropdown(
                        teachers: teachers,
                        selected: _teacherId,
                        onChanged: (v) => setState(() => _teacherId = v),
                      ),
              ),
              const SizedBox(height: 24),

              // ── Занятия ───────────────────────────────────────
              Row(
                children: [
                  _SectionTitle(title: 'Занятия (${_sessions.length})'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addSession,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Добавить'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_sessions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: const Center(
                    child: Text(
                      'Добавьте хотя бы одно занятие, чтобы курс был опубликован',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                    ),
                  ),
                )
              else
                ..._sessions.asMap().entries.map((e) => _SessionTile(
                      index: e.key + 1,
                      session: e.value,
                      onRemove: () =>
                          setState(() => _sessions.removeAt(e.key)),
                    )),

              const SizedBox(height: 32),

              LoadingButton(
                onPressed: _submit,
                loading: _loading,
                label: _sessions.isNotEmpty
                    ? 'Создать и опубликовать'
                    : 'Создать черновик',
                icon: _sessions.isNotEmpty
                    ? Icons.rocket_launch_outlined
                    : Icons.save_outlined,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Диалог добавления занятия ────────────────────────────────────────────────

class _AddSessionDialog extends StatefulWidget {
  final int index;
  const _AddSessionDialog({required this.index});

  @override
  State<_AddSessionDialog> createState() => _AddSessionDialogState();
}

class _AddSessionDialogState extends State<_AddSessionDialog> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  int _duration = 120;
  final _locationCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '120');

  @override
  void dispose() {
    _locationCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppTheme.gold,
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: AppTheme.gold,
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMMM yyyy', 'ru');
    final startsAt = DateTime(
      _date.year, _date.month, _date.day, _time.hour, _time.minute,
    );

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Занятие ${widget.index}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Date picker
            _PickerRow(
              icon: Icons.calendar_month_outlined,
              label: 'Дата',
              value: dateFmt.format(_date),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),

            // Time picker
            _PickerRow(
              icon: Icons.access_time_outlined,
              label: 'Время начала',
              value: _time.format(context),
              onTap: _pickTime,
            ),
            const SizedBox(height: 12),

            // Duration
            Row(children: [
              const Icon(Icons.timer_outlined,
                  size: 20, color: Color(0xFF888888)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Длительность (мин)',
                    suffixText: 'мин',
                  ),
                  onChanged: (v) =>
                      setState(() => _duration = int.tryParse(v) ?? 120),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // Location
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 20, color: Color(0xFF888888)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Место проведения (необязательно)',
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _SessionDraft(
                      startsAt: startsAt,
                      durationMin: _duration > 0 ? _duration : 60,
                      location: _locationCtrl.text.trim(),
                    ),
                  ),
                  child: const Text('Добавить'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Вспомогательные виджеты ──────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );
}

class _SegmentedSelector<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const _SegmentedSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final (value, label) = o;
        final isSelected = selected == value;
        return GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.gold.withAlpha(20)
                  : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.gold : const Color(0xFF2A2A2A),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppTheme.gold : const Color(0xFF888888),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TeacherDropdown extends StatelessWidget {
  final List<User> teachers;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _TeacherDropdown({
    required this.teachers,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          hint: const Text('Выберите преподавателя',
              style: TextStyle(color: Color(0xFF555555))),
          dropdownColor: AppTheme.surface,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFF888888)),
          items: teachers.map((t) => DropdownMenuItem(
                value: t.id,
                child: Text(t.fullName,
                    style: const TextStyle(color: Colors.white)),
              )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _EmptyTeachersHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: Color(0xFF888888)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Преподавателей нет. Сначала создайте преподавателя во вкладке «Пользователи».',
              style: TextStyle(color: Color(0xFF888888), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final int index;
  final _SessionDraft session;
  final VoidCallback onRemove;

  const _SessionTile({
    required this.index,
    required this.session,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMMM yyyy, HH:mm', 'ru');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.gold.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text('$index',
                  style: const TextStyle(
                      color: AppTheme.gold, fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fmt.format(session.startsAt),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
                Text(
                  '${session.durationMin} мин'
                  '${session.location.isNotEmpty ? ' · ${session.location}' : ''}',
                  style: const TextStyle(
                      color: Color(0xFF888888), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Color(0xFF888888), size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF888888)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF888888))),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFF555555), size: 20),
          ],
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message,
          style: TextStyle(
              color: Theme.of(context).colorScheme.error, fontSize: 13)),
    );
  }
}

// ── Модель черновика занятия ──────────────────────────────────────────────────

class _SessionDraft {
  final DateTime startsAt;
  final int durationMin;
  final String location;

  const _SessionDraft({
    required this.startsAt,
    required this.durationMin,
    required this.location,
  });
}
