import 'package:flutter/material.dart';

import '../models/facility_model.dart';

class RoomContainer extends StatelessWidget {
  const RoomContainer({
    super.key,
    required this.facility,
    required this.pendingRequests,
    this.inProgressRequests = 0,
    this.selected = false,
    this.onTap,
  });

  final FacilityModel facility;
  final int pendingRequests;
  final int inProgressRequests;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = pendingRequests == 0
        ? inProgressRequests > 0
              ? const Color(0xFF78A9D7)
              : const Color(0xFFE5F3EC)
        : pendingRequests < 3
        ? const Color(0xFFFFE9C2)
        : const Color(0xFFFFDAD6);
    return Material(
      color: selected ? Colors.blue[200] : statusColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? Colors.green[300]!
                  : const Color(0xFFB7C7BD),
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                facility.roomName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '$pendingRequests open'
                '${inProgressRequests > 0 ? ' · $inProgressRequests active' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoomDetailsPanel extends StatelessWidget {
  const RoomDetailsPanel({
    super.key,
    required this.facility,
    required this.pendingRequests,
    required this.inProgressRequests,
    required this.onReport,
  });

  final FacilityModel facility;
  final int pendingRequests;
  final int inProgressRequests;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D1D1)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            facility.roomName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Floor ${facility.floor} · ${facility.roomType}\n'
            '$pendingRequests open requests · '
            '$inProgressRequests in progress',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Report an issue'),
            ),
          ),
        ],
      ),
    );
  }
}
