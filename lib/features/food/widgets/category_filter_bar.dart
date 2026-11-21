import 'package:flutter/material.dart';
import 'package:college_canteen/core/theme/app_theme.dart';

class CategoryFilterBar extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  static const List<String> categories = [
    'All',
    'Snacks',
    'Meals',
    'Beverages',
    'Desserts',
  ];

  const CategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                onSelected(category);
              }
            },
            selectedColor: AppTheme.primaryColor,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primaryColor
                  : const Color(0xFFE0DCD5),
              width: 1.2,
            ),
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: isSelected ? 1 : 0,
            pressElevation: 1,
          );
        },
      ),
    );
  }
}
