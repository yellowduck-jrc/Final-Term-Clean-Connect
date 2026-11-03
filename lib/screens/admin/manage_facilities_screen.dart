import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../app/navigation_observer.dart';

import '../../models/app_user_model.dart';
import '../../models/facility_model.dart';
import '../../models/request_model.dart';
import '../../services/facility_service.dart';
import '../../services/request_service.dart';
import '../../services/user_service.dart';

class ManageFacilitiesScreen extends StatelessWidget {
  const ManageFacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final facilities = FacilityService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Facilities'),
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Add facility',
            onPressed: () => _editFacility(context, facilities),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<List<FacilityModel>>(
        stream: facilities.watchFacilities(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load facilities: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No facilities yet. Use + to add a room.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            itemCount: snapshot.data!.length,
            separatorBuilder: (_, _) => const SizedBox(height: 9),
            itemBuilder: (context, index) {
              final facility = snapshot.data![index];
              return Material(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(10),
                child: ListTile(
                  leading: const _FacilityIcon(),
                  title: Text(
                    facility.roomName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Floor ${facility.floor} · ${facility.roomType}'
                    '${facility.isActive ? '' : ' · Inactive'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        tooltip: 'Facility actions',
                        onSelected: (action) {
                          if (action == 'delete') {
                            _deleteFacility(context, facilities, facility);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete facility'),
                          ),
                        ],
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => _FacilityOverviewScreen(
                        facility: facility,
                        onEdit: () =>
                            _editFacility(context, facilities, facility),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const AdminBottomNavigationBar(selectedIndex: 2),
    );
  }

  Future<void> _editFacility(
    BuildContext context,
    FacilityService service, [
    FacilityModel? existing,
  ]) async {
    final formKey = GlobalKey<FormState>();
    final id = TextEditingController(text: existing?.id ?? '');
    final roomName = TextEditingController(text: existing?.roomName ?? '');
    final roomType = TextEditingController(text: existing?.roomType ?? 'room');
    var floor = existing?.floor ?? 1;
    var isActive = existing?.isActive ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add facility' : 'Edit facility'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: id,
                    enabled: existing == null,
                    decoration: const InputDecoration(labelText: 'Facility ID'),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'Enter a facility ID.'
                        : null,
                  ),
                  TextFormField(
                    controller: roomName,
                    decoration: const InputDecoration(labelText: 'Room name'),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'Enter a room name.'
                        : null,
                  ),
                  TextFormField(
                    controller: roomType,
                    decoration: const InputDecoration(labelText: 'Room type'),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: floor,
                    decoration: const InputDecoration(labelText: 'Floor'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Floor 1')),
                      DropdownMenuItem(value: 2, child: Text('Floor 2')),
                      DropdownMenuItem(value: 3, child: Text('Floor 3')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialogState(() => floor = value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (value) =>
                        setDialogState(() => isActive = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  await service.saveFacility(
                    FacilityModel(
                      id: id.text.trim(),
                      roomName: roomName.text.trim(),
                      floor: floor,
                      roomType: roomType.text.trim().isEmpty
                          ? 'room'
                          : roomType.text.trim(),
                      isActive: isActive,
                    ),
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (error) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Unable to save facility: $error'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    id.dispose();
    roomName.dispose();
    roomType.dispose();
  }

  Future<void> _deleteFacility(
    BuildContext context,
    FacilityService service,
    FacilityModel facility,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete facility?'),
        content: Text(
          'Delete ${facility.roomName}? Existing requests will be retained.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await service.deleteFacility(facility.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete facility: $error')),
        );
      }
    }
  }
}

class _FacilityIcon extends StatelessWidget {
  const _FacilityIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 44,
    decoration: BoxDecoration(
      color: const Color(0xFF70A6D4),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

class _FacilityOverviewScreen extends StatelessWidget {
  const _FacilityOverviewScreen({required this.facility, required this.onEdit});

  final FacilityModel facility;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Facility Overview'),
        actions: [
          IconButton(
            tooltip: 'Edit facility',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: RequestService().watchRequestsByFacility(facility.id),
        builder: (context, requestsSnapshot) {
          if (requestsSnapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load facility requests: ${requestsSnapshot.error}',
              ),
            );
          }
          if (!requestsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = requestsSnapshot.data!;
          return StreamBuilder<List<AppUserModel>>(
            stream: UserService().watchUsersByRole('staff'),
            builder: (context, usersSnapshot) {
              if (usersSnapshot.hasError) {
                return Center(
                  child: Text('Unable to load users: ${usersSnapshot.error}'),
                );
              }
              if (!usersSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                children: [
                  _FacilityPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _FacilityIcon(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    facility.roomName,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Floor ${facility.floor}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        const Text(
                          'Description',
                          style: TextStyle(fontSize: 11),
                        ),
                        Text(
                          facility.roomType,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FacilityPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text('Floor ${facility.floor}'),
                        const SizedBox(height: 10),
                        Container(
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB0B0B0),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_outlined, size: 18),
                                SizedBox(width: 6),
                                Text('Map preview unavailable'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FacilityPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Requests',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text('${requests.length} on facility'),
                        const SizedBox(height: 8),
                        if (requests.isEmpty)
                          const Text('No requests for this facility.')
                        else
                          for (final request in requests)
                            _FacilityRequestTile(
                              request: request,
                              users: usersSnapshot.data!,
                            ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: const AdminBottomNavigationBar(selectedIndex: 2),
    );
  }
}

class _FacilityPanel extends StatelessWidget {
  const _FacilityPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFD9D9D9),
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
}

class _FacilityRequestTile extends StatelessWidget {
  const _FacilityRequestTile({required this.request, required this.users});

  final RequestModel request;
  final List<AppUserModel> users;

  @override
  Widget build(BuildContext context) {
    final matches = users.where((user) => user.uid == request.assignedTo);
    final assignedName = matches.isEmpty ? 'Assign' : matches.first.fullName;
    return Container(
      margin: const EdgeInsets.only(top: 7),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFB0B0B0),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.description,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            '${request.id} · ${request.issueType}',
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '♟  $assignedName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                request.status.replaceAll('_', ' '),
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
