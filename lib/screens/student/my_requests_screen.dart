import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../dashboard/main_dashboard.dart';
import 'file_request_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    void showMessage(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xFF242735),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My requests',
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          IconButton(
            onPressed: () {
              showMessage('No new notifications.');
            },
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Track the clean-up requests you have sent.',
                style: TextStyle(fontSize: 11),
              ),

              const SizedBox(height: 14),

              Expanded(
                child: user == null
                    ? const Center(
                        child: Text(
                          'Please log in to view your requests.',
                        ),
                      )
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('requests')
                            .where(
                              'reportedBy',
                              isEqualTo: user.uid,
                            )
                            .snapshots(),

                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text(
                                'Unable to load your requests.',
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          List<QueryDocumentSnapshot> requests =
                              snapshot.data?.docs ?? [];

                          requests.sort((a, b) {
                            Map<String, dynamic> first =
                                a.data() as Map<String, dynamic>;

                            Map<String, dynamic> second =
                                b.data() as Map<String, dynamic>;

                            int dateA =
                                first['createdAt'] is Timestamp
                                    ? (first['createdAt'] as Timestamp)
                                        .millisecondsSinceEpoch
                                    : 0;

                            int dateB =
                                second['createdAt'] is Timestamp
                                    ? (second['createdAt'] as Timestamp)
                                        .millisecondsSinceEpoch
                                    : 0;

                            return dateB.compareTo(dateA);
                          });

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

                          return ListView.builder(
                            itemCount: requests.length,
                            itemBuilder: (context, index) {
                              Map<String, dynamic> data =
                                  requests[index].data()
                                      as Map<String, dynamic>;

                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 9,
                                ),
                                child: CleaningRequestCard(
                                  data: data,
                                  onTap: () {
                                    String description =
                                        data['description'] ??
                                            'Cleaning request';

                                    showMessage(description);
                                  },
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const FileRequestScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.add,
                    color: Color(0xFF20A879),
                  ),
                  label: const Text(
                    'Create a request',
                    style: TextStyle(
                      color: Color(0xFF20A879),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFBDBDBD),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: CustomBottomNav(
        selectedIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainDashboard(),
              ),
            );
          } else if (index == 2 || index == 3) {
            showMessage('This screen is not connected yet.');
          }
        },
      ),
    );
  }
}