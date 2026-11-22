import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/core/services/app_exception.dart';
import 'package:college_canteen/features/food/data/menu_repository.dart';
import 'package:college_canteen/features/food/models/food_item.dart';

void main() {
  const itemVendor1 = MenuItem(
    id: 'item-v1',
    name: 'Item V1',
    price: 30,
    vendorId: 'vendor-1',
    vendorName: 'Vendor One',
  );

  const itemVendor2 = MenuItem(
    id: 'item-v2',
    name: 'Item V2',
    price: 40,
    vendorId: 'vendor-2',
    vendorName: 'Vendor Two',
  );

  late InMemoryMenuRepository menuRepo;

  setUp(() {
    menuRepo = InMemoryMenuRepository(initialItems: [itemVendor1]);
  });

  group('MenuRepository vendor guard (upsertAs and deleteAs)', () {
    test('upsertAs with own vendorId succeeds', () async {
      const newItem = MenuItem(
        id: 'new-v1',
        name: 'New Item V1',
        price: 50,
        vendorId: 'vendor-1',
        vendorName: 'Vendor One',
      );

      await menuRepo.upsertAs('vendor-1', newItem);

      final found = menuRepo.currentItems.firstWhere((i) => i.id == 'new-v1');
      expect(found.name, 'New Item V1');
    });

    test('upsertAs with another vendor\'s item is rejected with AppException', () async {
      // Acting vendor is vendor-1, but item belongs to vendor-2
      expect(
        () => menuRepo.upsertAs('vendor-1', itemVendor2),
        throwsA(
          isA<AppException>().having(
            (e) => e.userMessage,
            'userMessage',
            'You can only manage your own items',
          ),
        ),
      );
    });

    test('upsertAs attempting to overwrite another vendor\'s existing item is rejected', () async {
      // Existing item belongs to vendor-1. vendor-2 attempts to overwrite it.
      const modifiedV1 = MenuItem(
        id: 'item-v1',
        name: 'Hijacked Item',
        price: 99,
        vendorId: 'vendor-2',
        vendorName: 'Vendor Two',
      );

      expect(
        () => menuRepo.upsertAs('vendor-2', modifiedV1),
        throwsA(
          isA<AppException>().having(
            (e) => e.userMessage,
            'userMessage',
            'You can only manage your own items',
          ),
        ),
      );
    });

    test('deleteAs of another vendor\'s item is rejected with AppException', () async {
      // item-v1 belongs to vendor-1; vendor-2 tries to delete it
      expect(
        () => menuRepo.deleteAs('vendor-2', 'item-v1'),
        throwsA(
          isA<AppException>().having(
            (e) => e.userMessage,
            'userMessage',
            'You can only manage your own items',
          ),
        ),
      );

      // Verify item was not deleted
      expect(menuRepo.currentItems.any((i) => i.id == 'item-v1'), isTrue);
    });

    test('deleteAs with own vendorId succeeds', () async {
      await menuRepo.deleteAs('vendor-1', 'item-v1');
      expect(menuRepo.currentItems.any((i) => i.id == 'item-v1'), isFalse);
    });
  });
}
