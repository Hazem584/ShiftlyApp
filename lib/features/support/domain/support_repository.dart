import 'dart:typed_data';

import 'support_models.dart';

abstract interface class SupportRepository {
  Future<SupportPage> list({required int page});
  Future<List<SupportContext>> contexts(String workspaceId);
  Future<SupportTicket> get(String id);
  Future<SupportTicket> create({
    required String workspaceId,
    required String clientId,
    required String title,
    required String description,
    SupportContext? related,
  });
  Future<void> reply({
    required String id,
    required String clientId,
    required String body,
  });
  Future<void> uploadImage({
    required String id,
    required Uint8List bytes,
    required String mime,
  });
  Future<Uint8List> image(String id);
}
