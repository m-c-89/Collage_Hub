import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/domain/user_role.dart';
import 'package:college_canteen/core/services/app_exception.dart';
import 'package:college_canteen/core/services/role_access_service.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/delivery/models/delivery_partner_profile.dart';
import 'package:college_canteen/features/delivery/screens/delivery_dashboard_screen.dart';
import 'package:college_canteen/features/delivery/services/delivery_validators.dart';
import 'package:college_canteen/features/delivery/services/partner_id.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';

class DeliveryRegistrationScreen extends StatefulWidget {
  final RoleAccessService? roleAccessService;
  final OrderRepository? orderRepository;
  final ProfileProvider? profileProvider;

  const DeliveryRegistrationScreen({
    super.key,
    this.roleAccessService,
    this.orderRepository,
    this.profileProvider,
  });

  @override
  State<DeliveryRegistrationScreen> createState() =>
      _DeliveryRegistrationScreenState();
}

class _DeliveryRegistrationScreenState
    extends State<DeliveryRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _accessCodeController;

  DeliveryMode _selectedMode = DeliveryMode.onFoot;
  bool _isSubmitting = false;
  String? _accessCodeError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _accessCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() {
      _accessCodeError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final roleAccessService =
        widget.roleAccessService ?? context.read<RoleAccessService>();
    final orderRepo =
        widget.orderRepository ?? context.read<OrderRepository>();
    final profileProvider =
        widget.profileProvider ?? context.read<ProfileProvider>();

    final code = _accessCodeController.text.trim();

    try {
      final isValidCode = await roleAccessService.verifyInviteCode(
        UserRole.deliveryPartner,
        code,
      );

      if (!mounted) return;

      if (!isValidCode) {
        setState(() {
          _accessCodeError = 'Invalid access code';
          _isSubmitting = false;
        });
        return;
      }

      final partnerId = generatePartnerId(
        (id) =>
            orderRepo.currentOrders.any((o) => o.assignedPartnerId == id) ||
            profileProvider.deliveryPartnerProfile?.partnerId == id,
      );

      final profile = DeliveryPartnerProfile(
        partnerId: partnerId,
        name: _nameController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        deliveryMode: _selectedMode,
        isOnline: true,
      );

      profileProvider.becomeDeliveryPartner(profile);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DeliveryDashboardScreen(partnerId: partnerId),
        ),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.userMessage)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration failed. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Register as Delivery Partner',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppTheme.maxContentWidth,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delivery_dining_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery Partner Onboarding',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Join campus delivery network to deliver orders.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 1. Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'e.g. Rahul Kumar',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDCD6CC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: DeliveryValidators.validatePartnerName,
                  ),

                  const SizedBox(height: 18),

                  // 2. Phone (numeric keyboard, 10 digits)
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: 'Phone Number *',
                      hintText: '10-digit mobile number',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      prefixText: '+91 ',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDCD6CC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: DeliveryValidators.validatePartnerPhone,
                  ),

                  const SizedBox(height: 18),

                  // 3. Delivery Mode Dropdown
                  DropdownButtonFormField<DeliveryMode>(
                    value: _selectedMode,
                    decoration: InputDecoration(
                      labelText: 'Delivery Mode *',
                      prefixIcon:
                          const Icon(Icons.two_wheeler_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDCD6CC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    items: DeliveryMode.values.map((mode) {
                      return DropdownMenuItem<DeliveryMode>(
                        value: mode,
                        child: Text(mode.label),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _selectedMode = value;
                              });
                              _formKey.currentState?.validate();
                            }
                          },
                  ),

                  const SizedBox(height: 18),

                  // 4. Access Code
                  TextFormField(
                    controller: _accessCodeController,
                    decoration: InputDecoration(
                      labelText: 'Access Code *',
                      hintText: 'Enter delivery partner access code',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      errorText: _accessCodeError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDCD6CC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (_) {
                      if (_accessCodeError != null) {
                        setState(() {
                          _accessCodeError = null;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Access code is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  // Submit button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Register as Delivery Partner',
                            style: TextStyle(
                              fontSize: 15,
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
    );
  }
}
