// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Booking _$BookingFromJson(Map<String, dynamic> json) => Booking(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      student: json['student'] == null
          ? null
          : User.fromJson(json['student'] as Map<String, dynamic>),
      courseId: json['courseId'] as String,
      course: json['course'] == null
          ? null
          : Course.fromJson(json['course'] as Map<String, dynamic>),
      status: $enumDecode(_$BookingStatusEnumMap, json['status']),
      paymentConfirmedAt: json['paymentConfirmedAt'] == null
          ? null
          : DateTime.parse(json['paymentConfirmedAt'] as String),
      cancelReason: json['cancelReason'] as String?,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$BookingToJson(Booking instance) => <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'student': instance.student?.toJson(),
      'courseId': instance.courseId,
      'course': instance.course?.toJson(),
      'status': _$BookingStatusEnumMap[instance.status]!,
      'paymentConfirmedAt': instance.paymentConfirmedAt?.toIso8601String(),
      'cancelReason': instance.cancelReason,
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$BookingStatusEnumMap = {
  BookingStatus.pendingPayment: 'pending_payment',
  BookingStatus.confirmed: 'confirmed',
  BookingStatus.cancelled: 'cancelled',
  BookingStatus.expired: 'expired',
};
