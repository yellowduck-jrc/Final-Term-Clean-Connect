import 'package:flutter/material.dart';

import '../../app/navigation_observer.dart';
import '../../models/request_model.dart';
import '../../services/facility_service.dart';
import '../../widgets/status_badge.dart';

class RequestDetailsScreen extends StatelessWidget {
  const RequestDetailsScreen({super.key, required this.request});

  final RequestModel request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Request details'),
      ),
      body: FutureBuilder(
        future: FacilityService().getFacility(request.facilityId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load facility details: ${snapshot.error}'),
            );
          }
          final facility = snapshot.data;
          final submitted = request.createdAt;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.issueType,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  StatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 20),
              _DetailRow(
                label: 'Facility',
                value: facility?.roomName ?? request.facilityId,
              ),
              _DetailRow(
                label: 'Floor',
                value: '${request.floor ?? facility?.floor ?? 'Unknown'}',
              ),
              _DetailRow(label: 'Description', value: request.description),
              _DetailRow(
                label: 'Submitted',
                value: submitted == null
                    ? 'Date unavailable'
                    : '${submitted.toLocal()}',
              ),
              _DetailRow(
                label: 'Assigned staff',
                value: request.assignedTo ?? 'Not assigned',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value),
      ],
    ),
  );
}