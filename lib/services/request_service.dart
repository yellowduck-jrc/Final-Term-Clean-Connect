import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/request_model.dart';
import 'facility_service.dart';

class RequestService {
  static const maxPhotoBytes = 650 * 1024;

  RequestService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('requests');

  Future<String> createRequest({
    required String reportedBy,
    required String facilityId,
    required int floor,
    required String issueType,
    required String description,
    Uint8List? imageBytes,
  }) async {
    if (reportedBy.trim().isEmpty ||
        facilityId.trim().isEmpty ||
        floor < 1 ||
        floor > 3 ||
        description.trim().isEmpty ||
        issueType.trim().isEmpty) {
      throw ArgumentError(
        'A reporter, facility, valid floor, issue type, and description are required.',
      );
    }
    if (imageBytes != null && imageBytes.length > maxPhotoBytes) {
      throw ArgumentError(
        'The photo is too large for Firestore. Choose a smaller photo.',
      );
    }

    final facility = await FacilityService(firestore: _firestore)
        .getFacility(facilityId.trim());
    if (facility != null && facility.floor != floor) {
      throw StateError(
        'The selected facility does not match the chosen floor.',
      );
    }

    final doc = _requests.doc();
    await doc.set({
      'reportedBy': reportedBy.trim(),
      'facilityId': facilityId.trim(),
      'floor': floor,
      'issueType': issueType,
      'description': description.trim(),
      'status': 'pending',
      'assignedTo': null,
      'isAdminAssigned': false,
      'createdAt': FieldValue.serverTimestamp(),
      'acceptedAt': null,
      'completedAt': null,
      'imageUrl': null,
      'photoBase64': imageBytes == null ? null : base64Encode(imageBytes),
    });
    return doc.id;
  }

  Stream<List<RequestModel>> watchAllRequests() =>
      _watch(_requests.snapshots());

  Stream<RequestModel?> watchRequest(String requestId) {
    if (requestId.trim().isEmpty) {
      throw ArgumentError.value(requestId, 'requestId', 'Cannot be empty.');
    }
    return _requests
        .doc(requestId)
        .snapshots()
        .map(
          (snapshot) => snapshot.exists
              ? RequestModel.fromMap(snapshot.data()!, id: snapshot.id)
              : null,
        );
  }

  Stream<List<RequestModel>> watchRequestsByReporter(String uid) =>
      _watch(_requests.where('reportedBy', isEqualTo: uid).snapshots());

  Stream<List<RequestModel>> watchRequestsForUser(String uid) => _watch(
    _requests
        .where(
          Filter.or(
            Filter('reportedBy', isEqualTo: uid),
            Filter('assignedTo', isEqualTo: uid),
          ),
        )
        .snapshots(),
  );

  Stream<List<RequestModel>> watchRequestsByFloor(int floor) =>
      _watch(_requests.where('floor', isEqualTo: floor).snapshots());

  Stream<List<RequestModel>> watchRequestsByFacility(String facilityId) =>
      _watch(_requests.where('facilityId', isEqualTo: facilityId).snapshots());

  Stream<List<RequestModel>> watchStaffDashboardRequests(String staffUid) =>
      _watch(
        _requests
            .where(
              Filter.or(
                Filter('status', isEqualTo: 'pending'),
                Filter('assignedTo', isEqualTo: staffUid),
              ),
            )
            .snapshots(),
      );

  Stream<List<RequestModel>> watchAssignedRequests(String uid) =>
      _watch(_requests.where('assignedTo', isEqualTo: uid).snapshots());

  Stream<List<RequestModel>> _watch(
    Stream<QuerySnapshot<Map<String, dynamic>>> source,
  ) {
    return source.map((snapshot) {
      final requests =
          snapshot.docs
              .map((doc) => RequestModel.fromMap(doc.data(), id: doc.id))
              .toList()
            ..sort((a, b) {
              final first = a.createdAt;
              final second = b.createdAt;
              if (first == null) return second == null ? 0 : 1;
              if (second == null) return -1;
              return second.compareTo(first);
            });
      return requests;
    });
  }

  Future<RequestModel?> getRequest(String id) async {
    final doc = await _requests.doc(id).get();
    if (!doc.exists) return null;
    return RequestModel.fromMap(doc.data()!, id: doc.id);
  }

  Future<void> updateStudentRequest({
    required String requestId,
    required String reportedBy,
    required String issueType,
    required String description,
  }) async {
    final normalizedDescription = description.trim();
    if (issueType.trim().isEmpty || normalizedDescription.isEmpty) {
      throw ArgumentError('A category and description are required.');
    }

    await _firestore.runTransaction((transaction) async {
      final reference = _requests.doc(requestId);
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) throw StateError('This request no longer exists.');

      final request = RequestModel.fromMap(snapshot.data()!, id: snapshot.id);
      if (request.reportedBy != reportedBy) {
        throw StateError('You can only edit your own requests.');
      }
      if (request.status != 'pending') {
        throw StateError('Only pending requests can be edited.');
      }

      transaction.update(reference, {
        'issueType': issueType.trim(),
        'description': normalizedDescription,
      });
    });
  }

  Future<void> deleteStudentRequest({
    required String requestId,
    required String reportedBy,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final reference = _requests.doc(requestId);
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) throw StateError('This request no longer exists.');

      final request = RequestModel.fromMap(snapshot.data()!, id: snapshot.id);
      if (request.reportedBy != reportedBy) {
        throw StateError('You can only delete your own requests.');
      }

      transaction.delete(reference);
    });
  }

  Future<void> acceptRequest(String requestId, String staffUid) async {
    await _firestore.runTransaction((transaction) async {
      final reference = _requests.doc(requestId);
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) throw StateError('This request no longer exists.');
      final request = RequestModel.fromMap(snapshot.data()!, id: snapshot.id);
      if (request.status != 'pending') {
        throw StateError('This request has already been accepted or updated.');
      }
      if (request.assignedTo != null &&
          request.assignedTo!.isNotEmpty &&
          request.assignedTo != staffUid) {
        throw StateError('This request is assigned to another staff member.');
      }
      transaction.update(reference, {
        'status': 'in_progress',
        'assignedTo': staffUid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> completeRequest(String requestId, String staffUid) async {
    await _firestore.runTransaction((transaction) async {
      final reference = _requests.doc(requestId);
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) throw StateError('This request no longer exists.');
      final request = RequestModel.fromMap(snapshot.data()!, id: snapshot.id);
      if (request.assignedTo != staffUid || request.status != 'in_progress') {
        throw StateError('Only the assigned staff member can complete it.');
      }
      transaction.update(reference, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateAssignmentAndStatus({
    required String requestId,
    required String status,
    required String? assignedTo,
  }) {
    if (!{
      'pending',
      'in_progress',
      'completed',
      'cancelled',
    }.contains(status)) {
      throw ArgumentError.value(
        status,
        'status',
        'Unsupported request status.',
      );
    }

    final updates = <String, Object?>{
      'status': status,
      'assignedTo': assignedTo,
      'isAdminAssigned': assignedTo != null && assignedTo.isNotEmpty,
    };
    if (status == 'in_progress') {
      updates['acceptedAt'] = FieldValue.serverTimestamp();
    }
    if (status == 'completed') {
      updates['completedAt'] = FieldValue.serverTimestamp();
    }
    return _requests.doc(requestId).update(updates);
  }
}
