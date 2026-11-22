import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:college_canteen/core/services/app_exception.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/core/utils/money.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/food/data/payment_gateway.dart';
import 'package:college_canteen/features/food/models/order.dart';
import 'package:college_canteen/features/food/screens/order_confirmation_screen.dart';
import 'package:college_canteen/features/food/services/payment_validators.dart';

class PaymentScreen extends StatefulWidget {
  final Order order;

  const PaymentScreen({super.key, required this.order});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod? _selectedMethod;
  bool _isProcessing = false;
  bool _isSubmitting = false;

  // Controllers for UPI
  final _upiController = TextEditingController();

  // Controllers for Card (held in widget state ONLY - never printed/logged/stored)
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_onFieldChanged);
    _expiryController.addListener(_onFieldChanged);
    _cvvController.addListener(_onFieldChanged);
    _nameController.addListener(_onFieldChanged);
    _upiController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _cardNumberController.removeListener(_onFieldChanged);
    _expiryController.removeListener(_onFieldChanged);
    _cvvController.removeListener(_onFieldChanged);
    _nameController.removeListener(_onFieldChanged);
    _upiController.removeListener(_onFieldChanged);

    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  bool _isFormValid() {
    if (_selectedMethod == null) return false;

    switch (_selectedMethod!) {
      case PaymentMethod.cod:
        return true;
      case PaymentMethod.upi:
        return isValidUpiId(_upiController.text);
      case PaymentMethod.card:
        return isValidCardNumber(_cardNumberController.text) &&
            isValidExpiry(_expiryController.text, DateTime.now()) &&
            isValidCvv(_cvvController.text) &&
            isValidName(_nameController.text);
    }
  }

  Future<void> _handlePayment() async {
    // 1. Block double taps
    if (_isSubmitting || _isProcessing) return;
    _isSubmitting = true;

    if (_selectedMethod == null) {
      _isSubmitting = false;
      return;
    }

    final orderRepo = context.read<OrderRepository>();
    final gateway = context.read<PaymentGateway>();

    // 2. Show the loading overlay and block back button
    setState(() => _isProcessing = true);

    String? paymentRef;

    // 3. gateway.pay (skip for COD)
    if (_selectedMethod != PaymentMethod.cod) {
      final reference = _selectedMethod == PaymentMethod.upi
          ? _upiController.text.trim()
          : _cardNumberController.text.replaceAll(' ', '');

      final paymentResult = await gateway.pay(
        amount: widget.order.grandTotal,
        method: _selectedMethod!,
        reference: reference,
      );

      if (!mounted) return;

      if (!paymentResult.success) {
        setState(() {
          _isProcessing = false;
          _isSubmitting = false;
        });
        final msg = paymentResult.failureMessage ??
            'Payment failed. Please check your payment details and retry.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _handlePayment(),
            ),
          ),
        );
        return;
      }

      paymentRef = paymentResult.transactionRef;
    }

    // 4. payForOrder
    try {
      final updatedOrder = await orderRepo.payForOrder(
        widget.order.id,
        widget.order.customerId,
        _selectedMethod!,
        paymentReference: paymentRef,
      );

      if (!mounted) return;

      // 5. pushAndRemoveUntil to OrderConfirmationScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(order: updatedOrder),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _isSubmitting = false;
      });
      final msg = e is AppException
          ? e.userMessage
          : (e is StateError
              ? e.message
              : 'Failed to pay for order. Please try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final grandTotal = widget.order.grandTotal;
    final totalQuantity =
        widget.order.items.fold<int>(0, (sum, i) => sum + i.quantity);
    final isValid = _isFormValid();
    final buttonLabel = _selectedMethod == PaymentMethod.cod
        ? 'Place Order'
        : 'Pay ${formatRupees(grandTotal)}';

    return PopScope(
      canPop: !_isProcessing,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: const Text(
                'Payment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            body: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card with item count & Grand Total
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                              color: Color(0xFFF0EBE1), width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total to Pay',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$totalQuantity ${totalQuantity == 1 ? 'item' : 'items'} in order',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatRupees(grandTotal),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Select Payment Method',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Radio tile: UPI
                      _buildMethodTile(
                        method: PaymentMethod.upi,
                        title: 'UPI (GPay / PhonePe / Paytm)',
                        icon: Icons.account_balance_outlined,
                      ),

                      if (_selectedMethod == PaymentMethod.upi) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: TextFormField(
                            controller: _upiController,
                            decoration: InputDecoration(
                              labelText: 'UPI ID',
                              hintText: 'e.g. ravi@okaxis',
                              prefixIcon: const Icon(Icons.alternate_email,
                                  size: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              errorText: _upiController.text.isNotEmpty &&
                                      !isValidUpiId(_upiController.text)
                                  ? 'Enter a valid UPI ID (e.g. name@bank)'
                                  : null,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Radio tile: Card
                      _buildMethodTile(
                        method: PaymentMethod.card,
                        title: 'Credit / Debit Card',
                        icon: Icons.credit_card_outlined,
                      ),

                      if (_selectedMethod == PaymentMethod.card) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _cardNumberController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  _CardNumberInputFormatter(),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Card Number',
                                  hintText: '4111 1111 1111 1111',
                                  prefixIcon:
                                      const Icon(Icons.credit_card, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  errorText: _cardNumberController
                                              .text.isNotEmpty &&
                                          !isValidCardNumber(
                                              _cardNumberController.text)
                                      ? 'Enter a valid 16-digit card number'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _expiryController,
                                      keyboardType: TextInputType.datetime,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'[\d/]')),
                                        LengthLimitingTextInputFormatter(5),
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'Expiry (MM/YY)',
                                        hintText: '11/26',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        errorText: _expiryController
                                                    .text.isNotEmpty &&
                                                !isValidExpiry(
                                                    _expiryController.text,
                                                    DateTime.now())
                                            ? 'Invalid date'
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _cvvController,
                                      obscureText: true,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(3),
                                      ],
                                      decoration: InputDecoration(
                                        labelText: 'CVV',
                                        hintText: '123',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        errorText: _cvvController
                                                    .text.isNotEmpty &&
                                                !isValidCvv(_cvvController.text)
                                            ? '3 digits'
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Name on Card',
                                  hintText: 'e.g. Rohit Sharma',
                                  prefixIcon: const Icon(Icons.person_outline,
                                      size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  errorText: _nameController.text.isNotEmpty &&
                                          !isValidName(_nameController.text)
                                      ? 'Enter 2-40 characters'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Radio tile: COD
                      _buildMethodTile(
                        method: PaymentMethod.cod,
                        title: 'Cash on Delivery (Pay at Delivery)',
                        icon: Icons.payments_outlined,
                      ),

                      const SizedBox(height: 30),

                      // Action Button
                      ElevatedButton(
                        onPressed: isValid && !_isProcessing && !_isSubmitting
                            ? () => _handlePayment()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade500,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: isValid ? 1 : 0,
                        ),
                        child: Text(
                          buttonLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedMethod == PaymentMethod.cod
                            ? 'Placing your order…'
                            : 'Processing payment…',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMethodTile({
    required PaymentMethod method,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : const Color(0xFFF0EBE1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<PaymentMethod>(
              value: method,
              groupValue: _selectedMethod,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) {
                setState(() {
                  _selectedMethod = val;
                });
              },
            ),
            Icon(icon,
                size: 20,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digitsOnly.length > 16
        ? digitsOnly.substring(0, 16)
        : digitsOnly;
    final formatted = formatCardNumber(limited);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
