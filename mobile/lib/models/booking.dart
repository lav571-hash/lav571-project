import 'package:json_annotation/json_annotation.dart';
import 'course.dart';
import 'user.dart';

part 'booking.g.dart';

enum BookingStatus {
  @JsonValue('pending_payment')
  pendingPayment,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('expired')
  expired,
}

@JsonSerializable()
class Booking {
  final String id;
  final String studentId;
  final User? student;
  final String courseId;
  final Course? course;
  final BookingStatus status;
  final DateTime? paymentConfirmedAt;
  final String? cancelReason;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.studentId,
    this.student,
    required this.courseId,
    this.course,
    required this.status,
    this.paymentConfirmedAt,
    this.cancelReason,
    this.expiresAt,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);
  Map<String, dynamic> toJson() => _$BookingToJson(this);

  String get statusLabel {
    switch (status) {
      case BookingStatus.pendingPayment:
        return 'Ожидает оплаты';
      case BookingStatus.confirmed:
        return 'Подтверждено';
      case BookingStatus.cancelled:
        return 'Отменено';
      case BookingStatus.expired:
        return 'Бронь истекла';
    }
  }

  bool get canStudentCancel => status == BookingStatus.pendingPayment;
}
