import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/services/app_exception.dart';
import 'package:college_canteen/features/food/data/menu_repository.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';
import 'package:college_canteen/features/food/models/food_item.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/vendor/data/vendor_repository.dart';
import 'package:college_canteen/features/vendor/models/vendor_profile.dart';

void main() {
  late InMemoryVendorRepository vendorRepo;

  setUp(() {
    vendorRepo = InMemoryVendorRepository();
  });

  group('VendorRepository - core behavior', () {
    test('seeded default vendor exists with correct initial properties', () {
      expect(vendorRepo.currentVendors.length, 1);

      final defaultVendor = vendorRepo.byId(AppConfig.defaultVendorId);
      expect(defaultVendor, isNotNull);
      expect(defaultVendor?.vendorId, AppConfig.defaultVendorId);
      expect(defaultVendor?.businessName, AppConfig.defaultVendorName);
      expect(defaultVendor?.businessType, BusinessType.canteen);
      expect(defaultVendor?.isAcceptingOrders, isTrue);
      expect(defaultVendor?.analyticsOrderThreshold, AppConfig.defaultAnalyticsBatchSize);
      expect(vendorRepo.isAcceptingOrders(AppConfig.defaultVendorId), isTrue);
    });

    test('duplicate register is rejected with AppException', () async {
      const duplicateProfile = VendorProfile(
        vendorId: AppConfig.defaultVendorId,
        businessName: 'Duplicate Canteen',
        businessType: BusinessType.canteen,
        contactPhone: '9876543210',
      );

      expect(
        () => vendorRepo.register(duplicateProfile),
        throwsA(isA<AppException>()),
      );
    });

    test('update of an unknown vendor id fails with AppException', () async {
      const unknownProfile = VendorProfile(
        vendorId: 'non-existent-vendor',
        businessName: 'Ghost Shop',
        businessType: BusinessType.cafe,
        contactPhone: '9876543210',
      );

      expect(
        () => vendorRepo.update(unknownProfile),
        throwsA(isA<AppException>()),
      );
    });

    test('setAnalyticsThreshold clamps value to AppConfig min..max', () async {
      // Clamp to min (5)
      await vendorRepo.setAnalyticsThreshold(AppConfig.defaultVendorId, 2);
      expect(
        vendorRepo.byId(AppConfig.defaultVendorId)?.analyticsOrderThreshold,
        AppConfig.minAnalyticsBatchSize,
      );

      // Clamp to max (500)
      await vendorRepo.setAnalyticsThreshold(AppConfig.defaultVendorId, 900);
      expect(
        vendorRepo.byId(AppConfig.defaultVendorId)?.analyticsOrderThreshold,
        AppConfig.maxAnalyticsBatchSize,
      );

      // Normal value in range
      await vendorRepo.setAnalyticsThreshold(AppConfig.defaultVendorId, 100);
      expect(
        vendorRepo.byId(AppConfig.defaultVendorId)?.analyticsOrderThreshold,
        100,
      );
    });

    test('unknown vendor id returns isAcceptingOrders false', () {
      expect(vendorRepo.isAcceptingOrders('completely-unknown-id'), isFalse);
    });
  });

  group('VendorRepository integration with OrderRepository', () {
    test('closing the default vendor makes the order repository reject orders with the "not accepting orders" message', () async {
      const testItem = MenuItem(
        id: 'canteen-thali',
        name: 'Veg Thali',
        price: 80,
        vendorId: AppConfig.defaultVendorId,
        vendorName: AppConfig.defaultVendorName,
        isAvailable: true,
      );

      final menuRepo = InMemoryMenuRepository(initialItems: [testItem]);
      final orderRepo = InMemoryOrderRepository(
        menuRepository: menuRepo,
        isVendorOpen: vendorRepo.isAcceptingOrders,
      );

      // 1. Initially default vendor is accepting orders -> quote succeeds
      const placeRequest = PlaceOrderRequest(
        clientRequestId: 'req-vendor-test-1',
        customerId: 'cust-1',
        vendorId: AppConfig.defaultVendorId,
        lines: [('canteen-thali', 1)],
        locationId: 'aitr-b3-f2-r234',
        expectedTotal: 85, // 80 + 5 delivery
      );

      final quote = orderRepo.quote(placeRequest);
      expect(quote.grandTotal, 85);

      // 2. Close default vendor
      await vendorRepo.setAcceptingOrders(AppConfig.defaultVendorId, false);
      expect(vendorRepo.isAcceptingOrders(AppConfig.defaultVendorId), isFalse);

      // 3. Now order placement / quote must fail with "{vendorName} is not accepting orders right now"
      expect(
        () => orderRepo.placeOrder(placeRequest),
        throwsA(
          predicate((e) =>
              e is OrderValidationException &&
              e.userMessage == '${AppConfig.defaultVendorName} is not accepting orders right now'),
        ),
      );
    });
  });
}
