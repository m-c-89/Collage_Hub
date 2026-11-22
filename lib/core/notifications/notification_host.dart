import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/notifications/app_notification.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/food/screens/order_tracking_screen.dart';
import 'package:college_canteen/features/profile/profile_provider.dart';
import 'package:college_canteen/features/vendor/screens/vendor_dashboard_screen.dart';

class NotificationHost extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final AppNotificationService notificationService;
  final Widget child;
  final ProfileProvider? profileProvider;

  const NotificationHost({
    super.key,
    required this.navigatorKey,
    required this.notificationService,
    required this.child,
    this.profileProvider,
  });

  @override
  State<NotificationHost> createState() => _NotificationHostState();
}

class _NotificationHostState extends State<NotificationHost>
    with WidgetsBindingObserver {
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  final Set<String> _seenNotificationIds = <String>{};
  StreamSubscription<AppNotification>? _subscription;

  @override
  void initState() {
    super.initState();
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _subscription = widget.notificationService.stream.listen(_handleNotification);
  }

  @override
  void didUpdateWidget(covariant NotificationHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notificationService != widget.notificationService) {
      _subscription?.cancel();
      _subscription =
          widget.notificationService.stream.listen(_handleNotification);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    super.dispose();
  }

  bool _isRecipientMatch(AppNotification notification, BuildContext context) {
    ProfileProvider? profileProvider = widget.profileProvider;
    try {
      profileProvider ??= Provider.of<ProfileProvider>(context, listen: false);
    } catch (_) {}

    final customerProfile = profileProvider?.profile;
    final currentCustomerId = customerProfile?.id ?? 'default-customer';
    final isVendor = profileProvider?.isVendor ?? false;
    final currentVendorId = profileProvider?.vendorProfile?.vendorId;

    if (notification.recipientType == RecipientType.customer) {
      return notification.recipientId == currentCustomerId ||
          (currentCustomerId == 'default-customer' &&
              notification.recipientId == 'demo-customer');
    } else if (notification.recipientType == RecipientType.vendor) {
      return isVendor && notification.recipientId == currentVendorId;
    }
    return false;
  }

  void _handleNotification(AppNotification notification) {
    if (!mounted) return;
    if (_lifecycleState != AppLifecycleState.resumed) return;
    if (!_seenNotificationIds.add(notification.id)) return;
    if (!_isRecipientMatch(notification, context)) return;

    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    final messengerContext = widget.navigatorKey.currentContext ?? context;
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(messengerContext);
    if (scaffoldMessenger == null) return;

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              notification.body,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: AppTheme.primaryColor,
          onPressed: () => _openTarget(notification),
        ),
      ),
    );
  }

  void _openTarget(AppNotification notification) {
    final navState = widget.navigatorKey.currentState;
    if (navState == null) return;

    if (notification.recipientType == RecipientType.customer) {
      navState.push(
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            initialOrderId: notification.orderId,
          ),
        ),
      );
    } else if (notification.recipientType == RecipientType.vendor) {
      navState.push(
        MaterialPageRoute(
          builder: (_) => VendorDashboardScreen(
            vendorId: notification.recipientId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
