enum DeliveryZone {
  zone1(name: 'Zone 1', chargePerItem: 15.0),
  zone2(name: 'Zone 2', chargePerItem: 20.0);

  final String name;
  final double chargePerItem;

  const DeliveryZone({
    required this.name,
    required this.chargePerItem,
  });
}

class CampusLocation {
  final String id;
  final String name;
  final DeliveryZone zone;

  const CampusLocation({
    required this.id,
    required this.name,
    required this.zone,
  });

  double get chargePerItem => zone.chargePerItem;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampusLocation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$name • ${zone.name} • +₹${zone.chargePerItem.toInt()}/item';
}
