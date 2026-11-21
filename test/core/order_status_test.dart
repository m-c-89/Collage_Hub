import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/domain/user_role.dart';

void main() {
  group('OrderStatus', () {
    test('labels are properly defined', () {
      expect(OrderStatus.placed.label, 'Placed');
      expect(OrderStatus.accepted.label, 'Accepted');
      expect(OrderStatus.preparing.label, 'Preparing');
      expect(OrderStatus.readyForPickup.label, 'Ready for Pickup');
      expect(OrderStatus.outForDelivery.label, 'Out for Delivery');
      expect(OrderStatus.delivered.label, 'Delivered');
      expect(OrderStatus.cancelled.label, 'Cancelled');
    });

    test('isTerminal is true only for delivered and cancelled', () {
      expect(OrderStatus.placed.isTerminal, isFalse);
      expect(OrderStatus.accepted.isTerminal, isFalse);
      expect(OrderStatus.preparing.isTerminal, isFalse);
      expect(OrderStatus.readyForPickup.isTerminal, isFalse);
      expect(OrderStatus.outForDelivery.isTerminal, isFalse);
      expect(OrderStatus.delivered.isTerminal, isTrue);
      expect(OrderStatus.cancelled.isTerminal, isTrue);
    });

    test('every allowed transition is true for its actor', () {
      // placed -> accepted (vendor)
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.placed,
          OrderStatus.accepted,
          UserRole.vendor,
        ),
        isTrue,
      );

      // placed -> cancelled (customer, vendor)
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.placed,
          OrderStatus.cancelled,
          UserRole.customer,
        ),
        isTrue,
      );
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.placed,
          OrderStatus.cancelled,
          UserRole.vendor,
        ),
        isTrue,
      );

      // accepted -> preparing (vendor)
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.accepted,
          OrderStatus.preparing,
          UserRole.vendor,
        ),
        isTrue,
      );

      // accepted -> cancelled (vendor)
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.accepted,
          OrderStatus.cancelled,
          UserRole.vendor,
        ),
        isTrue,
      );

      // preparing -> readyForPickup (vendor)
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.preparing,
          OrderStatus.readyForPickup,
          UserRole.vendor,
        ),
        isTrue,
      );

      // preparing -> cancelled (vendor)
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.preparing,
          OrderStatus.cancelled,
          UserRole.vendor,
        ),
        isTrue,
      );

      // readyForPickup -> outForDelivery (deliveryPartner)
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.readyForPickup,
          OrderStatus.outForDelivery,
          UserRole.deliveryPartner,
        ),
        isTrue,
      );

      // outForDelivery -> delivered (deliveryPartner)
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.outForDelivery,
          OrderStatus.delivered,
          UserRole.deliveryPartner,
        ),
        isTrue,
      );
    });

    test('wrong actor is false', () {
      // customer cannot accept
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.placed,
          OrderStatus.accepted,
          UserRole.customer,
        ),
        isFalse,
      );
      // deliveryPartner cannot accept
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.placed,
          OrderStatus.accepted,
          UserRole.deliveryPartner,
        ),
        isFalse,
      );

      // customer cannot prepare or mark ready
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.accepted,
          OrderStatus.preparing,
          UserRole.customer,
        ),
        isFalse,
      );
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.preparing,
          OrderStatus.readyForPickup,
          UserRole.customer,
        ),
        isFalse,
      );

      // customer and deliveryPartner cannot cancel accepted
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.accepted,
          OrderStatus.cancelled,
          UserRole.customer,
        ),
        isFalse,
      );
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.accepted,
          OrderStatus.cancelled,
          UserRole.deliveryPartner,
        ),
        isFalse,
      );

      // customer and deliveryPartner cannot cancel preparing
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.preparing,
          OrderStatus.cancelled,
          UserRole.customer,
        ),
        isFalse,
      );
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.preparing,
          OrderStatus.cancelled,
          UserRole.deliveryPartner,
        ),
        isFalse,
      );

      // vendor cannot mark readyForPickup -> outForDelivery
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.readyForPickup,
          OrderStatus.outForDelivery,
          UserRole.vendor,
        ),
        isFalse,
      );

      // vendor cannot mark delivered
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.outForDelivery,
          OrderStatus.delivered,
          UserRole.vendor,
        ),
        isFalse,
      );

      // customer cannot mark delivered
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.outForDelivery,
          OrderStatus.delivered,
          UserRole.customer,
        ),
        isFalse,
      );
    });

    test('delivered and cancelled allow nothing', () {
      for (final target in OrderStatus.values) {
        for (final actor in UserRole.values) {
          expect(
            OrderStatus.isTransitionAllowed(OrderStatus.delivered, target, actor),
            isFalse,
            reason: 'Delivered should not allow transition to $target by $actor',
          );
          expect(
            OrderStatus.isTransitionAllowed(OrderStatus.cancelled, target, actor),
            isFalse,
            reason: 'Cancelled should not allow transition to $target by $actor',
          );
        }
      }
    });

    test('cancel allowed from placed/accepted/preparing but not readyForPickup/outForDelivery', () {
      // placed: customer and vendor can cancel
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.placed,
          OrderStatus.cancelled,
          UserRole.customer,
        ),
        isTrue,
      );
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.placed,
          OrderStatus.cancelled,
          UserRole.vendor,
        ),
        isTrue,
      );

      // accepted: vendor can cancel
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.accepted,
          OrderStatus.cancelled,
          UserRole.vendor,
        ),
        isTrue,
      );

      // preparing: vendor can cancel
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.preparing,
          OrderStatus.cancelled,
          UserRole.vendor,
        ),
        isTrue,
      );

      // readyForPickup: no actor can cancel
      for (final actor in UserRole.values) {
        expect(
          OrderStatus.isTransitionAllowed(
            OrderStatus.readyForPickup,
            OrderStatus.cancelled,
            actor,
          ),
          isFalse,
          reason: 'Cancel should not be allowed from readyForPickup by $actor',
        );
      }

      // outForDelivery: no actor can cancel
      for (final actor in UserRole.values) {
        expect(
          OrderStatus.isTransitionAllowed(
            OrderStatus.outForDelivery,
            OrderStatus.cancelled,
            actor,
          ),
          isFalse,
          reason: 'Cancel should not be allowed from outForDelivery by $actor',
        );
      }
    });
  });
}
