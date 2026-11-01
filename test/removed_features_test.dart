import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/localization/arabic_translations.dart';
import 'package:shiftly/features/notifications/domain/entities/notification_type.dart';
import 'package:shiftly/features/shell/presentation/screens/work_hub_screen.dart';

void main() {
  test('work navigation keeps only supported sections', () {
    expect(WorkHubScreen.tabs.map((t) => t.$1).toList(), [
      'tasks',
      'shifts',
      'announcements',
      'personal',
    ]);
  });
  test('cache size uses megabytes', () {
    expect(
      arabicTranslations['{value1} MB · active files are retained'],
      contains('ميجابايت'),
    );
  });
  test('retired exchange notifications are safely treated as unavailable', () {
    expect(
      NotificationType.parse('SHIFT_EXCHANGE_REQUESTED'),
      NotificationType.unknown,
    );
    expect(
      NotificationType.parse('SHIFT_EXCHANGE_UPDATED'),
      NotificationType.unknown,
    );
  });
}
