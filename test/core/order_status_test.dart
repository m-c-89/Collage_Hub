import 'package:flutter_test/flutter_test.dart';
import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/domain/user_role.dart';

void main() {
  group('OrderStatus', () {
    test('labels are properly defined', () {
      expect(OrderStatus.placed.label, 'Request sent');
      expect(OrderStatus.etaProposed.label, 'Time Proposed');
      expect(OrderStatus.etaAgreed.label, 'Time Agreed');
      expect(OrderStatus.accepted.label, 'Accepted');
      expect(OrderStatus.preparing.label, 'Preparing');
      expect(OrderStatus.readyForPickup.label, 'Ready for Pickup');
      expect(OrderStatus.outForDelivery.label, 'Out for Delivery');
      expect(OrderStatus.delivered.label, 'Delivered');
      expect(OrderStatus.cancelled.label, 'Cancelled');
    });

    test('isTerminal is true only for delivered and cancelled', () {
      expect(OrderStatus.placed.isTerminal, isFalse);
      expect(OrderStatus.etaProposed.isTerminal, isFalse);
      expect(OrderStatus.etaAgreed.isTerminal, isFalse);
      expect(OrderStatus.accepted.isTerminal, isFalse);
      expect(OrderStatus.preparing.isTerminal, isFalse);
      expect(OrderStatus.readyForPickup.isTerminal, isFalse);
      expect(OrderStatus.outForDelivery.isTerminal, isFalse);
      expect(OrderStatus.delivered.isTerminal, isTrue);
      expect(OrderStatus.cancelled.isTerminal, isTrue);
    });

    test('CancelReason labels are defined', () {
      expect(CancelReason.customerCancelled.label, isNotEmpty);
      expect(CancelReason.customerDeclinedWait.label,
          'You declined the waiting time');
      expect(CancelReason.customerNoResponse.label, isNotEmpty);
      expect(CancelReason.vendorRejected.label, isNotEmpty);
      expect(CancelReason.vendorCancelled.label, isNotEmpty);
      expect(CancelReason.vendorNoResponse.label,
          'The kitchen did not respond in time');
      expect(CancelReason.paymentTimeout.label, 'Payment window expired');
    });

    test('every allowed transition is true for its actor', () {
      const allowedTransitions = [
        (OrderStatus.placed, OrderStatus.etaProposed, UserRole.vendor),
        (OrderStatus.placed, OrderStatus.cancelled, UserRole.customer),
        (OrderStatus.placed, OrderStatus.cancelled, UserRole.vendor),
        (OrderStatus.etaProposed, OrderStatus.etaAgreed, UserRole.customer),
        (OrderStatus.etaProposed, OrderStatus.cancelled, UserRole.customer),
        (OrderStatus.etaProposed, OrderStatus.cancelled, UserRole.vendor),
        (OrderStatus.etaAgreed, OrderStatus.accepted, UserRole.vendor),
        (OrderStatus.etaAgreed, OrderStatus.cancelled, UserRole.customer),
        (OrderStatus.etaAgreed, OrderStatus.cancelled, UserRole.vendor),
        (OrderStatus.accepted, OrderStatus.cancelled, UserRole.customer),
        (OrderStatus.accepted, OrderStatus.cancelled, UserRole.vendor),
        (OrderStatus.preparing, OrderStatus.readyForPickup, UserRole.vendor),
        (OrderStatus.preparing, OrderStatus.cancelled, UserRole.vendor),
        (
          OrderStatus.readyForPickup,
          OrderStatus.outForDelivery,
          UserRole.deliveryPartner
        ),
        (
          OrderStatus.outForDelivery,
          OrderStatus.delivered,
          UserRole.deliveryPartner
        ),
      ];

      for (final (from, to, actor) in allowedTransitions) {
        expect(
          OrderStatus.isTransitionAllowed(from, to, actor),
          isTrue,
          reason: '$from -> $to should be allowed for $actor',
        );
      }
    });

    test('human actors cannot do accepted -> preparing', () {
      for (final actor in UserRole.values) {
        expect(
          OrderStatus.isTransitionAllowed(
            OrderStatus.accepted,
            OrderStatus.preparing,
            actor,
          ),
          isFalse,
          reason: 'Human actor $actor cannot perform accepted -> preparing',
        );
      }
    });

    test('wrong actor is false for other transitions', () {
      // Customer cannot propose ETA
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.placed,
          OrderStatus.etaProposed,
          UserRole.customer,
        ),
        isFalse,
      );
      // Vendor cannot agree to ETA
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.etaProposed,
          OrderStatus.etaAgreed,
          UserRole.vendor,
        ),
        isFalse,
      );
      // Customer cannot accept from etaAgreed
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.etaAgreed,
          OrderStatus.accepted,
          UserRole.customer,
        ),
        isFalse,
      );
      // Customer cannot cancel preparing
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.preparing,
          OrderStatus.cancelled,
          UserRole.customer,
        ),
        isFalse,
      );
      // Vendor cannot transition readyForPickup -> outForDelivery
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.readyForPickup,
          OrderStatus.outForDelivery,
          UserRole.vendor,
        ),
        isFalse,
      );
      // Delivery partner cannot accept or cancel orders
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.placed,
          OrderStatus.accepted,
          UserRole.deliveryPartner,
        ),
        isFalse,
      );
      expect(
        OrderStatus.isTransitionAllowed(
          OrderStatus.placed,
          OrderStatus.cancelled,
          UserRole.deliveryPartner,
        ),
        isFalse,
      );
    });

    test('terminal states (delivered and cancelled) allow nothing', () {
      for (final target in OrderStatus.values) {
        for (final actor in UserRole.values) {
          expect(
            OrderStatus.isTransitionAllowed(
                OrderStatus.delivered, target, actor),
            isFalse,
            reason: 'Delivered should not allow transition to $target by $actor',
          );
          expect(
            OrderStatus.isTransitionAllowed(
                OrderStatus.cancelled, target, actor),
            isFalse,
            reason: 'Cancelled should not allow transition to $target by $actor',
          );
        }
      }
    });

    test('isSystemTransitionAllowed is true only for its allowed pairs', () {
      const allowedSystemPairs = {
        (OrderStatus.accepted, OrderStatus.preparing),
        (OrderStatus.placed, OrderStatus.cancelled),
        (OrderStatus.etaProposed, OrderStatus.cancelled),
        (OrderStatus.etaAgreed, OrderStatus.cancelled),
        (OrderStatus.accepted, OrderStatus.cancelled),
      };

      for (final from in OrderStatus.values) {
        for (final to in OrderStatus.values) {
          final isAllowed = allowedSystemPairs.contains((from, to));
          expect(
            OrderStatus.isSystemTransitionAllowed(from, to),
            isAllowed,
            reason: 'System transition ($from -> $to) should be $isAllowed',
          );
        }
      }
    });
  });
}
