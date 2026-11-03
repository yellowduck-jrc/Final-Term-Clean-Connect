class FacilityModel {
  const FacilityModel({
    required this.id,
    required this.roomName,
    required this.floor,
    required this.roomType,
    required this.isActive,
  });

  final String id;
  final String roomName;
  final int floor;
  final String roomType;
  final bool isActive;

  factory FacilityModel.fromMap(Map<String, dynamic> data, {String? id}) {
    final floorValue = data['floor'];
    return FacilityModel(
      id: (data['facilityId'] as String?) ?? id ?? '',
      roomName: (data['roomName'] as String?) ?? id ?? 'Unnamed room',
      floor: floorValue is num ? floorValue.toInt() : 1,
      roomType: (data['roomType'] as String?) ?? 'room',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'facilityId': id,
    'roomName': roomName,
    'floor': floor,
    'roomType': roomType,
    'isActive': isActive,
  };
}