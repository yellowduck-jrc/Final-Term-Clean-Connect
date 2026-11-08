import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../app/navigation_observer.dart';
import '../../models/facility_model.dart';
import '../../models/request_model.dart';
import '../../services/facility_service.dart';
import '../../services/request_service.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../widgets/request_thumbnail.dart';

const _headerColor = Color(0xFF242735);
const _detailGreen = Color(0xFF399849);
const _detailGray = Color(0xFFD9D9D9);

class RequestDetailsScreen extends StatelessWidget {
  const RequestDetailsScreen({super.key, required this.request});

  final RequestModel request;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _headerColor,
    appBar: AppBar(
      leading: const NavigationBackButton(),
      automaticallyImplyLeading: false,
      backgroundColor: _headerColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'Request',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.notifications),
          icon: const Icon(Icons.notifications_none),
        ),
      ],
    ),
    body: ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: ColoredBox(
        color: Colors.white,
        child: StreamBuilder<RequestModel?>(
          stream: RequestService().watchRequest(request.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load request details: ${snapshot.error}',
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final currentRequest = snapshot.data;
            if (currentRequest == null) {
              return const Center(
                child: Text('This request no longer exists.'),
              );
            }
            return FutureBuilder<FacilityModel?>(
              future: FacilityService().getFacility(currentRequest.facilityId),
              builder: (context, facilitySnapshot) {
                if (facilitySnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load facility details: '
                      '${facilitySnapshot.error}',
                    ),
                  );
                }
                return _RequestDetailsContent(
                  request: currentRequest,
                  facility: facilitySnapshot.data,
                );
              },
            );
          },
        ),
      ),
    ),
    bottomNavigationBar: const CustomBottomNav(selectedIndex: 1),
  );
}

class _RequestDetailsContent extends StatelessWidget {
  const _RequestDetailsContent({required this.request, required this.facility});

  final RequestModel request;
  final FacilityModel? facility;

  @override
  Widget build(BuildContext context) {
    final submitted = request.createdAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(17, 14, 17, 20),
      children: [
        _DetailsPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.issueType,
                style: const TextStyle(
                  color: _detailGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                submitted == null
                    ? 'Date unavailable'
                    : _formatSubmitted(submitted),
                style: const TextStyle(fontSize: 11),
              ),
              const Divider(height: 15),
              const Text('Description', style: TextStyle(fontSize: 11)),
              Text(request.description, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DetailsPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: _detailGreen, size: 25),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          color: _detailGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_floorLabel(request.floor ?? facility?.floor)} · '
                        'Near ${facility?.roomName ?? request.facilityId}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  border: Border.all(color: _detailGreen),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: RequestThumbnail(
                  request: request,
                  width: double.infinity,
                  height: 108,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DetailsPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assigned Worker',
                style: TextStyle(
                  color: _detailGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              _AssignedWorker(assignedTo: request.assignedTo),
            ],
          ),
        ),
        const SizedBox(height: 9),
        _DetailsPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status',
                style: TextStyle(
                  color: _detailGreen,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  _StatusChip(
                    label: 'Pending',
                    selected: request.status == 'pending',
                  ),
                  const SizedBox(width: 7),
                  _StatusChip(
                    label: 'In Progress',
                    selected:
                        request.status == 'in_progress' ||
                        request.status == 'accepted',
                  ),
                  const SizedBox(width: 7),
                  _StatusChip(
                    label: 'Complete',
                    selected: request.status == 'completed',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _detailGray,
      borderRadius: BorderRadius.circular(9),
    ),
    child: child,
  );
}

class _AssignedWorker extends StatelessWidget {
  const _AssignedWorker({required this.assignedTo});

  final String? assignedTo;

  @override
  Widget build(BuildContext context) {
    if (assignedTo == null || assignedTo!.trim().isEmpty) {
      return const _WorkerName(name: 'None');
    }

    return FutureBuilder(
      future: UserService().getUser(assignedTo!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Unable to load assigned worker: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _WorkerName(name: 'Loading…');
        }
        return _WorkerName(name: snapshot.data?.fullName ?? 'None');
      },
    );
  }
}

class _WorkerName extends StatelessWidget {
  const _WorkerName({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Container(
    height: 31,
    width: double.infinity,
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(name, style: const TextStyle(fontSize: 12)),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? _detailGreen : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black,
          fontSize: 11,
        ),
      ),
    ),
  );
}

String _floorLabel(int? floor) => switch (floor) {
  1 => 'First Floor',
  2 => 'Second Floor',
  3 => 'Third Floor',
  _ => 'Floor Unknown',
};

String _formatSubmitted(DateTime value) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final meridiem = local.hour < 12 ? 'AM' : 'PM';
  return '${months[local.month - 1]} ${local.day}, ${local.year} · '
      '$hour:$minute $meridiem';
}
