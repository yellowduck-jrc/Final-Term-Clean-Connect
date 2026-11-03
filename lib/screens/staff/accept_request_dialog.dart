import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/request_model.dart';
import '../../services/request_service.dart';

Future<void> showAcceptRequestDialog(
  BuildContext context,
  RequestModel request,
) async {
  final staffUid = FirebaseAuth.instance.currentUser?.uid;
  if (staffUid == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in again to accept this request.')),
    );
    return;
  }

  var isAccepting = false;
  String? errorMessage;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Accept request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${request.facilityId} · Floor ${request.floor ?? '?'}'),
            const SizedBox(height: 4),
            Text(request.issueType),
            const SizedBox(height: 8),
            Text(request.description),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: isAccepting
                ? null
                : () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: isAccepting
                ? null
                : () async {
                    setDialogState(() {
                      isAccepting = true;
                      errorMessage = null;
                    });
                    try {
                      await RequestService().acceptRequest(
                        request.id,
                        staffUid,
                      );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop(true);
                      }
                    } catch (error) {
                      if (dialogContext.mounted) {
                        setDialogState(() {
                          isAccepting = false;
                          errorMessage = error
                              .toString()
                              .replaceFirst('Bad state: ', '');
                        });
                      }
                    }
                  },
            child: isAccepting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Accept request'),
          ),
        ],
      ),
    ),
  );

  if (accepted == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request accepted.')),
    );
  }
}
