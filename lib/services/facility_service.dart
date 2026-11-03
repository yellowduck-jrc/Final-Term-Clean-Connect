import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/facility_model.dart';

class FacilityService {
  FacilityService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _facilities =>
      _firestore.collection('facilities');

  Stream<List<FacilityModel>> watchFacilities({int? floor}) {
    return _facilities.snapshots().map((snapshot) {
      final facilities = snapshot.docs
          .map((doc) => FacilityModel.fromMap(doc.data(), id: doc.id))
          .where((facility) => floor == null || facility.floor == floor)
          .toList()
        ..sort((a, b) {
          final floorOrder = a.floor.compareTo(b.floor);
          return floorOrder != 0
              ? floorOrder
              : a.roomName.toLowerCase().compareTo(
                  b.roomName.toLowerCase(),
                );
        });
      return facilities;
    });
  }

  Future<FacilityModel?> getFacility(String id) async {
    final doc = await _facilities.doc(id).get();
    if (doc.exists) {
      return FacilityModel.fromMap(doc.data()!, id: doc.id);
    }

    final byFacilityId = await _facilities
        .where('facilityId', isEqualTo: id)
        .limit(1)
        .get();
    if (byFacilityId.docs.isNotEmpty) {
      final match = byFacilityId.docs.first;
      return FacilityModel.fromMap(match.data(), id: match.id);
    }

    final byRoomName = await _facilities
        .where('roomName', isEqualTo: id)
        .limit(1)
        .get();
    if (byRoomName.docs.isNotEmpty) {
      final match = byRoomName.docs.first;
      return FacilityModel.fromMap(match.data(), id: match.id);
    }
    return null;
  }

  Future<void> saveFacility(FacilityModel facility) {
    if (facility.id.trim().isEmpty || facility.roomName.trim().isEmpty) {
      throw ArgumentError('A facility ID and room name are required.');
    }
    if (facility.floor < 1 || facility.floor > 3) {
      throw ArgumentError.value(facility.floor, 'floor', 'Must be 1, 2, or 3.');
    }
    return _facilities.doc(facility.id).set(facility.toMap());
  }

  Future<void> deleteFacility(String id) => _facilities.doc(id).delete();
}