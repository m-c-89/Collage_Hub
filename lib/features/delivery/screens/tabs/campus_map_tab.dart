import 'package:flutter/material.dart';
import 'package:college_canteen/core/theme/app_theme.dart';

class CampusMapTab extends StatelessWidget {
  const CampusMapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.map_outlined,
                size: 32,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Campus Map',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Campus buildings and delivery locations will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
