import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app/navigation_observer.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../widgets/status_badge.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Request Updates'),
      ),
      body: uid == null
          ? const Center(child: Text('Sign in to view updates.'))
          : StreamBuilder<List<RequestModel>>(
              stream: RequestService().watchRequestsForUser(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Unable to load updates: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final updates = snapshot.data!;
                if (updates.isEmpty) {
                  return const Center(child: Text('No request updates yet.'));
                }
                return ListView.separated(
                  itemCount: updates.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final request = updates[index];
                    final submittedAt = request.createdAt?.toLocal();
                    final submittedLabel = submittedAt == null
                        ? 'Submission date unavailable'
                        : 'Submitted ${submittedAt.month}/${submittedAt.day}/${submittedAt.year}';
                    return ListTile(
                      leading: const Icon(Icons.update_outlined),
                      title: Text('${request.issueType} request status'),
                      subtitle: Text(
                        '${request.facilityId}: ${request.description}\n'
                        '$submittedLabel',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: StatusBadge(status: request.status),
                    );
                  },
                );
              },
            ),
    );
  }
}
