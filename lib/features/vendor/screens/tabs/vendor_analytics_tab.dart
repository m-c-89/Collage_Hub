import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/core/utils/money.dart';
import 'package:college_canteen/features/vendor/providers/vendor_provider.dart';

class VendorAnalyticsTab extends StatelessWidget {
  final String? vendorId;

  const VendorAnalyticsTab({super.key, this.vendorId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: const [
            _EmptyStateBanner(),
            _TodaysOrdersCard(),
            SizedBox(height: 10),
            _TodaysRevenueCard(),
            SizedBox(height: 10),
            _CompletedTodayCard(),
            SizedBox(height: 10),
            _AverageOrderValueCard(),
            SizedBox(height: 10),
            _TopItemCard(),
            SizedBox(height: 14),
            _SuggestionProgressCard(),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateBanner extends StatelessWidget {
  const _EmptyStateBanner();

  @override
  Widget build(BuildContext context) {
    final hasNoOrders = context.select<VendorProvider, bool>(
      (p) => p.analytics.todaysOrders == 0,
    );

    if (!hasNoOrders) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade900),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No orders today',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Performance metrics will update as orders are placed today.',
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
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaysOrdersCard extends StatelessWidget {
  const _TodaysOrdersCard();

  @override
  Widget build(BuildContext context) {
    final count = context.select<VendorProvider, int>(
      (p) => p.analytics.todaysOrders,
    );
    return _MetricCard(
      title: "Today's Orders",
      value: '$count',
      icon: Icons.receipt_long_outlined,
      color: Colors.blue.shade700,
    );
  }
}

class _TodaysRevenueCard extends StatelessWidget {
  const _TodaysRevenueCard();

  @override
  Widget build(BuildContext context) {
    final revenue = context.select<VendorProvider, int>(
      (p) => p.analytics.todaysRevenue,
    );
    return _MetricCard(
      title: "Today's Revenue",
      value: formatRupees(revenue),
      icon: Icons.currency_rupee,
      color: Colors.green.shade700,
    );
  }
}

class _CompletedTodayCard extends StatelessWidget {
  const _CompletedTodayCard();

  @override
  Widget build(BuildContext context) {
    final count = context.select<VendorProvider, int>(
      (p) => p.analytics.completedToday,
    );
    return _MetricCard(
      title: 'Completed Today',
      value: '$count',
      icon: Icons.check_circle_outline,
      color: Colors.teal.shade700,
    );
  }
}

class _AverageOrderValueCard extends StatelessWidget {
  const _AverageOrderValueCard();

  @override
  Widget build(BuildContext context) {
    final aov = context.select<VendorProvider, int>(
      (p) => p.analytics.averageOrderValue,
    );
    return _MetricCard(
      title: 'Average Order Value',
      value: formatRupees(aov),
      icon: Icons.trending_up,
      color: Colors.indigo.shade700,
    );
  }
}

class _TopItemCard extends StatelessWidget {
  const _TopItemCard();

  @override
  Widget build(BuildContext context) {
    final (name, qty) = context.select<VendorProvider, (String?, int)>(
      (p) => (p.analytics.topItemName, p.analytics.topItemQuantity),
    );
    final valueText = (name != null && name.isNotEmpty) ? '$name × $qty' : '—';

    return _MetricCard(
      title: 'Top Item',
      value: valueText,
      icon: Icons.star_outline,
      color: Colors.amber.shade800,
    );
  }
}

class _SuggestionProgressCard extends StatelessWidget {
  const _SuggestionProgressCard();

  @override
  Widget build(BuildContext context) {
    final (completed, threshold, progress) =
        context.select<VendorProvider, (int, int, double)>(
      (p) => (
        p.analytics.completedSinceLastAnalysis,
        p.analytics.threshold,
        p.analytics.progress,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Suggestions progress',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Next suggestion refresh: $completed / $threshold',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
