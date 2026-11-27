import 'package:shiftly/core/error/api_exception.dart';

class ReportPageValidator {
  static const limit = 100;
  static const maxPages = 100;

  static void checkPage(
    int requested,
    int page,
    int pageLimit,
    int total,
    int pages,
    int count,
    int? previousTotal,
  ) {
    if (total > limit * maxPages) {
      throw const ApiException(
        message: 'This report is too large. Choose a shorter period.',
      );
    }
    if (page != requested ||
        pageLimit != limit ||
        total < 0 ||
        pages != (total / limit).ceil() ||
        count > limit ||
        (requested < pages && count != limit) ||
        (previousTotal != null && previousTotal != total)) {
      throw changed();
    }
  }

  static void checkCurrent(bool Function() isCurrent) {
    if (!isCurrent()) {
      throw const ApiException(message: 'Report request cancelled.');
    }
  }

  static ApiException changed() => const ApiException(
    message: 'Attendance changed while loading. Refresh the report.',
  );
}
