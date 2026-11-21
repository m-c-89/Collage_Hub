abstract final class AppConfig {
  static const int minOrderSubtotal = 50;
  static const double taxRate = 0.0;
  static const int serviceCharge = 0;
  static const Duration paymentProcessingDelay = Duration(milliseconds: 1800);
  static const int defaultAnalyticsBatchSize = 60;
  static const int minAnalyticsBatchSize = 5;
  static const int maxAnalyticsBatchSize = 500;
  static const int batchTimeToleranceMinutes = 3;
  static const int maxBatchSize = 4;
  static const int maxActiveTripOrders = 6;
  static const int deliveryWindowMinutes = 5;
  static const bool kDemoMode = true;
  static const String demoVendorInviteCode = 'VENDOR-DEMO';
  static const String demoDeliveryInviteCode = 'DELIVERY-DEMO';
  static const String defaultVendorId = 'canteen';
  static const String defaultVendorName = 'College Canteen';
}
