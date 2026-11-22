import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/config/app_config.dart';
import 'package:college_canteen/core/domain/user_role.dart';
import 'package:college_canteen/core/services/app_exception.dart';
import 'package:college_canteen/core/services/role_access_service.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';
import 'package:college_canteen/features/vendor/data/vendor_repository.dart';
import 'package:college_canteen/features/vendor/models/vendor_profile.dart';
import 'package:college_canteen/features/vendor/screens/vendor_dashboard_screen.dart';
import 'package:college_canteen/features/vendor/services/vendor_id.dart';
import 'package:college_canteen/features/vendor/services/vendor_validators.dart';

class VendorRegistrationScreen extends StatefulWidget {
  final RoleAccessService? roleAccessService;
  final VendorRepository? vendorRepository;
  final ProfileProvider? profileProvider;

  const VendorRegistrationScreen({
    super.key,
    this.roleAccessService,
    this.vendorRepository,
    this.profileProvider,
  });

  @override
  State<VendorRegistrationScreen> createState() =>
      _VendorRegistrationScreenState();
}

class _VendorRegistrationScreenState extends State<VendorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _phoneController;
  late final TextEditingController _fssaiController;
  late final TextEditingController _accessCodeController;

  BusinessType _selectedType = BusinessType.canteen;
  bool _manageExistingCanteen = false;
  bool _isSubmitting = false;
  String? _accessCodeError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _phoneController = TextEditingController();
    _fssaiController = TextEditingController();
    _accessCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _fssaiController.dispose();
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
    final vendorRepository =
        widget.vendorRepository ?? context.read<VendorRepository>();
    final profileProvider =
        widget.profileProvider ?? context.read<ProfileProvider>();

    final code = _accessCodeController.text.trim();
    final isValidCode = await roleAccessService.verifyInviteCode(
      UserRole.vendor,
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

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final phone = _phoneController.text.trim();
    final fssaiText = _fssaiController.text.trim();
    final fssaiNumber = fssaiText.isEmpty ? null : fssaiText;

    try {
      late final VendorProfile profile;

      if (_manageExistingCanteen) {
        profile = VendorProfile(
          vendorId: AppConfig.defaultVendorId,
          businessName: name,
          businessType: _selectedType,
          description: description,
          contactPhone: phone,
          fssaiNumber: fssaiNumber,
        );
        await vendorRepository.update(profile);
      } else {
        final vendorId = generateVendorId(
          name,
          (id) => vendorRepository.byId(id) != null,
          Random(),
        );
        profile = VendorProfile(
          vendorId: vendorId,
          businessName: name,
          businessType: _selectedType,
          description: description,
          contactPhone: phone,
          fssaiNumber: fssaiNumber,
        );
        await vendorRepository.register(profile);
      }

      if (!mounted) return;

      profileProvider.becomeVendor(profile);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VendorDashboardScreen(vendorId: profile.vendorId),
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
          'Register as Vendor',
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
                  // Banner
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
                            Icons.storefront_outlined,
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
                                'Vendor Onboarding',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Register your food outlet or business to accept orders.',
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

                  // 1. Business Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Business Name *',
                      hintText: 'e.g. Campus Corner',
                      prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
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
                    validator: validateBusinessName,
                  ),

                  const SizedBox(height: 18),

                  // 2. Business Type
                  DropdownButtonFormField<BusinessType>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Business Type *',
                      prefixIcon: const Icon(Icons.category_outlined, size: 20),
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
                    items: BusinessType.values.map((type) {
                      return DropdownMenuItem<BusinessType>(
                        value: type,
                        child: Text(type.label),
                      );
                    }).toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                _selectedType = value;
                              });
                              _formKey.currentState?.validate();
                            }
                          },
                  ),

                  const SizedBox(height: 18),

                  // 3. Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Short description (up to 200 characters)',
                      prefixIcon: const Icon(Icons.description_outlined, size: 20),
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
                    maxLines: 3,
                    maxLength: 200,
                    validator: (value) {
                      final trimmed = value?.trim() ?? '';
                      if (trimmed.length > 200) {
                        return 'Description cannot exceed 200 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // 4. Contact Phone
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    maxLength: 10,
                    decoration: InputDecoration(
                      labelText: 'Contact Phone *',
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
                    validator: validatePhone,
                  ),

                  const SizedBox(height: 18),

                  // 5. FSSAI Number
                  TextFormField(
                    controller: _fssaiController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(14),
                    ],
                    maxLength: 14,
                    decoration: InputDecoration(
                      labelText: _selectedType.fssaiRequired
                          ? 'FSSAI Number (required)'
                          : 'FSSAI Number (optional)',
                      hintText: '14-digit FSSAI license number',
                      prefixIcon: const Icon(Icons.verified_outlined, size: 20),
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
                    validator: (value) => validateFssai(value, _selectedType),
                  ),

                  const SizedBox(height: 18),

                  // 6. Access Code
                  TextFormField(
                    controller: _accessCodeController,
                    decoration: InputDecoration(
                      labelText: 'Access Code *',
                      hintText: 'Enter vendor access/invite code',
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

                  // 7. Demo Mode Switch
                  if (AppConfig.kDemoMode) ...[
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Manage existing College Canteen menu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      value: _manageExistingCanteen,
                      onChanged: _isSubmitting
                          ? null
                          : (val) {
                              setState(() {
                                _manageExistingCanteen = val;
                              });
                            },
                    ),
                  ],

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
                            'Register as Vendor',
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
