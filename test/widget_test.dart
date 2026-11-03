import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clean_connect/models/app_user_model.dart';
import 'package:clean_connect/models/facility_model.dart';
import 'package:clean_connect/models/request_model.dart';
import 'package:clean_connect/screens/maps/first_floor.dart';
import 'package:clean_connect/screens/student/file_request_screen.dart';
import 'package:clean_connect/services/auth_service.dart';
import 'package:clean_connect/widgets/request_card.dart';
import 'package:clean_connect/widgets/room_container.dart';
import 'package:clean_connect/widgets/status_badge.dart';

void main() {
  test('email validation accepts non-Gmail email addresses', () {
    expect(AuthService.validateEmail('person@example.edu'), isNull);
    expect(AuthService.validateEmail('person@gmail.com'), isNull);
    expect(AuthService.validateEmail('person@'), isNotNull);
    expect(AuthService.validateEmail('not an email'), isNotNull);
  });

  test('registration reports when Firebase already has the email', () {
    final message = AuthService.authErrorMessage(
      FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'Sensitive Firebase error details',
      ),
      creatingAccount: true,
    );

    expect(message, contains('already registered'));
    expect(message, isNot(contains('Sensitive Firebase error details')));
  });

  test('facility fields round-trip through Firestore map format', () {
    const facility = FacilityModel(
      id: 'K-101',
      roomName: 'Classroom 101',
      floor: 1,
      roomType: 'classroom',
      isActive: true,
    );

    final restored = FacilityModel.fromMap(facility.toMap(), id: facility.id);

    expect(restored.id, facility.id);
    expect(restored.roomName, facility.roomName);
    expect(restored.floor, facility.floor);
    expect(restored.roomType, facility.roomType);
    expect(restored.isActive, isTrue);
  });

  test('staff profiles read legacy name and active status fields', () {
    final user = AppUserModel.fromMap({
      'email': 'veiljosemarinas@gmail.com',
      'name': 'Veil Jose Marinas',
      'role': 'staff',
      'status': 'active',
    }, id: 'staff-1');

    expect(user.uid, 'staff-1');
    expect(user.fullName, 'Veil Jose Marinas');
    expect(user.role, 'staff');
    expect(user.isActive, isTrue);
  });

  test('request parsing preserves Firestore document IDs and status', () {
    final request = RequestModel.fromMap({
      'facilityId': 'K-101',
      'floor': 1,
      'issueType': 'spill',
      'description': 'Water on the floor',
      'reportedBy': 'student-1',
      'status': 'in_progress',
      'assignedTo': 'staff-1',
    }, id: 'request-1');

    expect(request.id, 'request-1');
    expect(request.facilityId, 'K-101');
    expect(request.status, 'in_progress');
    expect(request.assignedTo, 'staff-1');
  });

  testWidgets('request card shows location and status', (tester) async {
    const request = RequestModel(
      id: 'request-1',
      facilityId: 'K-101',
      floor: 1,
      issueType: 'spill',
      description: 'Water on the floor',
      reportedBy: 'student-1',
      status: 'pending',
      createdAt: null,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: RequestCard(request: request)),
      ),
    );

    expect(find.text('Water on the floor'), findsOneWidget);
    expect(find.text('K-101  |  Floor 1  |  spill'), findsOneWidget);
    expect(find.byType(StatusBadge), findsOneWidget);
  });

  testWidgets('report form keeps the map-selected room fixed', (tester) async {
    const facility = FacilityModel(
      id: 'floor3_k301',
      roomName: 'K-301',
      floor: 3,
      roomType: 'classroom',
      isActive: true,
    );

    await tester.pumpWidget(
      const MaterialApp(home: FileRequestScreen(initialFacility: facility)),
    );

    expect(find.text('K-301 · Floor 3'), findsOneWidget);
    expect(find.text('Select room'), findsNothing);
    expect(find.text('Choose a room'), findsNothing);
    expect(find.byType(DropdownButton<String>), findsOneWidget);
  });

  testWidgets('room details panel shows selected room and report action', (
    tester,
  ) async {
    var reportTapped = false;
    const facility = FacilityModel(
      id: 'floor3_k301',
      roomName: 'K-301',
      floor: 3,
      roomType: 'classroom',
      isActive: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoomDetailsPanel(
            facility: facility,
            pendingRequests: 2,
            inProgressRequests: 1,
            onReport: () => reportTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('K-301'), findsOneWidget);
    expect(
      find.text('Floor 3 · classroom\n2 open requests · 1 in progress'),
      findsOneWidget,
    );
    await tester.tap(find.text('Report an issue'));
    expect(reportTapped, isTrue);
  });

  testWidgets('selected room uses blue fill and green border', (tester) async {
    const facility = FacilityModel(
      id: 'floor3_k301',
      roomName: 'K-301',
      floor: 3,
      roomType: 'classroom',
      isActive: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RoomContainer(
            facility: facility,
            pendingRequests: 1,
            selected: true,
          ),
        ),
      ),
    );

    final roomMaterial = tester.widget<Material>(
      find.descendant(
        of: find.byType(RoomContainer),
        matching: find.byType(Material),
      ),
    );
    final roomContainer = tester.widget<Container>(
      find.descendant(
        of: find.byType(RoomContainer),
        matching: find.byWidgetPredicate(
          (widget) => widget is Container && widget.decoration is BoxDecoration,
        ),
      ),
    );
    final decoration = roomContainer.decoration! as BoxDecoration;

    expect(roomMaterial.color, Colors.blue[200]);
    expect(decoration.border!.top.color, Colors.green[300]);
  });

  testWidgets('first floor map rooms do not overflow vertically', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final facilities = [
      for (final room in [
        'K-101',
        'K-102',
        'K-103',
        'K-104',
        'K-109',
        'K-108',
        'PRIN. OFFICE',
        'K-107',
        'Toilets',
        'K-105',
        'K-106',
      ])
        FacilityModel(
          id: room,
          roomName: room,
          floor: 1,
          roomType: 'room',
          isActive: true,
        ),
    ];
    final requests = [
      for (final room in ['K-105', 'K-107'])
        RequestModel(
          id: 'request-$room',
          facilityId: room,
          floor: 1,
          issueType: 'cleaning',
          description: 'Needs cleaning',
          reportedBy: 'student-1',
          status: 'in_progress',
          createdAt: null,
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              FirstFloorPlan(facilities: facilities, requests: requests),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('first floor rooms can be reported when not configured', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [FirstFloorPlan(facilities: [], requests: [])],
          ),
        ),
      ),
    );

    await tester.tap(find.text('K-101'));
    await tester.pump();

    expect(find.text('K-101 · Floor 1 · 0 open'), findsOneWidget);
    expect(find.text('Inactive'), findsNothing);
    final reportButton = find.widgetWithText(TextButton, 'Report');
    expect(tester.widget<TextButton>(reportButton).onPressed, isNotNull);
    await tester.ensureVisible(reportButton);
    await tester.tap(reportButton);
    await tester.pumpAndSettle();

    expect(find.text('Create a request'), findsOneWidget);
    expect(find.text('K-101 · Floor 1'), findsOneWidget);
  });
}
