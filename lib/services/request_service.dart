import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/request_model.dart';
import 'facility_service.dart';

class RequestService {
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

    final facility = await FacilityService(firestore: _firestore)
        .getFacility(facilityId.trim());
    if (facility != null && facility.floor != floor) {
      throw StateError(
        'The selected facility does not match the chosen floor.',
      );
    }

    final doc = await _requests.add({
      'reportedBy': reportedBy.trim(),
      'facilityId': facilityId.trim(),
      'floor': floor,
      'issueType': issueType,
      'description': description.trim(),
      'status': 'pending',
      'assignedTo': null,
      'createdAt': FieldValue.serverTimestamp(),
      'acceptedAt': null,
      'completedAt': null,
    });
    return doc.id;
  }

  Stream<List<RequestModel>> watchAllRequests() =>
      _watch(_requests.snapshots());

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
