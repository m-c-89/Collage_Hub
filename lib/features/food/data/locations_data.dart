import 'package:college_canteen/features/food/models/campus_location.dart';

const List<CampusLocation> campusLocations = [
  // --- Zone 1 (+₹15 per item) ---
  CampusLocation(
    id: 'loc-234',
    name: '234',
    zone: DeliveryZone.zone1,
  ),
  CampusLocation(
    id: 'loc-235',
    name: '235',
    zone: DeliveryZone.zone1,
  ),
  CampusLocation(
    id: 'loc-236',
    name: '236',
    zone: DeliveryZone.zone1,
  ),
  CampusLocation(
    id: 'loc-237',
    name: '237',
    zone: DeliveryZone.zone1,
  ),
  CampusLocation(
    id: 'loc-block3-back',
    name: 'Backside of Block 3 Building',
    zone: DeliveryZone.zone1,
  ),

  // --- Zone 2 (+₹20 per item) ---
  CampusLocation(
    id: 'loc-121',
    name: '121',
    zone: DeliveryZone.zone2,
  ),
  CampusLocation(
    id: 'loc-120',
    name: '120',
    zone: DeliveryZone.zone2,
  ),
  CampusLocation(
    id: 'loc-block-2',
    name: 'Block-2',
    zone: DeliveryZone.zone2,
  ),
  CampusLocation(
    id: 'loc-block-1',
    name: 'Block-1',
    zone: DeliveryZone.zone2,
  ),
];
