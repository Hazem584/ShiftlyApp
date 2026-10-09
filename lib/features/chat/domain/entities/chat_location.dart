import 'package:equatable/equatable.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models_parsers.dart';

class ChatLocation extends Equatable {
  const ChatLocation({
    required this.latitude,
    required this.longitude,
    this.label,
    this.address,
  });

  final double latitude;
  final double longitude;
  final String? label;
  final String? address;

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  factory ChatLocation.fromJson(Map<String, Object?> json) {
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    final value = ChatLocation(
      latitude: latitude is num ? latitude.toDouble() : double.nan,
      longitude: longitude is num ? longitude.toDouble() : double.nan,
      label: chatModelsOptionalText(json['label']),
      address: chatModelsOptionalText(json['address']),
    );
    if (!value.isValid) throw const FormatException('Invalid location');
    return value;
  }

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    if (label != null) 'label': label,
    if (address != null) 'address': address,
  };

  @override
  List<Object?> get props => [latitude, longitude, label, address];
}
