import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/features/profile/domain/repositories/profile_image_picker.dart';

import '../domain/support_models.dart';
import '../domain/support_repository.dart';

String supportContextError(Object e) => e is ApiException
    ? e.message
    : 'Could not load task and shift choices. You can still report a general problem.';

String supportSubmitError(Object e, String? savedId) => savedId != null
    ? 'Your report was saved, but its image was not uploaded. Retry or open the saved report.'
    : e is ApiException
    ? e.message
    : 'Could not submit the support report. Retry safely.';

Future<(ProfileImageSelection?, String?)?> pickSupportAttachment(
  ProfileImagePicker picker,
) async {
  try {
    final img = await picker.pickImage();
    if (img == null) return null;
    if (img.bytes.length > 2097152 || img.detectedMimeType == null) {
      return (null, 'Choose a JPEG, PNG or WebP image up to 2 MB.');
    }
    return (img, null);
  } catch (_) {
    return (null, 'Could not select an image.');
  }
}

Future<String> submitSupportTicket({
  required SupportRepository repository,
  required String workspaceId,
  required String clientId,
  required String title,
  required String description,
  required SupportContext? related,
  required ProfileImageSelection? image,
  required String? existingId,
  required void Function(String) onTicketCreated,
}) async {
  var id = existingId;
  if (id == null) {
    final ticket = await repository.create(
      workspaceId: workspaceId,
      clientId: clientId,
      title: title,
      description: description,
      related: related,
    );
    id = ticket.id;
    onTicketCreated(id);
  }
  if (image != null) {
    await repository.uploadImage(
      id: id,
      bytes: image.bytes,
      mime: image.detectedMimeType!,
    );
  }
  return id;
}
