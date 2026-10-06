part of '../../chat_models.dart';

class ChatMediaUrl extends Equatable {
  const ChatMediaUrl({required this.url, required this.expiresAt});
  final Uri url;
  final DateTime expiresAt;

  @override
  List<Object?> get props => [expiresAt];

  @override
  String toString() => 'ChatMediaUrl(expiresAt: $expiresAt)';
}
