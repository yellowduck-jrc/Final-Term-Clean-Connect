import 'package:flutter/material.dart';

class FirstFloorMapScreen extends StatefulWidget {
  const FirstFloorMapScreen({super.key});

  @override
  State<FirstFloorMapScreen> createState() => _FirstFloorMapScreenState();
}

final Map<String, int> rightFirstFloorRooms = {
  'K-101': 0,
  'K-102': 1,
  'K-103': 0,
  'K-104': 3,
};

final Map<String, int> leftFirstFloorRooms = {
  'Clinic': 0,
  'K-107': 0,
  'K-108': 2,
  'K-109': 0,
};

final Map<String, int> bottomFirstFloorRooms = {'K-105': 0, 'K-106': 0};

class _FirstFloorMapScreenState extends State<FirstFloorMapScreen> {
  String? selectedRoom;

  Color getRoomColor(String roomName, int requests) {
    if (selectedRoom == roomName) {
      return const Color(0xFF7CB5DB);
    }

    if (requests >= 3) {
      return const Color(0xFFE99087);
    }

    if (requests > 0) {
      return const Color(0xFFF0BF89);
    }

    return const Color(0xFFD9D9D9);
  }

  Widget buildRoom(
    String roomName, {
    int requests = 0,
    String? subtitle,
    int flex = 1,
  }) {
    final isSelected = selectedRoom == roomName;

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedRoom = isSelected ? null : roomName;
          });
        },
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: getRoomColor(roomName, requests),
            border: Border.all(
              color: const Color(0xFF159A83),
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                roomName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9),
                ),
              const SizedBox(height: 3),
              CircleAvatar(
                radius: 10,
                backgroundColor: const Color(0xFF607D86),
                child: Text(
                  '$requests',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (isSelected)
                const Text('active', style: TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRoomColumn(Map<String, int> rooms) {
    return Column(
      children: [
        for (final entry in rooms.entries)
          buildRoom(entry.key, requests: entry.value),
      ],
    );
  }

  Widget buildLegend(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  int getSelectedRoomRequests() {
    if (selectedRoom == null) return 0;

    return rightFirstFloorRooms[selectedRoom] ??
        leftFirstFloorRooms[selectedRoom] ??
        bottomFirstFloorRooms[selectedRoom] ??
        0;
  }

  Widget buildSelectedRoomDetails() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: selectedRoom == null
          ? const Center(
              child: Text(
                'Tap a room to view its details.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            )
          : Row(
              children: [
                const Icon(Icons.meeting_room_outlined, color: Colors.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedRoom!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${getSelectedRoomRequests()} open requests',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
    );
  }

  Widget buildRequestCard({
    required String title,
    required String requestId,
    required String category,
    required String location,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '$requestId $category',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(fontSize: 9, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FLOOR PLAN TITLE
          const Center(
            child: Text(
              'FIRST FLOOR PLAN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 10),

          // FLOOR MAP
          SizedBox(
            height: 350,
            child: Column(
              children: [
                Expanded(
                  flex: 4,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 2,
                        child: buildRoomColumn(rightFirstFloorRooms),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 24,
                              child: Center(
                                child: Text(
                                  'HALLWAY',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD9D9D9),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: const Text(
                                  'OPEN\nBELOW',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        flex: 2,
                        child: buildRoomColumn(leftFirstFloorRooms),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 28,
                  child: Center(
                    child: Text('HALLWAY', style: TextStyle(fontSize: 11)),
                  ),
                ),

                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      buildRoom(
                        'K-105',
                        subtitle: 'ES Canteen',
                        requests: bottomFirstFloorRooms['K-105']!,
                        flex: 3,
                      ),
                      const SizedBox(width: 10),
                      buildRoom(
                        'K-106',
                        requests: bottomFirstFloorRooms['K-106']!,
                        flex: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // STATUS LEGEND
          Wrap(
            spacing: 10,
            runSpacing: 7,
            children: [
              buildLegend(const Color(0xFFD9D9D9), 'No open requests'),
              buildLegend(const Color(0xFFF0BF89), 'Open requests'),
              buildLegend(const Color(0xFF7CB5DB), 'In progress'),
              buildLegend(const Color(0xFFE99087), '3+ open requests'),
            ],
          ),

          const SizedBox(height: 16),

          buildSelectedRoomDetails(),

          const SizedBox(height: 10),

          // RECENT REQUESTS HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Requests',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  debugPrint('View All tapped');
                },
                child: const Text('View All ›', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),

          // SAMPLE REQUESTS
          buildRequestCard(
            title: 'Spill near the main entrance',
            requestId: 'CC-1042',
            category: 'Spill',
            location: 'Floor 1 | K-101',
            status: 'In progress',
            statusColor: const Color(0xFFF0BF89),
          ),

          buildRequestCard(
            title: 'Restroom needs attention',
            requestId: 'CC-1041',
            category: 'Restroom',
            location: 'Floor 1 | K-105',
            status: 'Open',
            statusColor: const Color(0xFFE99087),
          ),
        ],
      ),
    );
  }
}
