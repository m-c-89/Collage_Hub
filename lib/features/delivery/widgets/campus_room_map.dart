import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:college_canteen/core/domain/order_status.dart';
import 'package:college_canteen/core/theme/app_theme.dart';
import 'package:college_canteen/features/delivery/models/room_mark.dart';
import 'package:college_canteen/features/delivery/providers/delivery_provider.dart';
import 'package:college_canteen/features/delivery/services/campus_layout.dart';
import 'package:college_canteen/features/delivery/widgets/minimal_order_card.dart';
import 'package:college_canteen/features/food/models/delivery_location.dart';

class CampusRoomMap extends StatefulWidget {
  final CampusLayout? layout;

  const CampusRoomMap({
    super.key,
    this.layout,
  });

  @override
  State<CampusRoomMap> createState() => _CampusRoomMapState();
}

class _CampusRoomMapState extends State<CampusRoomMap> {
  late final CampusLayout _layout;
  String? _selectedBlock;
  int? _selectedFloor;

  @override
  void initState() {
    super.initState();
    _layout = widget.layout ?? CampusLayout.fromLocations(kDeliveryLocations);
    if (_layout.blocks.isNotEmpty) {
      _selectedBlock = _layout.blocks.first;
      final floors = _layout.floorsFor(_selectedBlock!);
      if (floors.isNotEmpty) {
        _selectedFloor = floors.first;
      }
    }
  }

  void _syncSelectionWithOrders(DeliveryProvider provider) {
    final blocks = _layout.blocks;
    if (blocks.isEmpty) return;

    if (_selectedBlock == null || !blocks.contains(_selectedBlock)) {
      final orderBlock = blocks.firstWhere(
        (b) => provider.blocksWithOrders.contains(b),
        orElse: () => blocks.first,
      );
      _selectedBlock = orderBlock;
    }

    final floors = _layout.floorsFor(_selectedBlock!);
    if (floors.isEmpty) {
      _selectedFloor = null;
      return;
    }

    if (_selectedFloor == null || !floors.contains(_selectedFloor)) {
      final blockRooms = _layout.roomsForBlock(_selectedBlock!);
      final floorWithOrder = floors.firstWhere(
        (f) => blockRooms.any((r) =>
            r.floor == f && provider.roomMarks.containsKey(r.locationId)),
        orElse: () => floors.first,
      );
      _selectedFloor = floorWithOrder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();
    final roomMarks = provider.roomMarks;

    if (roomMarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0EBE1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map_outlined,
                  size: 32,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No orders on the map right now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Active deliveries and pending batches will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    _syncSelectionWithOrders(provider);

    final selectedBlock = _selectedBlock ?? _layout.blocks.first;
    final floors = _layout.floorsFor(selectedBlock);
    final selectedFloor = _selectedFloor ?? (floors.isNotEmpty ? floors.first : 1);
    final rooms = _layout.roomsFor(selectedBlock, selectedFloor);

    return Column(
      children: [
        _buildControls(context, provider, selectedBlock, selectedFloor, floors),
        Expanded(
          child: RepaintBoundary(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.0,
              child: _buildRoomCanvas(
                context,
                provider,
                selectedBlock,
                selectedFloor,
                rooms,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(
    BuildContext context,
    DeliveryProvider provider,
    String selectedBlock,
    int selectedFloor,
    List<int> floors,
  ) {
    return Container(
      color: AppTheme.cardBackground,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final block in _layout.blocks) ...[
                  _buildBlockChip(context, provider, block, selectedBlock),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final floor in floors) ...[
                  _buildFloorChip(
                    context,
                    provider,
                    floor,
                    selectedFloor,
                    selectedBlock,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockChip(
    BuildContext context,
    DeliveryProvider provider,
    String block,
    String selectedBlock,
  ) {
    final isSelected = selectedBlock == block;
    final blockRooms = _layout.roomsForBlock(block);
    final hasActive = blockRooms.any((r) =>
        provider.roomMarks[r.locationId]?.kind == RoomMarkKind.active);
    final hasPending = blockRooms.any((r) =>
        provider.roomMarks[r.locationId]?.kind == RoomMarkKind.pending);

    Color? chipBg;
    Color labelColor = AppTheme.textPrimary;
    BorderSide borderSide = const BorderSide(color: Color(0xFFE0DCD5));

    if (hasActive) {
      borderSide = const BorderSide(color: AppTheme.primaryColor, width: 2);
      if (isSelected) {
        chipBg = AppTheme.primaryColor;
        labelColor = Colors.white;
      } else {
        chipBg = AppTheme.primaryContainer.withOpacity(0.5);
        labelColor = AppTheme.primaryDark;
      }
    } else if (hasPending) {
      borderSide = const BorderSide(color: AppTheme.primaryLight, width: 1.5);
      if (isSelected) {
        chipBg = AppTheme.primaryColor;
        labelColor = Colors.white;
      } else {
        chipBg = AppTheme.primaryContainer.withOpacity(0.3);
        labelColor = AppTheme.primaryDark;
      }
    } else if (isSelected) {
      chipBg = AppTheme.primaryColor;
      labelColor = Colors.white;
      borderSide = const BorderSide(color: AppTheme.primaryColor);
    }

    return ChoiceChip(
      key: ValueKey('block-chip-$block'),
      label: Text(
        block,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: labelColor,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: chipBg ?? AppTheme.primaryColor,
      backgroundColor: chipBg ?? Colors.white,
      side: borderSide,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedBlock = block;
            final blockFloors = _layout.floorsFor(block);
            if (!blockFloors.contains(_selectedFloor)) {
              _selectedFloor = blockFloors.isNotEmpty ? blockFloors.first : 1;
            }
          });
        }
      },
    );
  }

  Widget _buildFloorChip(
    BuildContext context,
    DeliveryProvider provider,
    int floor,
    int selectedFloor,
    String selectedBlock,
  ) {
    final isSelected = selectedFloor == floor;
    final floorRooms = _layout.roomsFor(selectedBlock, floor);
    final hasActive = floorRooms.any((r) =>
        provider.roomMarks[r.locationId]?.kind == RoomMarkKind.active);
    final hasPending = floorRooms.any((r) =>
        provider.roomMarks[r.locationId]?.kind == RoomMarkKind.pending);

    Color? chipBg;
    Color labelColor = AppTheme.textPrimary;
    BorderSide borderSide = const BorderSide(color: Color(0xFFE0DCD5));

    if (hasActive) {
      borderSide = const BorderSide(color: AppTheme.primaryColor, width: 2);
      if (isSelected) {
        chipBg = AppTheme.primaryColor;
        labelColor = Colors.white;
      } else {
        chipBg = AppTheme.primaryContainer.withOpacity(0.5);
        labelColor = AppTheme.primaryDark;
      }
    } else if (hasPending) {
      borderSide = const BorderSide(color: AppTheme.primaryLight, width: 1.5);
      if (isSelected) {
        chipBg = AppTheme.primaryColor;
        labelColor = Colors.white;
      } else {
        chipBg = AppTheme.primaryContainer.withOpacity(0.3);
        labelColor = AppTheme.primaryDark;
      }
    } else if (isSelected) {
      chipBg = AppTheme.primaryColor;
      labelColor = Colors.white;
      borderSide = const BorderSide(color: AppTheme.primaryColor);
    }

    return ChoiceChip(
      key: ValueKey('floor-chip-$floor'),
      label: Text(
        'Floor $floor',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: labelColor,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      selectedColor: chipBg ?? AppTheme.primaryColor,
      backgroundColor: chipBg ?? Colors.white,
      side: borderSide,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFloor = floor;
          });
        }
      },
    );
  }

  Widget _buildRoomCanvas(
    BuildContext context,
    DeliveryProvider provider,
    String selectedBlock,
    int selectedFloor,
    List<CampusRoom> rooms,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(minWidth: 260, maxWidth: 480),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0DCD5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.meeting_room_outlined,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$selectedBlock \u2022 Floor $selectedFloor',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.scaffoldBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${rooms.length} ${rooms.length == 1 ? 'room' : 'rooms'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final room in rooms)
                    _buildRoomTile(context, provider, room),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomTile(
    BuildContext context,
    DeliveryProvider provider,
    CampusRoom room,
  ) {
    final mark = provider.roomMarks[room.locationId];
    final isActive = mark?.kind == RoomMarkKind.active;
    final isPending = mark?.kind == RoomMarkKind.pending;

    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFE0DCD5);
    Color textColor = AppTheme.textPrimary;

    if (isActive) {
      bgColor = AppTheme.primaryColor;
      borderColor = AppTheme.primaryDark;
      textColor = Colors.white;
    } else if (isPending) {
      bgColor = AppTheme.primaryContainer;
      borderColor = AppTheme.primaryLight;
      textColor = AppTheme.primaryDark;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: ValueKey('room-tile-${room.locationId}'),
        onTap: mark != null
            ? () => _showRoomOrdersSheet(
                  context: context,
                  room: room,
                  mark: mark,
                )
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 108,
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isActive ? 2 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isActive && mark?.stopNumber != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${mark!.stopNumber}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ] else if (isPending) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  room.room,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoomOrdersSheet({
    required BuildContext context,
    required CampusRoom room,
    required RoomMark mark,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return ChangeNotifierProvider<DeliveryProvider>.value(
          value: context.read<DeliveryProvider>(),
          child: Consumer<DeliveryProvider>(
            builder: (context, provider, _) {
              final activeOrders =
                  provider.activeOrdersForLocation(room.locationId);
              final pendingOrders =
                  provider.pendingOrdersForLocation(room.locationId);

              return SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        if (mark.isActive) ...[
                          for (final order in activeOrders)
                            MinimalOrderCard(
                              key: ValueKey('sheet-active-${order.orderId}'),
                              order: order,
                              stopNumber: mark.stopNumber,
                              action: FilledButton(
                                onPressed: order.status ==
                                            OrderStatus.outForDelivery &&
                                        !provider.isActionInProgress
                                    ? () async {
                                        final success = await provider
                                            .markDelivered(order.orderId);
                                        if (success && sheetContext.mounted) {
                                          Navigator.of(sheetContext).pop();
                                        }
                                      }
                                    : null,
                                child: const Text('Mark Delivered'),
                              ),
                            ),
                        ] else if (mark.isPending) ...[
                          for (final order in pendingOrders)
                            MinimalOrderCard(
                              key: ValueKey('sheet-pending-${order.orderId}'),
                              order: order,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
