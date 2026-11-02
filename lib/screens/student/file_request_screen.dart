import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../dashboard/main_dashboard.dart';
import 'my_requests_screen.dart';

class FileRequestScreen extends StatefulWidget {
  const FileRequestScreen({super.key});

  @override
  State<FileRequestScreen> createState() =>
      _FileRequestScreenState();
}

class _FileRequestScreenState extends State<FileRequestScreen> {
  final TextEditingController descriptionController =
      TextEditingController();

  String? selectedFacilityId;
  String issueType = 'cleaning';
  bool isSubmitting = false;

  final Color navy = const Color(0xFF242735);
  final Color green = const Color(0xFF20A879);

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> submitRequest() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('Please log in first.');
      return;
    }

    if (selectedFacilityId == null) {
      showMessage('Please select a room.');
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      showMessage('Please enter a description.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      DocumentSnapshot facility = await FirebaseFirestore.instance
          .collection('facilities')
          .doc(selectedFacilityId)
          .get();

      if (!facility.exists) {
        showMessage('The selected room no longer exists.');
        return;
      }

      Map<String, dynamic> facilityData =
          facility.data() as Map<String, dynamic>;

      if (facilityData['isActive'] != true) {
        showMessage('This room is currently unavailable.');
        return;
      }

      await FirebaseFirestore.instance.collection('requests').add({
        'reportedBy': user.uid,
        'facilityId':
            facilityData['facilityId'] ?? facility.id,
        'floor': facilityData['floor'],
        'issueType': issueType,
        'description': descriptionController.text.trim(),
        'status': 'pending',
        'assignedTo': null,
        'createdAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'completedAt': null,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cleaning request submitted successfully!'),
        ),
      );

      descriptionController.clear();

      setState(() {
        selectedFacilityId = null;
        issueType = 'cleaning';
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MyRequestsScreen(),
        ),
      );
    } catch (e) {
      showMessage('Failed to submit request. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create a request',
          style: TextStyle(fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Request a cleanup',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF292D3C),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tell us where cleaning is needed.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 25),

              const Text(
                'Select room',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('facilities')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text(
                      'Unable to load rooms.',
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  List<QueryDocumentSnapshot> facilities =
                      snapshot.data!.docs;

                  if (facilities.isEmpty) {
                    return const Text(
                      'No active rooms available.',
                    );
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFD5D5D5),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: facilities.any(
                        (facility) =>
                            facility.id == selectedFacilityId,
                      )
                          ? selectedFacilityId
                          : null,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('Choose a room'),
                      items: facilities.map((facility) {
                        Map<String, dynamic> data =
                            facility.data()
                                as Map<String, dynamic>;

                        String roomName =
                            data['roomName'] ?? facility.id;
                        String floor = '${data['floor'] ?? '?'}';

                        return DropdownMenuItem<String>(
                          value: facility.id,
                          child: Text(
                            '$roomName - Floor $floor',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedFacilityId = value;
                        });
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 22),

              const Text(
                'Issue type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFD5D5D5),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButton<String>(
                  value: issueType,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: 'cleaning',
                      child: Text('Cleaning'),
                    ),
                    DropdownMenuItem(
                      value: 'spill',
                      child: Text('Spill'),
                    ),
                    DropdownMenuItem(
                      value: 'trash',
                      child: Text('Trash'),
                    ),
                    DropdownMenuItem(
                      value: 'restroom',
                      child: Text('Restroom'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        issueType = value;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),

              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe what needs cleaning...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFFD5D5D5),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit request',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: -1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const MainDashboard(),
              ),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MyRequestsScreen(),
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