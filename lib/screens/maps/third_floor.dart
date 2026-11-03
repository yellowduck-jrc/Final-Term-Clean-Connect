import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../models/facility_model.dart';
import '../../models/request_model.dart';
import '../../services/facility_service.dart';
import '../../services/request_service.dart';
import '../student/file_request_screen.dart';

class ThirdFloorMapScreen extends StatefulWidget {
  const ThirdFloorMapScreen({super.key});

  @override
  State<ThirdFloorMapScreen> createState() => _ThirdFloorMapScreenState();
}

class _ThirdFloorMapScreenState extends State<ThirdFloorMapScreen> {
  static const _leftRooms = ['K-301', 'K-302', 'K-303', 'K-304'];
  static const _rightRooms = ['K-312', 'K-311', 'K-310', 'K-309'];
  static const _bottomRooms = ['Toilets', 'K-305', 'K-306', 'K-307', 'K-308'];

  String? _selectedRoom;

  String _key(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  FacilityModel _facilityFor(String room, List<FacilityModel> facilities) {
    for (final facility in facilities) {
      if (_key(facility.roomName) == _key(room) ||
          _key(facility.id) == _key(room)) {
        return facility;
      }
    }
    return FacilityModel(
      id: room,
      roomName: room,
      floor: 3,
      roomType: room == 'Toilets' ? 'restroom' : 'room',
      isActive: false,
    );
  }

  int _requestCount(
    String room,
    String status,
    List<FacilityModel> facilities,
    List<RequestModel> requests,
  ) {
    final facilityId = _key(_facilityFor(room, facilities).id);
    return requests
        .where(
          (request) =>
              _key(request.facilityId) == facilityId &&
              request.status == status,
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FacilityModel>>(
      stream: FacilityService().watchFacilities(floor: 3),
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
          stream: RequestService().watchRequestsByFloor(3),
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

            final facilities = facilitySnapshot.data!;
            final requests = requestSnapshot.data!;
            final selectedFacility = _selectedRoom == null
                ? null
                : _facilityFor(_selectedRoom!, facilities);

            return LayoutBuilder(
              builder: (context, constraints) {
                const referenceWidth = 325.0;
                final mapWidth = constraints.maxWidth;
                final contentWidth = (mapWidth - 16).clamp(0.0, mapWidth);
                final scale = contentWidth / referenceWidth;

                return SizedBox(
                  width: mapWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'HALLWAY',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12 * scale),
                        ),
                        SizedBox(height: 4 * scale),
                        _buildFloorPlan(scale, facilities, requests),
                        SizedBox(height: 5 * scale),
                        Text(
                          'HALLWAY',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12 * scale),
                        ),
                        SizedBox(height: 5 * scale),
                        _buildBottomRooms(
                          scale,
                          contentWidth,
                          facilities,
                          requests,
                        ),
                        SizedBox(height: 8 * scale),
                        _buildLegend(),
                        SizedBox(height: 10 * scale),
                        _buildRoomDetails(selectedFacility, requests),
                        SizedBox(height: 8 * scale),
                        _buildRecentRequests(requests),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFloorPlan(
    double scale,
    List<FacilityModel> facilities,
    List<RequestModel> requests,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapWidth = constraints.maxWidth;
        final sideWidth = mapWidth * 0.18;
        final sideGap = mapWidth * 0.04;
        final reservedWidth = sideWidth * 2 + sideGap * 2;
        final centerWidth = mapWidth > reservedWidth
            ? mapWidth - reservedWidth
            : 0.0;
        const roomSpacing = 1.0;
        final sideRoomHeight = sideWidth;
        final mainHeight =
            sideRoomHeight * _leftRooms.length +
            roomSpacing * (_leftRooms.length - 1);

        return SizedBox(
          height: mainHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: sideWidth,
                child: _buildSideRooms(
                  _leftRooms,
                  sideRoomHeight,
                  roomSpacing,
                  scale,
                  facilities,
                  requests,
                ),
              ),
              SizedBox(width: sideGap),
              SizedBox(
                width: centerWidth,
                height: mainHeight,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    border: Border.all(color: const Color(0xFF888888)),
                  ),
                  child: Text(
                    'OPEN\nBELOW',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: sideGap),
              SizedBox(
                width: sideWidth,
                child: _buildSideRooms(
                  _rightRooms,
                  sideRoomHeight,
                  roomSpacing,
                  scale,
                  facilities,
                  requests,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSideRooms(
    List<String> rooms,
    double roomHeight,
    double roomSpacing,
    double scale,
    List<FacilityModel> facilities,
    List<RequestModel> requests,
  ) {
    return Column(
      children: [
        for (var index = 0; index < rooms.length; index++) ...[
          if (index > 0) SizedBox(height: roomSpacing),
          SizedBox(
            height: roomHeight,
            width: double.infinity,
            child: _buildRoom(rooms[index], scale, facilities, requests),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomRooms(
    double scale,
    double mapWidth,
    List<FacilityModel> facilities,
    List<RequestModel> requests,
  ) {
    const referenceSpacing = 5.0;
    final spacing = referenceSpacing * scale;
    final roomWidth =
        (mapWidth - spacing * (_bottomRooms.length - 1)) / _bottomRooms.length;
    final roomHeight = 62 * scale;

    return SizedBox(
      height: roomHeight,
      child: Row(
        children: [
          for (var index = 0; index < _bottomRooms.length; index++) ...[
            if (index > 0) SizedBox(width: spacing),
            SizedBox(
              width: roomWidth,
              height: roomHeight,
              child: _buildRoom(
                _bottomRooms[index],
                scale,
                facilities,
                requests,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoom(
    String roomId,
    double scale,
    List<FacilityModel> facilities,
    List<RequestModel> requests,
  ) {
    final facility = _facilityFor(roomId, facilities);
    final pending = _requestCount(roomId, 'pending', facilities, requests);
    final inProgress = _requestCount(
      roomId,
      'in_progress',
      facilities,
      requests,
    );
    final selected = _selectedRoom == roomId;
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
          padding: EdgeInsets.symmetric(
            horizontal: 2 * scale,
            vertical: 3 * scale,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Colors.green[300]! : const Color(0xFF20A879),
              width: selected ? 2 * scale : scale,
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
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 2 * scale),
              CircleAvatar(
                radius: 9 * scale,
                backgroundColor: const Color(0xFF607D83),
                child: Text(
                  '$pending',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10 * scale,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (facility.isActive && inProgress > 0)
                Text(
                  '$inProgress active',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9 * scale),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 4,
      runSpacing: 4,
      children: const [
        _PlanLegend(color: Color(0xFFD9D9D9), label: 'No open requests'),
        _PlanLegend(color: Color(0xFFF2C58F), label: 'Open requests'),
        _PlanLegend(color: Color(0xFF78A9D7), label: 'In progress'),
        _PlanLegend(color: Color(0xFFE7837D), label: '3+ open requests'),
      ],
    );
  }

  Widget _buildRoomDetails(
    FacilityModel? facility,
    List<RequestModel> requests,
  ) {
    if (facility == null) {
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

    final pending = _requestCount(facility.roomName, 'pending', [
      facility,
    ], requests);
    final inProgress = _requestCount(facility.roomName, 'in_progress', [
      facility,
    ], requests);

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
              '${facility.roomName} · Floor 3 · $pending open · '
              '$inProgress in progress',
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

  Widget _buildRecentRequests(List<RequestModel> requests) {
    final recent = requests.where((request) => request.floor == 3).take(2);
    final recentRequests = recent.toList();

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
        if (recentRequests.isEmpty)
          const Text(
            'No recent requests.',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          )
        else
          for (final request in recentRequests) ...[
            _MapRequestTile(
              request: request,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.requestDetails,
                arguments: request,
              ),
            ),
            if (request != recentRequests.last) const SizedBox(height: 5),
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
                      'Floor ${request.floor ?? 3} | ${request.facilityId}',
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
