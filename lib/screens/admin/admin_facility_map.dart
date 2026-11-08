
import 'package:flutter/material.dart';

import '../../models/facility_model.dart';
import '../../models/request_model.dart';
import '../../services/facility_service.dart';
import '../../services/request_service.dart';

class AdminFacilityMap extends StatelessWidget {
  const AdminFacilityMap({
    super.key,
    required this.floor,
    required this.onFacilityTap,
    this.selectedFacilityId,
  });

  final int floor;
  final ValueChanged<FacilityModel> onFacilityTap;
  final String? selectedFacilityId;

  static const _leftRooms = {
    1: ['K-101', 'K-102', 'K-103', 'K-104'],
    2: ['K-201', 'K-202', 'K-203', 'K-204'],
    3: ['K-301', 'K-302', 'K-303', 'K-304'],
  };

  static const _rightRooms = {
    1: ['K-109', 'K-108', 'PRIN. OFFICE', 'K-107'],
    2: ['K-211', 'K-210', 'K-209'],
    3: ['K-312', 'K-311', 'K-310', 'K-309'],
  };

  static const _bottomRooms = {
    1: ['Toilets', 'K-105', 'K-106'],
    2: ['Toilets', 'K-205', 'K-206', 'K-207', 'K-208'],
    3: ['Toilets', 'K-305', 'K-306', 'K-307', 'K-308'],
  };

  String _key(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  FacilityModel _facilityFor(
    String room,
    List<FacilityModel> facilities,
  ) {
    for (final facility in facilities) {
      if (_key(facility.roomName) == _key(room) ||
          _key(facility.id) == _key(room)) {
        return facility;
      }
    }

    return FacilityModel(
      id: room,
      roomName: room,
      floor: floor,
      roomType: room == 'Toilets' ? 'restroom' : 'room',
      isActive: false,
    );
  }

  int _count(
    FacilityModel facility,
    List<RequestModel> requests,
    String status,
  ) {
    return requests
        .where(
          (request) =>
              _key(request.facilityId) == _key(facility.id) &&
              request.status == status,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FacilityModel>>(
      stream: FacilityService().watchFacilities(floor: floor),
      builder: (context, facilitySnapshot) {
        if (facilitySnapshot.hasError) {
          return const Center(child: Text('Unable to load facilities.'));
        }

        if (!facilitySnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<RequestModel>>(
          stream: RequestService().watchRequestsByFloor(floor),
          builder: (context, requestSnapshot) {
            if (requestSnapshot.hasError) {
              return const Center(child: Text('Unable to load requests.'));
            }

            if (!requestSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final facilities = facilitySnapshot.data!;
            final requests = requestSnapshot.data!;
            final left = _leftRooms[floor]!;
            final right = _rightRooms[floor]!;
            final bottom = _bottomRooms[floor]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'HALLWAY',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final sideWidth = width * 0.19;
                    final spacing = width * 0.025;
                    final roomHeight = (width * 0.16).clamp(58.0, 78.0);
                    final height =
                        roomHeight * left.length + (left.length - 1);

                    final rightRoomHeight = right.length == left.length
                        ? roomHeight
                        : (height - (right.length - 1)) / right.length;

                    return SizedBox(
                      height: height,
                      child: Row(
                        children: [
                          SizedBox(
                            width: sideWidth,
                            child: _sideRooms(
                              left,
                              roomHeight,
                              facilities,
                              requests,
                            ),
                          ),
                          SizedBox(width: spacing),
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD9D9D9),
                                border: Border.all(
                                  color: const Color(0xFF888888),
                                ),
                              ),
                              child: Text(
                                floor == 1 ? 'QUADRANGLE' : 'OPEN\nBELOW',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: spacing),
                          SizedBox(
                            width: sideWidth,
                            child: _sideRooms(
                              right,
                              rightRoomHeight,
                              facilities,
                              requests,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'HALLWAY',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 4.0;
                    final roomWidth =
                        (constraints.maxWidth -
                            spacing * (bottom.length - 1)) /
                        bottom.length;

                    return Row(
                      children: [
                        for (var i = 0; i < bottom.length; i++) ...[
                          if (i > 0) const SizedBox(width: spacing),
                          SizedBox(
                            width: roomWidth,
                            height: 72,
                            child: _room(
                              bottom[i],
                              facilities,
                              requests,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Legend(color: Color(0xFFBDBDBD), label: 'Inactive'),
                    _Legend(color: Color(0xFFD9D9D9), label: 'No open requests'),
                    _Legend(color: Color(0xFFF2C58F), label: 'Open requests'),
                    _Legend(color: Color(0xFF78A9D7), label: 'In progress'),
                    _Legend(color: Color(0xFFE7837D), label: '3+ open'),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sideRooms(
    List<String> rooms,
    double height,
    List<FacilityModel> facilities,
    List<RequestModel> requests,
  ) {
    return Column(
      children: [
        for (var i = 0; i < rooms.length; i++) ...[
          if (i > 0) const SizedBox(height: 1),
          SizedBox(
            height: height,
            width: double.infinity,
            child: _room(rooms[i], facilities, requests),
          ),
        ],
      ],
    );
  }

  Widget _room(
    String room,
    List<FacilityModel> facilities,
    List<RequestModel> requests,
  ) {
    final facility = _facilityFor(room, facilities);
    final pending = _count(facility, requests, 'pending');
    final inProgress = _count(facility, requests, 'in_progress');
    final selected = selectedFacilityId != null &&
        _key(selectedFacilityId!) == _key(facility.id);

    final color = !facility.isActive
        ? const Color(0xFFBDBDBD)
        : pending >= 3
            ? const Color(0xFFE7837D)
            : pending > 0
                ? const Color(0xFFF2C58F)
                : inProgress > 0
                    ? const Color(0xFF78A9D7)
                    : const Color(0xFFD9D9D9);

    return Material(
      color: selected ? Colors.blue[200] : color,
      child: InkWell(
        onTap: () => onFacilityTap(facility),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? Colors.green
                  : const Color(0xFF20A879),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  facility.roomName,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              CircleAvatar(
                radius: 8,
                backgroundColor: const Color(0xFF607D83),
                child: Text(
                  '$pending',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                  ),
                ),
              ),
              if (facility.isActive && inProgress > 0)
                Text(
                  '$inProgress active',
                  maxLines: 1,
                  style: const TextStyle(fontSize: 8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black26),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9)),
      ],
    );
  }
}
