import 'package:flutter/foundation.dart';
import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/features/food/models/order.dart';

class PaymentResult {
  final bool success;
  final String? failureMessage;
  final String? transactionRef;

  const PaymentResult({
    required this.success,
    this.failureMessage,
    this.transactionRef,
  });

  const PaymentResult.success({String? transactionRef})
      : this(success: true, transactionRef: transactionRef);

  const PaymentResult.failure(String message)
      : this(success: false, failureMessage: message);
}

abstract interface class PaymentGateway {
  Future<PaymentResult> pay({
    required int amount,
    required PaymentMethod method,
    required String reference,
  });
}

class MockPaymentGateway implements PaymentGateway {
  final Duration delay;
  final DateTime Function() clock;

  MockPaymentGateway({
    this.delay = AppConfig.paymentProcessingDelay,
    this.clock = DateTime.now,
  });

  @override
  Future<PaymentResult> pay({
    required int amount,
    required PaymentMethod method,
    required String reference,
  }) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    // Never store, print or log card data.
    if (kDebugMode) {
      final sanitized = reference.replaceAll(RegExp(r'\s+'), '');
      if (method == PaymentMethod.card && sanitized.endsWith('0000')) {
        return const PaymentResult.failure(
          'Card payment was declined. Please try another card or payment method.',
        );
      }
      if (method == PaymentMethod.upi &&
          reference.toLowerCase().contains('fail')) {
        return const PaymentResult.failure(
          'UPI transaction failed. Please check your UPI ID and try again.',
        );
      }
    }

    final txRef = 'TXN-${clock().millisecondsSinceEpoch}';
    return PaymentResult.success(transactionRef: txRef);
  }
}
