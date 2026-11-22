import 'dart:async';

enum RecipientType { customer, vendor }

class AppNotification {
  final String id;
  final RecipientType recipientType;
  final String recipientId;
  final String orderId;
  final String title;
  final String body;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.recipientType,
    required this.recipientId,
    required this.orderId,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AppNotification(id: $id, recipient: $recipientType:$recipientId, orderId: $orderId, title: $title)';
}

abstract interface class AppNotificationService {
  Stream<AppNotification> get stream;
  void notify(AppNotification n);
}

class InAppNotificationService implements AppNotificationService {
  final StreamController<AppNotification> _controller =
      StreamController<AppNotification>.broadcast();

  @override
  Stream<AppNotification> get stream => _controller.stream;

  @override
  void notify(AppNotification n) {
    if (!_controller.isClosed) {
      _controller.add(n);
    }
  }

  void dispose() {
    _controller.close();
  }
}
