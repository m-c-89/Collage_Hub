// _DeliveryZone is private to this file — never exposed in user-visible text.
enum _DeliveryZone { zone1, zone2 }

class DeliveryLocation {
  final String id;
  final String address;
  final String building;
  final String block;
  final int floor;
  final String room;
  final int fee;
  // ignore: unused_field
  final _DeliveryZone _zone;

  const DeliveryLocation({
    required this.id,
    required this.address,
    required this.building,
    required this.block,
    required this.floor,
    required this.room,
    this.fee = 5,
    _DeliveryZone zone = _DeliveryZone.zone1,
  }) : _zone = zone;

  const DeliveryLocation._({
    required this.id,
    required this.address,
    required this.building,
    required this.block,
    required this.floor,
    required this.room,
    required this.fee,
    required _DeliveryZone zone,
  }) : _zone = zone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryLocation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const kDeliveryLocations = <DeliveryLocation>[
  DeliveryLocation._(
    id: 'aitr-b3-f2-r234',
    address: 'Room 234, Floor 2, Block 3, AITR Building',
    building: 'AITR Building',
    block: 'Block 3',
    floor: 2,
    room: 'Room 234',
    fee: 5,
    zone: _DeliveryZone.zone1,
  ),
  DeliveryLocation._(
    id: 'aitr-b2-f1-r120',
    address: 'Room 120, Floor 1, Block 2, AITR Building',
    building: 'AITR Building',
    block: 'Block 2',
    floor: 1,
    room: 'Room 120',
    fee: 5,
    zone: _DeliveryZone.zone1,
  ),
  DeliveryLocation._(
    id: 'aitr-b3-f1-r136',
    address: 'Room 136, Floor 1, Block 3, AITR Building',
    building: 'AITR Building',
    block: 'Block 3',
    floor: 1,
    room: 'Room 136',
    fee: 10,
    zone: _DeliveryZone.zone2,
  ),
  DeliveryLocation._(
    id: 'aitr-b3-f3-r316',
    address: 'Room 316, Floor 3, Block 3, AITR Building',
    building: 'AITR Building',
    block: 'Block 3',
    floor: 3,
    room: 'Room 316',
    fee: 10,
    zone: _DeliveryZone.zone2,
  ),
];

/// Returns locations where EVERY whitespace-split token appears in the address
/// (case-insensitive). Empty query → empty list.
List<DeliveryLocation> filterLocations(String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return const [];
  final tokens = trimmed.toLowerCase().split(RegExp(r'\s+'));
  return kDeliveryLocations.where((loc) {
    final lower = loc.address.toLowerCase();
    return tokens.every((t) => lower.contains(t));
  }).toList();
}

/// Trims, collapses whitespace, case-folds, then matches exactly against an
/// address string or an id. Returns null if no match.
DeliveryLocation? matchScannedPayload(String raw) {
  final normalised = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  for (final loc in kDeliveryLocations) {
    if (loc.address.toLowerCase() == normalised || loc.id.toLowerCase() == normalised) {
      return loc;
    }
  }
  return null;
}
