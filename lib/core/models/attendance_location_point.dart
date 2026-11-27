import 'package:equatable/equatable.dart';

class AttendanceLocationPoint extends Equatable {
  const AttendanceLocationPoint({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.isMocked = false,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final bool isMocked;

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
    'isMocked': isMocked,
  };

  @override
  List<Object?> get props => [latitude, longitude, accuracyMeters, isMocked];
}
