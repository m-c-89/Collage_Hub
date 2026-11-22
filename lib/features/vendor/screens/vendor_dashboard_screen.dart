import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/food/data/order_repository.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';
import 'package:college_canteen/features/vendor/data/vendor_repository.dart';
import 'package:college_canteen/features/vendor/providers/vendor_provider.dart';
import 'package:college_canteen/features/vendor/screens/tabs/vendor_analytics_tab.dart';
import 'package:college_canteen/features/vendor/screens/tabs/vendor_items_tab.dart';
import 'package:college_canteen/features/vendor/screens/tabs/vendor_orders_tab.dart';
import 'package:college_canteen/features/vendor/screens/tabs/vendor_suggestions_tab.dart';

class VendorDashboardScreen extends StatefulWidget {
  final String vendorId;
  final VendorRepository? vendorRepository;
  final OrderRepository? orderRepository;
  final ProfileProvider? profileProvider;

  const VendorDashboardScreen({
    super.key,
    required this.vendorId,
    this.vendorRepository,
    this.orderRepository,
    this.profileProvider,
  });

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isVendor = widget.profileProvider?.isVendor ??
          context.read<ProfileProvider>().isVendor;
      if (!isVendor) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vendor access required'),
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
    final isVendor = widget.profileProvider?.isVendor ??
        context.watch<ProfileProvider>().isVendor;

    if (!isVendor) {
      return const Scaffold(
        body: SizedBox.shrink(),
      );
    }

    final vendorRepo =
        widget.vendorRepository ?? context.read<VendorRepository>();
    final orderRepo =
        widget.orderRepository ?? context.read<OrderRepository>();

    return ChangeNotifierProvider<VendorProvider>(
      create: (_) => VendorProvider(
        vendorId: widget.vendorId,
        orders: orderRepo,
        vendors: vendorRepo,
      ),
      child: Consumer<VendorProvider>(
        builder: (context, vendorProv, child) {
          final vendor = vendorProv.profile;
          final title = vendor?.businessName ?? 'Vendor Dashboard';
          final badge = vendorProv.newOrderBadge;

          return DefaultTabController(
            length: 4,
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
                bottom: TabBar(
                  labelColor: AppTheme.primaryColor,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.primaryColor,
                  tabs: [
                    Tab(
                      text: 'Orders',
                      icon: badge > 0
                          ? Badge.count(
                              count: badge,
                              child: const Icon(Icons.receipt_long_outlined),
                            )
                          : const Icon(Icons.receipt_long_outlined),
                    ),
                    const Tab(
                      text: 'Analytics',
                      icon: Icon(Icons.analytics_outlined),
                    ),
                    const Tab(
                      text: 'Suggestions',
                      icon: Icon(Icons.lightbulb_outline),
                    ),
                    const Tab(
                      text: 'Items',
                      icon: Icon(Icons.restaurant_menu_outlined),
                    ),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  VendorOrdersTab(vendorId: widget.vendorId),
                  VendorAnalyticsTab(vendorId: widget.vendorId),
                  VendorSuggestionsTab(vendorId: widget.vendorId),
                  VendorItemsTab(vendorId: widget.vendorId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
