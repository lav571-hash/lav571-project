// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Session _$SessionFromJson(Map<String, dynamic> json) => Session(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      durationMin: (json['durationMin'] as num).toInt(),
      location: json['location'] as String?,
    );

Map<String, dynamic> _$SessionToJson(Session instance) => <String, dynamic>{
      'id': instance.id,
      'courseId': instance.courseId,
      'startsAt': instance.startsAt.toIso8601String(),
      'durationMin': instance.durationMin,
      'location': instance.location,
    };

Material _$MaterialFromJson(Map<String, dynamic> json) => Material(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      kind: json['kind'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      order: (json['order'] as num).toInt(),
    );

Map<String, dynamic> _$MaterialToJson(Material instance) => <String, dynamic>{
      'id': instance.id,
      'courseId': instance.courseId,
      'kind': instance.kind,
      'title': instance.title,
      'url': instance.url,
      'order': instance.order,
    };

Course _$CourseFromJson(Map<String, dynamic> json) => Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      level: $enumDecode(_$CourseLevelEnumMap, json['level']),
      type: $enumDecode(_$CourseTypeEnumMap, json['type']),
      teacherId: json['teacherId'] as String,
      teacher: json['teacher'] == null
          ? null
          : User.fromJson(json['teacher'] as Map<String, dynamic>),
      capacity: (json['capacity'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      photoUrl: json['photoUrl'] as String?,
      program: json['program'] as String?,
      status: $enumDecode(_$CourseStatusEnumMap, json['status']),
      sessions: (json['sessions'] as List<dynamic>?)
          ?.map((e) => Session.fromJson(e as Map<String, dynamic>))
          .toList(),
      materials: (json['materials'] as List<dynamic>?)
          ?.map((e) => Material.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'level': _$CourseLevelEnumMap[instance.level]!,
      'type': _$CourseTypeEnumMap[instance.type]!,
      'teacherId': instance.teacherId,
      'teacher': instance.teacher?.toJson(),
      'capacity': instance.capacity,
      'price': instance.price,
      'photoUrl': instance.photoUrl,
      'program': instance.program,
      'status': _$CourseStatusEnumMap[instance.status]!,
      'sessions': instance.sessions?.map((e) => e.toJson()).toList(),
      'materials': instance.materials?.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$CourseLevelEnumMap = {
  CourseLevel.beginner: 'beginner',
  CourseLevel.intermediate: 'intermediate',
  CourseLevel.advanced: 'advanced',
};

const _$CourseTypeEnumMap = {
  CourseType.single: 'single',
  CourseType.program: 'program',
};

const _$CourseStatusEnumMap = {
  CourseStatus.draft: 'draft',
  CourseStatus.published: 'published',
  CourseStatus.archived: 'archived',
};
