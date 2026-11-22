import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/delivery/providers/delivery_provider.dart';
import 'package:college_canteen/features/delivery/screens/tabs/active_trip_tab.dart';
import 'package:college_canteen/features/delivery/screens/tabs/campus_map_tab.dart';
import 'package:college_canteen/features/delivery/widgets/delivery_notification_banner.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  final String? partnerId;
  final OrderRepository? orderRepository;
  final ProfileProvider? profileProvider;
  final DateTime Function()? now;

  const DeliveryDashboardScreen({
    super.key,
    this.partnerId,
    this.orderRepository,
    this.profileProvider,
    this.now,
  });

  @override
  State<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  static T? _safeRead<T>(BuildContext context) {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isPartner = widget.profileProvider?.isDeliveryPartner ??
          context.read<ProfileProvider>().isDeliveryPartner;
      if (!isPartner) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery access required'),
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider =
        widget.profileProvider ?? context.watch<ProfileProvider>();
    final isDeliveryPartner = profileProvider.isDeliveryPartner;

    if (!isDeliveryPartner) {
      return const Scaffold(
        body: SizedBox.shrink(),
      );
    }

    final partnerId = widget.partnerId ??
        profileProvider.deliveryPartnerProfile?.partnerId ??
        '';
    final orderRepo = widget.orderRepository ??
        _safeRead<OrderRepository>(context) ??
        context.read<OrderRepository>();

    return ChangeNotifierProvider<DeliveryProvider>(
      create: (_) => DeliveryProvider(
        partnerId: partnerId,
        orders: orderRepo,
        now: widget.now,
      ),
      child: const _DeliveryDashboardView(),
    );
  }
}

class _DeliveryDashboardView extends StatelessWidget {
  const _DeliveryDashboardView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Delivery',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: -0.2,
            ),
          ),
          actions: [
            Consumer<DeliveryProvider>(
              builder: (context, deliveryProv, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      deliveryProv.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: deliveryProv.isOnline
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch.adaptive(
                      value: deliveryProv.isOnline,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) => deliveryProv.setOnline(val),
                    ),
                    const SizedBox(width: 8),
                  ],
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(
                text: 'Active Trip',
                icon: Icon(Icons.delivery_dining_outlined),
              ),
              Tab(
                text: 'Campus Map',
                icon: Icon(Icons.map_outlined),
              ),
            ],
          ),
        ),
        body: const Column(
          children: [
            DeliveryNotificationBanner(),
            _DeliveryMetricsHeader(),
            Expanded(
              child: TabBarView(
                children: [
                  ActiveTripTab(),
                  CampusMapTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryMetricsHeader extends StatelessWidget {
  const _DeliveryMetricsHeader();

  @override
  Widget build(BuildContext context) {
    final metrics = context.watch<DeliveryProvider>().metrics;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0EBE1), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricItem(
              label: 'Active deliveries',
              value: '${metrics.activeDeliveries}',
              icon: Icons.local_shipping_outlined,
            ),
          ),
          Container(
            height: 36,
            width: 1,
            color: const Color(0xFFE0D9CF),
          ),
          Expanded(
            child: _buildMetricItem(
              label: 'Delivered today',
              value: '${metrics.deliveredToday}',
              icon: Icons.check_circle_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
