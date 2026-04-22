class ApiConstants {
  ApiConstants._();

  // Change to your production URL before release
  static const String baseUrl = 'https://api.vrisharopan.in/api';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String changePassword = '/auth/change-password';

  // Customer
  static const String dashboard = '/customers/dashboard';
  static const String profile = '/customers/profile';
  static const String referrals = '/customers/referrals';
  static const String fcmToken = '/customers/fcm-token';

  // Trees
  static const String trees = '/trees';
  static const String giftTree = '/trees/gift';
  static const String treesMap = '/trees/map';

  // Payments
  static const String createSubscription = '/payments/create-subscription';
  static const String payments = '/payments';

  // Notifications
  static const String notifications = '/notifications';
  static const String markNotificationsRead = '/notifications/mark-read';
}
