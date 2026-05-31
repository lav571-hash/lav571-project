import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/courses_provider.dart';
import '../../models/course.dart';
import '../../widgets/course_card.dart';
import '../../theme/app_theme.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  CourseLevel? _filterLevel;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(publishedCoursesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            _SearchBar(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
            _LevelFilter(
              selected: _filterLevel,
              onChanged: (l) => setState(() => _filterLevel = l),
            ),
            Expanded(
              child: coursesAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppTheme.gold)),
                error: (e, _) => _ErrorState(onRetry: () => ref.refresh(publishedCoursesProvider)),
                data: (courses) {
                  final filtered = courses.where((c) {
                    final matchLevel =
                        _filterLevel == null || c.level == _filterLevel;
                    final matchSearch = _searchQuery.isEmpty ||
                        c.title.toLowerCase().contains(_searchQuery) ||
                        (c.description?.toLowerCase().contains(_searchQuery) ??
                            false);
                    return matchLevel && matchSearch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const _EmptyState();
                  }

                  return RefreshIndicator(
                    color: AppTheme.gold,
                    onRefresh: () async =>
                        ref.refresh(publishedCoursesProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => CourseCard(
                        course: filtered[i],
                        onTap: () =>
                            context.push('/courses/${filtered[i].id}'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.gold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.content_cut, color: Colors.black, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Каталог курсов',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Поиск курсов...',
          prefixIcon:
              const Icon(Icons.search, size: 20, color: Color(0xFF888888)),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear,
                      size: 18, color: Color(0xFF888888)),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
        ),
      ),
    );
  }
}

class _LevelFilter extends StatelessWidget {
  final CourseLevel? selected;
  final ValueChanged<CourseLevel?> onChanged;

  const _LevelFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _FilterChip(
            label: 'Все',
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Начинающий',
            selected: selected == CourseLevel.beginner,
            onTap: () => onChanged(CourseLevel.beginner),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Средний',
            selected: selected == CourseLevel.intermediate,
            onTap: () => onChanged(CourseLevel.intermediate),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Продвинутый',
            selected: selected == CourseLevel.advanced,
            onTap: () => onChanged(CourseLevel.advanced),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.gold : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.black : const Color(0xFFAAAAAA),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 56, color: Color(0xFF444444)),
          SizedBox(height: 12),
          Text(
            'Курсов не найдено',
            style: TextStyle(color: Color(0xFF888888), fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Color(0xFF888888)),
          const SizedBox(height: 12),
          const Text(
            'Ошибка загрузки',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
