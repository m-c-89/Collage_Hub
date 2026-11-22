import 'package:college_canteen/features/delivery/models/delivery_order.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';

class CampusRoom {
  final String room;
  final String locationId;
  final String block;
  final int floor;
  final String building;

  const CampusRoom({
    required this.room,
    required this.locationId,
    this.block = '',
    this.floor = 0,
    this.building = '',
  });

  String get name => room;
  String get id => locationId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CampusRoom &&
          runtimeType == other.runtimeType &&
          room == other.room &&
          locationId == other.locationId;

  @override
  int get hashCode => Object.hash(room, locationId);

  @override
  String toString() => 'CampusRoom(room: $room, locationId: $locationId)';
}

class CampusBlock {
  final String name;
  final List<int> floors;
  final Map<int, List<CampusRoom>> _roomsByFloor;

  const CampusBlock({
    required this.name,
    required this.floors,
    required Map<int, List<CampusRoom>> roomsByFloor,
  }) : _roomsByFloor = roomsByFloor;

  List<CampusRoom> roomsFor(int floor) => _roomsByFloor[floor] ?? const [];
  List<CampusRoom> rooms(int floor) => roomsFor(floor);

  @override
  String toString() => name;
}

class CampusLayout {
  final List<String> blocks;
  final Map<String, List<int>> _floorsByBlock;
  final Map<String, Map<int, List<CampusRoom>>> _roomsByBlockAndFloor;
  final Map<String, CampusBlock> _blockMap;
  final Set<String> _locationIds;
  final List<DeliveryLocation> _locations;

  CampusLayout._({
    required this.blocks,
    required Map<String, List<int>> floorsByBlock,
    required Map<String, Map<int, List<CampusRoom>>> roomsByBlockAndFloor,
    required Map<String, CampusBlock> blockMap,
    required Set<String> locationIds,
    required List<DeliveryLocation> locations,
  })  : _floorsByBlock = floorsByBlock,
        _roomsByBlockAndFloor = roomsByBlockAndFloor,
        _blockMap = blockMap,
        _locationIds = locationIds,
        _locations = locations;

  factory CampusLayout.fromLocations(List<DeliveryLocation> locations) {
    final blockSet = <String>{};
    final floorsMap = <String, Set<int>>{};
    final roomsMap = <String, Map<int, List<CampusRoom>>>{};
    final locationIds = <String>{};

    for (final loc in locations) {
      locationIds.add(loc.id);
      blockSet.add(loc.block);

      floorsMap.putIfAbsent(loc.block, () => <int>{}).add(loc.floor);

      final blockRooms = roomsMap.putIfAbsent(loc.block, () => {});
      final floorRooms = blockRooms.putIfAbsent(loc.floor, () => <CampusRoom>[]);

      if (!floorRooms.any((r) => r.locationId == loc.id)) {
        floorRooms.add(
          CampusRoom(
            room: loc.room,
            locationId: loc.id,
            block: loc.block,
            floor: loc.floor,
            building: loc.building,
          ),
        );
      }
    }

    final sortedBlocks = blockSet.toList()..sort();
    final sortedFloorsByBlock = <String, List<int>>{};
    final sortedRoomsByBlockAndFloor = <String, Map<int, List<CampusRoom>>>{};
    final blockObjects = <String, CampusBlock>{};

    for (final block in sortedBlocks) {
      final floorList = (floorsMap[block]?.toList() ?? [])..sort();
      sortedFloorsByBlock[block] = List.unmodifiable(floorList);

      final blockRooms = roomsMap[block] ?? {};
      final sortedFloorRooms = <int, List<CampusRoom>>{};

      for (final floor in floorList) {
        final rList = List<CampusRoom>.from(blockRooms[floor] ?? []);
        rList.sort((a, b) => a.room.compareTo(b.room));
        sortedFloorRooms[floor] = List.unmodifiable(rList);
      }

      sortedRoomsByBlockAndFloor[block] = Map.unmodifiable(sortedFloorRooms);

      blockObjects[block] = CampusBlock(
        name: block,
        floors: List.unmodifiable(floorList),
        roomsByFloor: Map.unmodifiable(sortedFloorRooms),
      );
    }

    return CampusLayout._(
      blocks: List.unmodifiable(sortedBlocks),
      floorsByBlock: Map.unmodifiable(sortedFloorsByBlock),
      roomsByBlockAndFloor: Map.unmodifiable(sortedRoomsByBlockAndFloor),
      blockMap: Map.unmodifiable(blockObjects),
      locationIds: Set.unmodifiable(locationIds),
      locations: List.unmodifiable(locations),
    );
  }

  factory CampusLayout.standard() =>
      CampusLayout.fromLocations(kDeliveryLocations);

  List<int> floorsFor(String block) => _floorsByBlock[block] ?? const [];
  List<int> floors(String block) => floorsFor(block);

  List<CampusRoom> roomsFor(String block, int floor) =>
      _roomsByBlockAndFloor[block]?[floor] ?? const [];
  List<CampusRoom> rooms(String block, int floor) => roomsFor(block, floor);

  List<CampusRoom> roomsForBlock(String block) {
    final floors = floorsFor(block);
    final result = <CampusRoom>[];
    for (final floor in floors) {
      result.addAll(roomsFor(block, floor));
    }
    return result;
  }

  CampusBlock? block(String name) => _blockMap[name];
  Map<String, CampusBlock> get blockMap => _blockMap;
  List<DeliveryLocation> get locations => _locations;

  String? locationIdFor(DeliveryOrder order) {
    if (_locationIds.contains(order.locationId)) {
      return order.locationId;
    }
    return null;
  }

  DeliveryLocation? locationById(String id) {
    for (final loc in _locations) {
      if (loc.id == id) return loc;
    }
    return null;
  }
}
