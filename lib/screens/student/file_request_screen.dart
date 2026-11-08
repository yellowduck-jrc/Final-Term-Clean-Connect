import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/navigation_observer.dart';
import '../../app/app_routes.dart';
import '../../models/facility_model.dart';
import '../../services/request_service.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_bottom_nav.dart';
import '../shared/notifications_screen.dart';

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
  String priority = 'Medium';
  bool isSubmitting = false;
  bool isPickingPhoto = false;
  Uint8List? selectedPhotoBytes;

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
        imageBytes: selectedPhotoBytes,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cleaning request submitted successfully!'),
        ),
      );

      descriptionController.clear();

      setState(() {
        selectedPhotoBytes = null;
        selectedFacilityId = null;
        selectedRoomName = null;
        selectedFloor = null;
        issueType = 'cleaning';
      });

      Navigator.pushReplacementNamed(context, AppRoutes.myRequests);
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

  Future<void> pickPhoto() async {
    await _pickPhoto(ImageSource.gallery);
  }

  Future<void> takePhoto() => _pickPhoto(ImageSource.camera);

  Future<void> _pickPhoto(ImageSource source) async {
    setState(() => isPickingPhoto = true);
    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 45,
      );
      if (!mounted || photo == null) return;

      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      if (bytes.length > RequestService.maxPhotoBytes) {
        showMessage(
          'Photo is too large after compression. Choose a smaller photo.',
        );
        return;
      }
      setState(() {
        selectedPhotoBytes = bytes;
      });
    } catch (error) {
      if (mounted) showMessage('Unable to take a photo: $error');
    } finally {
      if (mounted) setState(() => isPickingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        leading: const NavigationBackButton(),
        automaticallyImplyLeading: false,
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Requests',
          style: TextStyle(
            fontSize: 17,
            decoration: TextDecoration.underline,
            decorationColor: Color(0xFF178EEA),
            decorationThickness: 2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
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
            padding: const EdgeInsets.fromLTRB(13, 18, 13, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    'Create a Request',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF299D50),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    'Submit a request to track and resolve\nyour concern.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      color: Color(0xFF242735),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: const Color(0xFFD0D0D0),
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: isPickingPhoto ? null : pickPhoto,
                    child: SizedBox(
                      height: 98,
                      width: double.infinity,
                      child: selectedPhotoBytes == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isPickingPhoto)
                                  const SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Color(0xFF828282),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 42,
                                    color: Color(0xFF828282),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  isPickingPhoto
                                      ? 'Selecting photo...'
                                      : 'Tap to upload a photo',
                                  style: const TextStyle(
                                    color: Color(0xFF737373),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Image.memory(
                              selectedPhotoBytes!,
                              width: double.infinity,
                              height: 98,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: isPickingPhoto ? null : takePhoto,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Open camera'),
                  ),
                ),
                const SizedBox(height: 16),
                _fieldLabel('Request Category'),
                _fieldBox(
                  icon: Icons.build_outlined,
                  child: DropdownButton<String>(
                    value: issueType,
                    isExpanded: true,
                    underline: const SizedBox(),
                    style: const TextStyle(
                      color: Color(0xFF242735),
                      fontSize: 14,
                    ),
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
                        setState(() => issueType = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _fieldLabel('Request Title'),
                _fieldBox(
                  icon: Icons.text_fields,
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter a short title',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _fieldLabel('Location'),
                _fieldBox(
                  icon: Icons.location_on_outlined,
                  fillColor: selectedFacilityId == null
                      ? Colors.white
                      : const Color(0xFFEAEAEA),
                  child: selectedFacilityId == null
                      ? TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.map),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            foregroundColor: const Color(0xFF242735),
                          ),
                          child: const Text('Enter the room location'),
                        )
                      : Text(
                          '${selectedRoomName ?? selectedFacilityId}'
                          '${selectedFloor == null ? '' : ' · Floor $selectedFloor'}',
                          style: const TextStyle(
                            color: Color(0xFF242735),
                            fontSize: 14,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                _fieldLabel('Description'),
                _fieldBox(
                  icon: Icons.description_outlined,
                  alignment: CrossAxisAlignment.start,
                  child: TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe your request in detail...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                const Text(
                  'Priority Level',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final level in ['Low', 'Medium', 'High'])
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: OutlinedButton(
                            onPressed: () => setState(() => priority = level),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 29),
                              padding: EdgeInsets.zero,
                              backgroundColor: priority == level
                                  ? const Color(0xFF399849)
                                  : Colors.white,
                              foregroundColor: priority == level
                                  ? Colors.white
                                  : const Color(0xFF252525),
                              side: const BorderSide(color: Color(0xFFAAAAAA)),
                              shape: const StadiumBorder(),
                            ),
                            child: Text(level),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : submitRequest,
                    icon: const Icon(Icons.send_outlined, size: 21),
                    label: isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit Request',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1458D3),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () => Navigator.maybePop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1458D3),
                      side: const BorderSide(color: Color(0xFF1458D3)),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 4),
      child: Text.rich(
        TextSpan(
          text: '$text ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
          children: const [
            TextSpan(
              text: '*',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldBox({
    required IconData icon,
    required Widget child,
    CrossAxisAlignment alignment = CrossAxisAlignment.center,
    Color fillColor = Colors.white,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(color: const Color(0xFFD1D1D1)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: alignment,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 5),
            child: Icon(icon, size: 23, color: const Color(0xFF152457)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
