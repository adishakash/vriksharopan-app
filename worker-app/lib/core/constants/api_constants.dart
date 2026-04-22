class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.vrisharopan.in/api';

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';

  // Worker
  static const String dashboard = '/workers/dashboard';
  static const String orders = '/workers/orders';
  static const String earnings = '/workers/earnings';
  static const String checkIn = '/workers/attendance/check-in';
  static const String checkOut = '/workers/attendance/check-out';
  static const String syncOffline = '/workers/sync';
  static const String fcmToken = '/customers/fcm-token';

  // Trees
  static const String trees = '/trees';
}
