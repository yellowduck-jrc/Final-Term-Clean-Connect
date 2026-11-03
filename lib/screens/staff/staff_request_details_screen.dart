import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/navigation_observer.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../widgets/status_badge.dart';

class StaffRequestDetailsScreen extends StatefulWidget {
  const StaffRequestDetailsScreen({super.key, required this.request});

  final RequestModel request;

  @override
  State<StaffRequestDetailsScreen> createState() =>
      _StaffRequestDetailsScreenState();
}

class _StaffRequestDetailsScreenState extends State<StaffRequestDetailsScreen> {
  final _requests = RequestService();
  bool _isUpdating = false;
  String? _errorMessage;

  Future<void> _updateRequest({required bool complete}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _errorMessage = 'Sign in again to update this request.');
      return;
    }
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });
    try {
      if (complete) {
        await _requests.completeRequest(widget.request.id, uid);
      } else {
        await _requests.acceptRequest(widget.request.id, uid);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAssignedToCurrentUser =
        widget.request.assignedTo == FirebaseAuth.instance.currentUser?.uid;
    final canAccept =
        widget.request.status == 'pending' &&
        (widget.request.assignedTo == null || isAssignedToCurrentUser);
    final canComplete =
        widget.request.status == 'in_progress' && isAssignedToCurrentUser;

    return Scaffold(
      appBar: AppBar(
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Request details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.request.issueType,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              StatusBadge(status: widget.request.status),
            ],
          ),
          const SizedBox(height: 20),
          Text('Facility: ${widget.request.facilityId}'),
          Text('Floor: ${widget.request.floor ?? 'Unknown'}'),
          Text('Reported by: ${widget.request.reportedBy}'),
          const SizedBox(height: 14),
          Text(widget.request.description),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (canAccept || canComplete) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isUpdating
                  ? null
                  : () => _updateRequest(complete: canComplete),
              child: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(canComplete ? 'Mark completed' : 'Accept request'),
            ),
          ],
        ],
      ),
    );
  }
}
