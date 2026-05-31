import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/course.dart';
import '../theme/app_theme.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;

  const CourseCard({super.key, required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CourseImage(photoUrl: course.photoUrl),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _LevelChip(level: course.level),
                      const SizedBox(width: 6),
                      _TypeChip(type: course.type),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (course.teacher != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      course.teacher!.fullName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        course.priceLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.gold,
                        ),
                      ),
                      _SeatsInfo(capacity: course.capacity),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseImage extends StatelessWidget {
  final String? photoUrl;

  const _CourseImage({this.photoUrl});

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return SizedBox(
        height: 160,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => const _PlaceholderImage(),
          errorWidget: (_, __, ___) => const _PlaceholderImage(),
        ),
      );
    }
    return const _PlaceholderImage();
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      color: AppTheme.surfaceVariant,
      child: const Center(
        child: Icon(Icons.content_cut, size: 40, color: Color(0xFF555555)),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final CourseLevel level;

  const _LevelChip({required this.level});

  @override
  Widget build(BuildContext context) {
    final colors = {
      CourseLevel.beginner: const Color(0xFF4CAF7D),
      CourseLevel.intermediate: const Color(0xFFE5A84C),
      CourseLevel.advanced: const Color(0xFFCF6679),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (colors[level] ?? Colors.grey).withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: (colors[level] ?? Colors.grey).withAlpha(80)),
      ),
      child: Text(
        _label(level),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colors[level] ?? Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _label(CourseLevel l) {
    switch (l) {
      case CourseLevel.beginner:
        return 'НАЧИНАЮЩИЙ';
      case CourseLevel.intermediate:
        return 'СРЕДНИЙ';
      case CourseLevel.advanced:
        return 'ПРОДВИНУТЫЙ';
    }
  }
}

class _TypeChip extends StatelessWidget {
  final CourseType type;

  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type == CourseType.single ? 'РАЗОВОЕ' : 'ПРОГРАММА',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF888888),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SeatsInfo extends StatelessWidget {
  final int capacity;

  const _SeatsInfo({required this.capacity});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.people_outline, size: 14, color: Color(0xFF888888)),
        const SizedBox(width: 4),
        Text(
          'до $capacity мест',
          style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
        ),
      ],
    );
  }
}
