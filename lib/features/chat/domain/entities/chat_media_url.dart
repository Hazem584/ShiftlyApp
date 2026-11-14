import 'package:equatable/equatable.dart';

class ChatMediaUrl extends Equatable {
  const ChatMediaUrl({
    required this.url,
    required this.expiresAt,
    this.allowImageTransformation = false,
  });
  final Uri url;
  // A CDN may optimize an image while preserving its attachment identity.
  final bool allowImageTransformation;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [expiresAt, allowImageTransformation];

  @override
  String toString() => 'ChatMediaUrl(expiresAt: $expiresAt)';
}
