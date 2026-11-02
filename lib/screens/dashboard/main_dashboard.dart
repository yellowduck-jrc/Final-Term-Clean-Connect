import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../student/file_request_screen.dart';
import '../student/my_requests_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  String userName = 'User';

  @override
  void initState() {
    super.initState();
    getUserName();
  }

  Future<void> getUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (!mounted) return;

      if (result.docs.isNotEmpty) {
        Map<String, dynamic> data =
            result.docs.first.data() as Map<String, dynamic>;

        setState(() {
          userName = data['fullName'] ?? 'User';
        });
      } else {
        setState(() {
          userName = user.displayName ??
              user.email?.split('@')[0] ??
              'User';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = user.displayName ??
              user.email?.split('@')[0] ??
              'User';
        });
      }
    }
  }

  void openRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyRequestsScreen(),
      ),
    );
  }

  void openRequestForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FileRequestScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF242735),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Clean Connect',
          style: TextStyle(fontSize: 17),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications.'),
                ),
              );
            },
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 23,
                    backgroundColor: Color(0xFFE8E8E8),
                    child: Icon(
                      Icons.person,
                      color: Colors.black54,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $userName',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF292D3C),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Help keep your campus fresh and welcoming.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0EBFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, size: 21),
                    const SizedBox(height: 7),
                    const Text(
                      'See something that needs care?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF292D3C),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Send a quick campus clean-up request.',
                      style: TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 9),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton.icon(
                        onPressed: openRequestForm,
                        icon: const Icon(Icons.add, size: 19),
                        label: const Text(
                          'New request',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3478F6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Requests',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed: openRequests,
                    child: const Text(
                      'View All  ❯',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF3478F6),
                      ),
                    ),
                  ),
                ],
              ),
              if (user == null)
                const Text('Please log in to view your requests.')
              else
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('requests')
                      .where('reportedBy', isEqualTo: user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Unable to load requests.');
                    }

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    List<QueryDocumentSnapshot> docs =
                        snapshot.data?.docs ?? [];

                    docs.sort((a, b) {
                      Map<String, dynamic> first =
                          a.data() as Map<String, dynamic>;
                      Map<String, dynamic> second =
                          b.data() as Map<String, dynamic>;

                      int dateA = first['createdAt'] is Timestamp
                          ? (first['createdAt'] as Timestamp)
                              .millisecondsSinceEpoch
                          : 0;

                      int dateB = second['createdAt'] is Timestamp
                          ? (second['createdAt'] as Timestamp)
                              .millisecondsSinceEpoch
                          : 0;

                      return dateB.compareTo(dateA);
                    });

                    if (docs.isEmpty) {
                      return const Text(
                        'You have no cleaning requests yet.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    }

                    return Column(
                      children: docs.take(2).map((doc) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: CleaningRequestCard(
                            data: doc.data() as Map<String, dynamic>,
                            onTap: openRequests,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: 0,
        onTap: (index) {
          if (index == 1) {
            openRequests();
          } else if (index == 2 || index == 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This screen is not connected yet.'),
              ),
            );
          }
        },
      ),
    );
  }
}

class CleaningRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const CleaningRequestCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String description =
        data['description'] ?? 'Cleaning request';
    String facilityId = data['facilityId'] ?? 'Unknown facility';
    String issueType = data['issueType'] ?? 'cleaning';
    String floor = '${data['floor'] ?? '?'}';
    String status = data['status'] ?? 'pending';

    Color statusColor;

    if (status.toLowerCase() == 'pending') {
      statusColor = const Color(0xFFF2BD79);
    } else if (status.toLowerCase() == 'accepted' ||
        status.toLowerCase() == 'in progress') {
      statusColor = const Color(0xFF83D9B3);
    } else if (status.toLowerCase() == 'completed') {
      statusColor = const Color(0xFF83D9B3);
    } else {
      statusColor = const Color(0xFFF28B82);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD5D5D5)),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
            Text(
              '$facilityId  ${issueType.toUpperCase()}',
              style: const TextStyle(
                fontSize: 9,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    'Floor $floor | $facilityId',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    List<IconData> icons = [
      Icons.home_outlined,
      Icons.fact_check_outlined,
      Icons.map_outlined,
      Icons.person_outline,
    ];

    List<String> labels = ['Home', 'Requests', 'Map', 'Profile'];

    return Container(
      color: const Color(0xFFE0E0E0),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(icons.length, (index) {
            bool selected = index == selectedIndex;

            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 45,
                      height: 27,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF83D9B3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icons[index], size: 19),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      labels[index],
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}