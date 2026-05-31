import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import 'auth_provider.dart';

final bookingServiceProvider = Provider<BookingService>(
  (ref) => BookingService(ref.watch(apiClientProvider)),
);

final myBookingsProvider = FutureProvider<List<Booking>>((ref) {
  return ref.watch(bookingServiceProvider).getMyBookings();
});

final allBookingsProvider = FutureProvider<List<Booking>>((ref) {
  return ref.watch(bookingServiceProvider).getAllBookings();
});

final bookingsByCourseProvider =
    FutureProvider.family<List<Booking>, String>((ref, courseId) {
  return ref.watch(bookingServiceProvider).getBookingsByCourse(courseId);
});

// Actions (non-reactive service wrapper for mutations)
final bookingActionsProvider = Provider<BookingService>(
  (ref) => ref.watch(bookingServiceProvider),
);
