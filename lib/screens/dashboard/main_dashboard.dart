import 'package:flutter/material.dart';

import '../../app/navigation_observer.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/app_routes.dart';
import '../../models/request_model.dart';
import '../../widgets/request_thumbnail.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../shared/notifications_screen.dart';
import '../student/request_details_screen.dart';

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
          userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
        });
      }
    }
  }

  void openRequests() {
    Navigator.pushNamed(context, AppRoutes.myRequests);
  }

  void openRequestForm() {
    Navigator.pushNamed(context, AppRoutes.map);
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF242735),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/auth/broom.png',
          width: 52,
          height: 40,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            tooltip: 'Request updates',
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
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
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF292D3C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Help keep your campus fresh and welcoming.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC3E8DC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF40434A),
                          ),
                          children: const [
                            TextSpan(text: 'See something that '),
                            TextSpan(
                              text: 'needs care?',
                              style: TextStyle(color: Color(0xFF299D50)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Send a quick campus clean-up request.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 30,
                        child: ElevatedButton.icon(
                          onPressed: openRequestForm,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New request'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF399849),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 11),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (user != null)
                  _StudentRequestStats(uid: user.uid, onViewAll: openRequests),
                Padding(
                  padding: const EdgeInsets.only(left: 2, top: 2, bottom: 1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Requests',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      TextButton(
                        onPressed: openRequests,
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'View All  ›',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF1458D3),
                          ),
                        ),
                      ),
                    ],
                  ),
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

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
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
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        );
                      }

                      return Column(
                        children: docs.take(3).map((doc) {
                          final request = RequestModel.fromMap(
                            doc.data() as Map<String, dynamic>,
                            id: doc.id,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _DashboardRequestCard(
                              request: request,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      RequestDetailsScreen(request: request),
                                ),
                              ),
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
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: 0,
        selectedColor: const Color(0xFF399849),
      ),
    );
  }
}

class _StudentRequestStats extends StatelessWidget {
  const _StudentRequestStats({required this.uid, required this.onViewAll});

  final String uid;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .where('reportedBy', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Unable to load request statistics: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const LinearProgressIndicator();
        }
        final today = DateTime.now();
        final todayDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = data['createdAt'];
          if (timestamp is! Timestamp) return false;
          final date = timestamp.toDate();
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        });
        final todayRequests = todayDocs.toList();
        int countStatus(Set<String> statuses) => todayRequests.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return statuses.contains(
            (data['status'] as String? ?? '').toLowerCase().replaceAll(
              ' ',
              '_',
            ),
          );
        }).length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Requests Update Today',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'View All  ›',
                      style: TextStyle(fontSize: 10, color: Color(0xFF1458D3)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _StudentStatCard(
                      label: 'Pending Request',
                      value: countStatus({'pending'}),
                      color: const Color(0xFFE99735),
                      caption: 'for today',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StudentStatCard(
                      label: 'On Progress',
                      value: countStatus({'in_progress', 'accepted'}),
                      color: const Color(0xFF6FA4D9),
                      caption: 'for today',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StudentStatCard(
                      label: 'Finished Request',
                      value: countStatus({'completed'}),
                      color: const Color(0xFFEE857F),
                      caption: 'for today',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StudentStatCard extends StatelessWidget {
  const _StudentStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.caption,
  });

  final String label;
  final int value;
  final Color color;
  final String caption;

  @override
  Widget build(BuildContext context) => Container(
    height: 112,
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFF399849), width: 1.2),
      borderRadius: BorderRadius.circular(17),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 3,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          caption,
          style: const TextStyle(fontSize: 9, color: Color(0xFF777777)),
        ),
      ],
    ),
  );
}

class _DashboardRequestCard extends StatelessWidget {
  const _DashboardRequestCard({required this.request, required this.onTap});

  final RequestModel request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = request.status.toLowerCase();
    final statusLabel = status.replaceAll('_', ' ');
    final Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = const Color(0xFFE8B35D);
      case 'in_progress':
      case 'accepted':
        statusColor = const Color(0xFFDAB86E);
      case 'completed':
        statusColor = const Color(0xFFDF7D72);
      default:
        statusColor = const Color(0xFFDF7D72);
    }

    return Material(
      color: const Color(0xFFC3E8DC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              RequestThumbnail(request: request),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF299D50),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${request.facilityId} ${request.issueType}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF6A7073),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Color(0xFF36404A),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            'Floor ${request.floor ?? '?'} | ${request.facilityId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF6A7073),
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
                children: [
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: Color(0xFF252A2D),
                  ),
                  const SizedBox(height: 13),
                  Container(
                    constraints: const BoxConstraints(minWidth: 50),
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
                        color: Color(0xFF5F4A33),
                        fontSize: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    String description = data['description'] ?? 'Cleaning request';
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
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    'Floor $floor | $facilityId',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
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
