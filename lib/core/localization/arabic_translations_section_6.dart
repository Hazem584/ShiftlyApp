import 'package:shiftly/core/localization/arabic_error_translations.dart';
import 'package:shiftly/core/localization/arabic_interface_translations.dart';
import 'package:shiftly/core/localization/arabic_report_translations.dart';
import 'package:shiftly/core/localization/arabic_team_work_translations.dart';
import 'package:shiftly/core/localization/arabic_workflow_translations.dart';

const arabicTranslationSection6 = <String, String>{
  'This information changed or conflicts with an existing record. Refresh its status before trying again.':
      'تغيّرت البيانات أو تعارضت مع سجل موجود. حدّث الحالة قبل ما تجرّب تاني.',
  'The request timed out. Please try again.':
      'انتهت مهلة الطلب. اتأكد من حالته قبل ما تجرّب تاني.',
  'Use Clock out when you finish. Your workspace confirms the final worked duration.':
      'سجّل خروجك لما تخلّص شغل. النظام هيأكد مدة الشغل النهائية.',
  ...arabicInterfaceTranslations,
  ...arabicErrorTranslations,
  ...arabicWorkflowTranslations,
  ...arabicReportTranslations,
  ...arabicTeamWorkTranslations,
};
