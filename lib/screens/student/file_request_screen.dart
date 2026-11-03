import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../app/navigation_observer.dart';
import '../../app/app_routes.dart';
import '../dashboard/main_dashboard.dart';
import 'my_requests_screen.dart';
import '../../models/facility_model.dart';
import '../../services/request_service.dart';
import '../../services/user_service.dart';

class FileRequestScreen extends StatefulWidget {
  const FileRequestScreen({
    super.key,
    this.initialFacility,
    this.initialFacilityId,
    this.roomName,
    this.floor,
  });

  final FacilityModel? initialFacility;
  final String? initialFacilityId;
  final String? roomName;
  final int? floor;

  @override
  State<FileRequestScreen> createState() => _FileRequestScreenState();
}

class _FileRequestScreenState extends State<FileRequestScreen> {
  final TextEditingController descriptionController = TextEditingController();

  String? selectedFacilityId;
  String? selectedRoomName;
  int? selectedFloor;
  String issueType = 'cleaning';
  bool isSubmitting = false;

  final Color navy = const Color(0xFF242735);
  final Color green = const Color(0xFF20A879);

  @override
  void initState() {
    super.initState();
    selectedFacilityId = widget.initialFacility?.id ?? widget.initialFacilityId;
    selectedRoomName =
        widget.initialFacility?.roomName ??
        widget.roomName ??
        selectedFacilityId;
    selectedFloor = widget.initialFacility?.floor ?? widget.floor;
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> submitRequest() async {
    if (isSubmitting) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('Please log in first.');
      return;
    }

    if (selectedFacilityId == null || selectedFloor == null) {
      showMessage('Choose a room from the map before submitting.');
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
      final profile = await UserService().getUser(user.uid);
      if (profile?.role != 'student') {
        showMessage('Only student accounts can submit cleaning requests.');
        return;
      }

      await RequestService().createRequest(
        reportedBy: user.uid,
        facilityId: selectedFacilityId!,
        floor: selectedFloor!,
        issueType: issueType,
        description: descriptionController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cleaning request submitted successfully!'),
        ),
      );

      descriptionController.clear();

      setState(() {
        selectedFacilityId = null;
        selectedRoomName = null;
        selectedFloor = null;
        issueType = 'cleaning';
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyRequestsScreen()),
      );
    } catch (error) {
      showMessage(
        'Failed to submit request: '
        '${error.toString().replaceFirst('Bad state: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Create a request', style: TextStyle(fontSize: 17)),
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
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 25),

              const Text(
                'Report location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F7),
                  border: Border.all(color: const Color(0xFFD5D5D5)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedFacilityId == null
                            ? 'No room selected'
                            : '${selectedRoomName ?? selectedFacilityId}'
                                  '${selectedFloor == null ? '' : ' · Floor $selectedFloor'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (selectedFacilityId == null)
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.map),
                        child: const Text('Choose on map'),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Issue type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD5D5D5)),
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
                    DropdownMenuItem(value: 'spill', child: Text('Spill')),
                    DropdownMenuItem(value: 'trash', child: Text('Trash')),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                    borderSide: const BorderSide(color: Color(0xFFD5D5D5)),
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
                          style: TextStyle(fontWeight: FontWeight.bold),
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
              MaterialPageRoute(builder: (context) => const MainDashboard()),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MyRequestsScreen()),
            );
          } else if (index == 2) {
            Navigator.pushNamed(context, AppRoutes.map);
          } else if (index == 3) {
            Navigator.pushNamed(context, AppRoutes.profile);
          }
        },
      ),
    );
  }
}
