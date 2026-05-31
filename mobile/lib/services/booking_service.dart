import '../models/booking.dart';
import 'api_client.dart';

class BookingService {
  final ApiClient _client;

  BookingService(this._client);

  Future<Booking> createBooking(String courseId) async {
    final response = await _client.post('/bookings', data: {'courseId': courseId});
    return Booking.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Booking>> getMyBookings() async {
    final response = await _client.get('/bookings/my');
    final list = response.data as List<dynamic>;
    return list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Booking>> getAllBookings() async {
    final response = await _client.get('/bookings');
    final list = response.data as List<dynamic>;
    return list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Booking>> getBookingsByCourse(String courseId) async {
    final response = await _client.get('/bookings/course/$courseId');
    final list = response.data as List<dynamic>;
    return list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Booking> confirmPayment(String bookingId) async {
    final response = await _client.patch('/bookings/$bookingId/confirm-payment');
    return Booking.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Booking> cancelBooking(String bookingId, {String? reason}) async {
    final response = await _client.patch(
      '/bookings/$bookingId/cancel',
      data: {if (reason != null) 'reason': reason},
    );
    return Booking.fromJson(response.data as Map<String, dynamic>);
  }
}
