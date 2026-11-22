import 'package:flutter/material.dart';
import 'package:college_canteen/core/theme/app_theme.dart';

class VendorItemsTab extends StatelessWidget {
  final String? vendorId;

  const VendorItemsTab({super.key, this.vendorId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 48,
            color: AppTheme.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'Items – coming in the next step',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
