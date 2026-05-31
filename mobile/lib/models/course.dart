import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'course.g.dart';

enum CourseLevel {
  @JsonValue('beginner')
  beginner,
  @JsonValue('intermediate')
  intermediate,
  @JsonValue('advanced')
  advanced,
}

enum CourseType {
  @JsonValue('single')
  single,
  @JsonValue('program')
  program,
}

enum CourseStatus {
  @JsonValue('draft')
  draft,
  @JsonValue('published')
  published,
  @JsonValue('archived')
  archived,
}

@JsonSerializable()
class Session {
  final String id;
  final String courseId;
  final DateTime startsAt;
  final int durationMin;
  final String? location;

  const Session({
    required this.id,
    required this.courseId,
    required this.startsAt,
    required this.durationMin,
    this.location,
  });

  factory Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);
  Map<String, dynamic> toJson() => _$SessionToJson(this);
}

@JsonSerializable()
class Material {
  final String id;
  final String courseId;
  final String kind;
  final String title;
  final String url;
  final int order;

  const Material({
    required this.id,
    required this.courseId,
    required this.kind,
    required this.title,
    required this.url,
    required this.order,
  });

  factory Material.fromJson(Map<String, dynamic> json) =>
      _$MaterialFromJson(json);
  Map<String, dynamic> toJson() => _$MaterialToJson(this);
}

@JsonSerializable()
class Course {
  final String id;
  final String title;
  final String? description;
  final CourseLevel level;
  final CourseType type;
  final String teacherId;
  final User? teacher;
  final int capacity;
  final double price;
  final String? photoUrl;
  final String? program;
  final CourseStatus status;
  final List<Session>? sessions;
  final List<Material>? materials;
  final DateTime createdAt;

  const Course({
    required this.id,
    required this.title,
    this.description,
    required this.level,
    required this.type,
    required this.teacherId,
    this.teacher,
    required this.capacity,
    required this.price,
    this.photoUrl,
    this.program,
    required this.status,
    this.sessions,
    this.materials,
    required this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);
  Map<String, dynamic> toJson() => _$CourseToJson(this);

  String get levelLabel {
    switch (level) {
      case CourseLevel.beginner:
        return 'Начинающий';
      case CourseLevel.intermediate:
        return 'Средний';
      case CourseLevel.advanced:
        return 'Продвинутый';
    }
  }

  String get typeLabel {
    switch (type) {
      case CourseType.single:
        return 'Разовое занятие';
      case CourseType.program:
        return 'Программа';
    }
  }

  String get priceLabel => '${price.toStringAsFixed(0)} ₽';
}
