import 'package:flutter/material.dart';

String resolvePlatformBlockedTitle({
  required bool arabic,
  required Map<String, dynamic>? status,
  required String? suspension,
}) {
  if (suspension != null) {
    return arabic ? 'الحساب معلّق' : 'Account suspended';
  }
  if (status?['title']?.toString().trim().isNotEmpty ?? false) {
    return status!['title'].toString();
  }
  return switch (status?['mode']) {
    'MAINTENANCE' => arabic ? 'التطبيق تحت الصيانة' : 'Under maintenance',
    'UPDATING' => arabic ? 'جارٍ تحديث التطبيق' : 'An update is in progress',
    'DISABLED' => arabic ? 'الخدمة متوقفة حاليًا' : 'Service unavailable',
    _ => arabic ? 'تعذّر الاتصال' : 'Unable to connect',
  };
}

String resolvePlatformBlockedMessage({
  required bool arabic,
  required Map<String, dynamic>? status,
  required String? suspension,
}) {
  if (suspension != null) return suspension;
  if (status?['message']?.toString().trim().isNotEmpty ?? false) {
    return status!['message'].toString();
  }
  return arabic ? 'حاول مجددًا بعد قليل.' : 'Please try again shortly.';
}

Widget buildPlatformAnnouncementBanner(
  BuildContext context,
  String announcement,
) {
  return Material(
    color: Theme.of(context).colorScheme.secondaryContainer,
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.campaign_outlined, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                announcement,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
