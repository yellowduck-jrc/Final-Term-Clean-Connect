import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../models/facility_model.dart';
import '../../models/request_model.dart';
import '../../services/facility_service.dart';
import '../../services/request_service.dart';
import '../student/file_request_screen.dart';

class FirstFloorMapScreen extends StatelessWidget {
  const FirstFloorMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FacilityModel>>(
      stream: FacilityService().watchFacilities(floor: 1),
      builder: (context, facilitySnapshot) {
        if (facilitySnapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load floor facilities: ${facilitySnapshot.error}',
            ),
          );
        }
        if (!facilitySnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<List<RequestModel>>(
          stream: RequestService().watchRequestsByFloor(1),
          builder: (context, requestSnapshot) {
            if (requestSnapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load request counts: ${requestSnapshot.error}',
                ),
              );
            }
            if (!requestSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            return FirstFloorPlan(
              facilities: facilitySnapshot.data!,
              requests: requestSnapshot.data!,
            );
          },
        );
      },
    );
  }
}

class FirstFloorPlan extends StatefulWidget {
  const FirstFloorPlan({
    super.key,
    required this.facilities,
    required this.requests,
  });

  final List<FacilityModel> facilities;
  final List<RequestModel> requests;

  @override
  State<FirstFloorPlan> createState() => _FirstFloorPlanState();
}

class _FirstFloorPlanState extends State<FirstFloorPlan> {
  static const _leftRooms = ['K-101', 'K-102', 'K-103', 'K-104'];
  static const _rightRooms = ['K-109', 'K-108', 'PRIN. OFFICE', 'K-107'];
  static const _bottomRooms = ['Toilets', 'K-105', 'K-106'];
  static const _roomSubtitles = {'K-105': 'ES CANTEEN', 'K-107': 'HELE RM.'};

  String? _selectedRoom;

  String _key(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  FacilityModel _facilityFor(String room) {
    for (final facility in widget.facilities) {
      if (_key(facility.roomName) == _key(room) ||
          _key(facility.id) == _key(room)) {
        return facility;
      }
    }
    return FacilityModel(
      id: room,
      roomName: room,
      floor: 1,
      roomType: room == 'Toilets' ? 'restroom' : 'room',
      isActive: false,
    );
  }

  int _requestCount(String room, String status) => widget.requests
      .where(
        (request) =>
            _key(request.facilityId) == _key(_facilityFor(room).id) &&
            request.status == status,
      )
      .length;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapWidth = constraints.maxWidth;
        final bottomSpacing = (mapWidth * 0.012).clamp(5.0, 6.0);
        final sideSpacing = mapWidth * 0.035;
        final sideWidth = mapWidth * 0.185;
        final sideRoomHeight = (mapWidth * 0.15).clamp(75.0, 85.0);
        final bottomWidth =
            (mapWidth - bottomSpacing * (_bottomRooms.length - 1)) /
            _bottomRooms.length;
        final bottomRoomHeight = (bottomWidth * 0.46).clamp(75.0, 85.0);
        final sideRoomSpacing = 1.0;
        final mapHeight =
            sideRoomHeight * _leftRooms.length +
            sideRoomSpacing * (_leftRooms.length - 1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('HALLWAY', textAlign: TextAlign.center),
            const SizedBox(height: 6),
            SizedBox(
              height: mapHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: sideWidth,
                    child: _buildSideRooms(
                      _leftRooms,
                      sideWidth,
                      sideRoomHeight,
                      sideRoomSpacing,
                    ),
                  ),
                  SizedBox(width: sideSpacing),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        border: Border.all(color: const Color(0xFF888888)),
                      ),
                      child: const Text(
                        'QUADRANGLE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: sideSpacing),
                  SizedBox(
                    width: sideWidth,
                    child: _buildSideRooms(
                      _rightRooms,
                      sideWidth,
                      sideRoomHeight,
                      sideRoomSpacing,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text('HALLWAY', textAlign: TextAlign.center),
            const SizedBox(height: 6),
            SizedBox(
              height: bottomRoomHeight,
              child: Row(
                children: [
                  for (var index = 0; index < _bottomRooms.length; index++) ...[
                    if (index > 0) SizedBox(width: bottomSpacing),
                    SizedBox(
                      width: bottomWidth,
                      child: _buildRoom(_bottomRooms[index]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 4,
              runSpacing: 4,
              children: [
                _PlanLegend(
                  color: Color(0xFFD9D9D9),
                  label: 'No open requests',
                ),
                _PlanLegend(color: Color(0xFFF2C58F), label: 'Open requests'),
                _PlanLegend(color: Color(0xFF78A9D7), label: 'In progress'),
                _PlanLegend(
                  color: Color(0xFFE7837D),
                  label: '3+ open requests',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRoomDetails(),
            const SizedBox(height: 8),
            _buildRecentRequests(),
          ],
        );
      },
    );
  }

  Widget _buildSideRooms(
    List<String> rooms,
    double roomWidth,
    double roomHeight,
    double roomSpacing,
  ) => Column(
    children: [
      for (var index = 0; index < rooms.length; index++) ...[
        if (index > 0) SizedBox(height: roomSpacing),
        SizedBox(
          width: roomWidth,
          height: roomHeight,
          child: _buildRoom(rooms[index]),
        ),
      ],
    ],
  );

  Widget _buildRoom(String roomId) {
    final facility = _facilityFor(roomId);
    final pending = _requestCount(roomId, 'pending');
    final inProgress = _requestCount(roomId, 'in_progress');
    final selected = _selectedRoom == roomId;
    final subtitle =
        _roomSubtitles[facility.roomName] ?? _roomSubtitles[roomId];
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
        onTap: () => setState(() => _selectedRoom = roomId),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.green[300]! : const Color(0xFF20A879),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              CircleAvatar(
                radius: 9,
                backgroundColor: const Color(0xFF607D83),
                child: Text(
                  '$pending',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (facility.isActive && inProgress > 0)
                Text(
                  '$inProgress active',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomDetails() {
    final roomId = _selectedRoom;
    if (roomId == null) {
      return Container(
        alignment: Alignment.center,
        constraints: const BoxConstraints(minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD1D1D1)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Text(
          'Tap a room to view its details.',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      );
    }

    final facility = _facilityFor(roomId);
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D1D1)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${facility.roomName} · Floor 1 · '
              '${_requestCount(roomId, 'pending')} open',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => FileRequestScreen(initialFacility: facility),
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30),
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRequests() {
    final recent = widget.requests
        .where((request) => request.floor == 1)
        .take(2)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Requests',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.myRequests),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View All', style: TextStyle(fontSize: 10)),
                  Icon(Icons.chevron_right, size: 15),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (recent.isEmpty)
          const Text(
            'No recent requests.',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          )
        else
          for (final request in recent) ...[
            _MapRequestTile(
              request: request,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.requestDetails,
                arguments: request,
              ),
            ),
            if (request != recent.last) const SizedBox(height: 5),
          ],
      ],
    );
  }
}

class _MapRequestTile extends StatelessWidget {
  const _MapRequestTile({required this.request, required this.onTap});

  final RequestModel request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (request.status) {
      'in_progress' => const Color(0xFFF2C58F),
      'completed' => const Color(0xFF83D9B3),
      'cancelled' => const Color(0xFFD9D9D9),
      _ => const Color(0xFFE7837D),
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD6D6D6)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 19),
                ],
              ),
              Text(
                request.issueType,
                style: const TextStyle(fontSize: 10, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 12),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      'Floor ${request.floor ?? 1} | ${request.facilityId}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request.status.replaceAll('_', ' '),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanLegend extends StatelessWidget {
  const _PlanLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black26),
        ),
      ),
      const SizedBox(width: 3),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(fontSize: 10, color: Colors.black54),
      ),
    ],
  );
}
