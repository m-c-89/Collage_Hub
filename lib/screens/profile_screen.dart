import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/customer_profile.dart';
import '../providers/profile_provider.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isMandatory;

  const ProfileScreen({
    super.key,
    this.isMandatory = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;

  bool _allowExit = false;

  @override
  void initState() {
    super.initState();
    final currentProfile = context.read<ProfileProvider>().profile;
    _nameController = TextEditingController(
      text: currentProfile?.fullName ?? '',
    );
    _mobileController = TextEditingController(
      text: currentProfile?.mobileNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newProfile = CustomerProfile(
      fullName: _nameController.text.trim(),
      mobileNumber: _mobileController.text.trim(),
    );

    context.read<ProfileProvider>().save(newProfile);

    if (widget.isMandatory) {
      setState(() {
        _allowExit = true;
      });
      // Skip straight to next step: Checkout (coming next)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const CheckoutScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer profile updated successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _backToCart() {
    setState(() {
      _allowExit = true;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isMandatory
        ? 'Create Customer Profile'
        : (context.watch<ProfileProvider>().hasProfile
            ? 'Edit Customer Profile'
            : 'Customer Profile');

    return PopScope(
      canPop: !widget.isMandatory || _allowExit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: -0.2,
            ),
          ),
          automaticallyImplyLeading: !widget.isMandatory,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Canteen identity banner
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
                              Icons.badge_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isMandatory
                                      ? 'Mandatory Student / Faculty Details'
                                      : 'Campus Canteen Profile',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Used for canteen counter pick-up verification.',
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

                    // 1. Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'e.g. Aarav Sharma',
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
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Full Name is required';
                        }
                        if (trimmed.length < 3) {
                          return 'Full Name must be at least 3 characters';
                        }
                        if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmed)) {
                          return 'Letters and spaces only';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // 2. Mobile Number
                    TextFormField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      maxLength: 10,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number *',
                        hintText: '10-digit number (e.g. 9876543210)',
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
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Mobile Number is required';
                        }
                        if (trimmed.length != 10) {
                          return 'Mobile Number must be exactly 10 digits';
                        }
                        if (!RegExp(r'^[6-9]').hasMatch(trimmed)) {
                          return 'Mobile Number must start with 6, 7, 8, or 9';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    // Primary Button: "Save & Continue"
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        widget.isMandatory ? 'Save & Continue' : 'Save Details',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // In mandatory mode: explicit "Back to Cart" exit
                    if (widget.isMandatory) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _backToCart,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimary,
                          side: const BorderSide(color: Color(0xFFDCD6CC)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Back to Cart',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
