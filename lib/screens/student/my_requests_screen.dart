import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/navigation_observer.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../widgets/request_thumbnail.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../../app/app_routes.dart';
import '../shared/notifications_screen.dart';
import 'request_details_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  Future<void> _editRequest(
    BuildContext context,
    RequestModel request,
    String userId,
  ) async {
    if (request.status != 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only pending requests can be edited.')),
      );
      return;
    }

    final editedRequest = await showDialog<_RequestEditData>(
      context: context,
      builder: (_) => _EditRequestDialog(request: request),
    );
    if (editedRequest == null || !context.mounted) return;

    try {
      await RequestService().updateStudentRequest(
        requestId: request.id,
        reportedBy: userId,
        issueType: editedRequest.issueType,
        description: editedRequest.description,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Request updated.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update request: $error')),
        );
      }
    }
  }

  Future<void> _deleteRequest(
    BuildContext context,
    RequestModel request,
    String userId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete request?'),
        content: const Text('This request will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await RequestService().deleteStudentRequest(
        requestId: request.id,
        reportedBy: userId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Request deleted.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete request: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF242735),
      appBar: AppBar(
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF242735),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('My Requests', style: TextStyle(fontSize: 17)),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsScreen(),
              ),
            ),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 16, 13, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1),
                  child: Text(
                    'Track the clean-up requests you have sent.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF242735)),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: user == null
                      ? const Center(
                          child: Text('Please log in to view your requests.'),
                        )
                      : StreamBuilder<List<RequestModel>>(
                          stream: RequestService().watchRequestsByReporter(
                            user.uid,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Unable to load your requests: '
                                  '${snapshot.error}',
                                ),
                              );
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final requests = snapshot.data ?? [];
                            if (requests.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No requests submitted yet.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: requests.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final request = requests[index];
                                return _MyRequestTile(
                                  request: request,
                                  onEdit: () =>
                                      _editRequest(context, request, user.uid),
                                  onDelete: () => _deleteRequest(
                                    context,
                                    request,
                                    user.uid,
                                  ),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => RequestDetailsScreen(
                                        request: request,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 39,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.map);
                    },
                    icon: const Icon(Icons.add, color: Color(0xFF299D50)),
                    label: const Text(
                      'Create a request',
                      style: TextStyle(
                        color: Color(0xFF299D50),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFBDBDBD)),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: CustomBottomNav(selectedIndex: 1),
    );
  }
}

class _MyRequestTile extends StatelessWidget {
  const _MyRequestTile({
    required this.request,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final RequestModel request;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = request.status.toLowerCase();
    final statusLabel = status.replaceAll('_', ' ');
    final Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = const Color(0xFFE7B35C);
      case 'in_progress':
      case 'accepted':
        statusColor = const Color(0xFFE7B35C);
      default:
        statusColor = const Color(0xFFE27F76);
    }

    return Material(
      color: const Color(0xFFE7E7E7),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: Row(
            children: [
              RequestThumbnail(request: request),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF292D32),
                      ),
                    ),
                    Text(
                      '${request.facilityId} ${request.issueType}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF777777),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Color(0xFF363B3F),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            'Floor ${request.floor ?? '?'} | ${request.facilityId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF777777),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_right, size: 19),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _actionButton(
                        icon: Icons.edit,
                        color: const Color(0xFF399849),
                        tooltip: 'Edit request',
                        onPressed: onEdit,
                      ),
                      const SizedBox(width: 2),
                      _actionButton(
                        icon: Icons.delete,
                        color: const Color(0xFFE12216),
                        tooltip: 'Delete request',
                        onPressed: onDelete,
                      ),
                      const SizedBox(width: 5),
                      Container(
                        constraints: const BoxConstraints(minWidth: 51),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF6D5640),
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 23,
      height: 23,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Container(
          width: 19,
          height: 19,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, size: 12, color: Colors.white),
        ),
      ),
    );
  }
}

class _RequestEditData {
  const _RequestEditData({required this.issueType, required this.description});

  final String issueType;
  final String description;
}

class _EditRequestDialog extends StatefulWidget {
  const _EditRequestDialog({required this.request});

  final RequestModel request;

  @override
  State<_EditRequestDialog> createState() => _EditRequestDialogState();
}

class _EditRequestDialogState extends State<_EditRequestDialog> {
  late final TextEditingController _descriptionController;
  late String _issueType;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.request.description,
    );
    _issueType = widget.request.issueType;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit request'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _issueType,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'cleaning', child: Text('Cleaning')),
                DropdownMenuItem(value: 'spill', child: Text('Spill')),
                DropdownMenuItem(value: 'trash', child: Text('Trash')),
                DropdownMenuItem(value: 'restroom', child: Text('Restroom')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _issueType = value);
              },
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Enter a description.'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _RequestEditData(
                issueType: _issueType,
                description: _descriptionController.text,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
