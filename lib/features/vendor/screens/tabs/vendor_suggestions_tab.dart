import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/vendor/providers/vendor_provider.dart';
import 'package:college_canteen/features/vendor/services/vendor_suggestion_engine.dart';

class VendorSuggestionsTab extends StatelessWidget {
  final String? vendorId;

  const VendorSuggestionsTab({super.key, this.vendorId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
        child: Consumer<VendorProvider>(
          builder: (context, provider, child) {
            final analytics = provider.analytics;
            final threshold = analytics.threshold;
            final completedSince = analytics.completedSinceLastAnalysis;
            final progress = analytics.progress;
            final suggestions = provider.suggestions;
            final lastError = provider.lastError;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                if (lastError != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 20,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lastError,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: Colors.red.shade700,
                          onPressed: () => provider.clearLastError(),
                        ),
                      ],
                    ),
                  ),
                ],

                // 1. Threshold Control & Progress Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Analysis Threshold',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$threshold orders',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: AppTheme.primaryColor,
                              iconSize: 22,
                              tooltip: 'Decrease threshold',
                              onPressed: threshold > 5
                                  ? () => provider.setThreshold(threshold - 5)
                                  : null,
                            ),
                            Expanded(
                              child: Slider(
                                value: threshold.toDouble(),
                                min: 5,
                                max: 500,
                                divisions: 99,
                                label: '$threshold',
                                activeColor: AppTheme.primaryColor,
                                onChanged: (val) {
                                  provider.setThreshold(val.round());
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: AppTheme.primaryColor,
                              iconSize: 22,
                              tooltip: 'Increase threshold',
                              onPressed: threshold < 500
                                  ? () => provider.setThreshold(threshold + 5)
                                  : null,
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cycle Progress',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              '$completedSince / $threshold completed orders',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Debug Button (+10 Orders)
                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        provider.simulateCompletedOrders(10);
                      },
                      icon: const Icon(Icons.flash_on, size: 18),
                      label: const Text('+10 Orders'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // 3. Suggestions List or Empty State
                if (suggestions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 56,
                            color: AppTheme.primaryColor.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Suggestions appear after $threshold completed orders',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Keep serving orders to generate personalized business insights.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Actionable Recommendations',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  for (final suggestion in suggestions)
                    _SuggestionCard(suggestion: suggestion),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final Suggestion suggestion;

  const _SuggestionCard({required this.suggestion});

  IconData _iconForType(SuggestionType type) {
    return switch (type) {
      SuggestionType.bestsellers => Icons.workspace_premium_rounded,
      SuggestionType.lowRated => Icons.warning_amber_rounded,
      SuggestionType.praised => Icons.favorite_rounded,
      SuggestionType.slowMover => Icons.hourglass_bottom_rounded,
      SuggestionType.peakHour => Icons.schedule_rounded,
    };
  }

  Color _colorForType(SuggestionType type) {
    return switch (type) {
      SuggestionType.bestsellers => Colors.amber.shade800,
      SuggestionType.lowRated => Colors.red.shade700,
      SuggestionType.praised => AppTheme.pureVegGreen,
      SuggestionType.slowMover => Colors.orange.shade800,
      SuggestionType.peakHour => Colors.blue.shade700,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(suggestion.type);
    final icon = _iconForType(suggestion.type);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestion.detail,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
