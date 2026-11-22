enum DeliveryMode {
  onFoot,
  bicycle,
  scooter;

  String get label => switch (this) {
        DeliveryMode.onFoot => 'On Foot',
        DeliveryMode.bicycle => 'Bicycle',
        DeliveryMode.scooter => 'Scooter',
      };
}

class DeliveryPartnerProfile {
  final String partnerId;
  final String name;
  final String contactPhone;
  final DeliveryMode deliveryMode;
  final bool isOnline;

  const DeliveryPartnerProfile({
    required this.partnerId,
    required this.name,
    required this.contactPhone,
    required this.deliveryMode,
    required this.isOnline,
  });

  DeliveryPartnerProfile copyWith({
    String? partnerId,
    String? name,
    String? contactPhone,
    DeliveryMode? deliveryMode,
    bool? isOnline,
  }) {
    return DeliveryPartnerProfile(
      partnerId: partnerId ?? this.partnerId,
      name: name ?? this.name,
      contactPhone: contactPhone ?? this.contactPhone,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryPartnerProfile &&
          runtimeType == other.runtimeType &&
          partnerId == other.partnerId &&
          name == other.name &&
          contactPhone == other.contactPhone &&
          deliveryMode == other.deliveryMode &&
          isOnline == other.isOnline;

  @override
  int get hashCode => Object.hash(
        partnerId,
        name,
        contactPhone,
        deliveryMode,
        isOnline,
      );

  @override
  String toString() =>
      'DeliveryPartnerProfile(partnerId: $partnerId, name: $name, contactPhone: $contactPhone, deliveryMode: $deliveryMode, isOnline: $isOnline)';
}
