import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  const RequestModel({
    required this.id,
    required this.facilityId,
    required this.floor,
    required this.issueType,
    required this.description,
    required this.reportedBy,
    required this.status,
    required this.createdAt,
    this.assignedTo,
    this.acceptedAt,
    this.completedAt,
  });

  final String id;
  final String facilityId;
  final int? floor;
  final String issueType;
  final String description;
  final String reportedBy;
  final String status;
  final String? assignedTo;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  factory RequestModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return RequestModel(
      id: (data['requestId'] as String?) ?? id ?? '',
      facilityId: (data['facilityId'] as String?) ?? '',
      floor: data['floor'] is num ? (data['floor'] as num).toInt() : null,
      issueType: (data['issueType'] as String?) ?? 'cleaning',
      description: (data['description'] as String?) ?? '',
      reportedBy: (data['reportedBy'] as String?) ?? '',
      status: ((data['status'] as String?) ?? 'pending').toLowerCase(),
      assignedTo: data['assignedTo'] as String?,
      createdAt: _dateTime(data['createdAt']),
      acceptedAt: _dateTime(data['acceptedAt']),
      completedAt: _dateTime(data['completedAt']),
    );
  }

  static DateTime? _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}