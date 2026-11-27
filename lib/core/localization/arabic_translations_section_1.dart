import 'package:shiftly/core/localization/access_translations.dart';
import 'package:shiftly/core/localization/arabic_schedule_exception_translations.dart';
import 'package:shiftly/core/localization/arabic_workday_translations.dart';
import 'package:shiftly/core/localization/collaboration_translations.dart';
import 'package:shiftly/core/localization/communication_translations.dart';
import 'package:shiftly/core/localization/manager_translations.dart';
import 'package:shiftly/features/device_sessions/device_sessions_translations.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_translations.dart';
import 'package:shiftly/features/support/presentation/support_translations.dart';
import 'package:shiftly/features/tasks/presentation/task_translations.dart';

const arabicTranslationSection1 = <String, String>{
  ...accessTranslations,
  ...communicationTranslations,
  ...managerTranslations,
  ...collaborationTranslations,
  ...supportTranslations,
  ...employeeTranslations,
  'Document': 'مستند',
  'React to message': 'تفاعل مع الرسالة',
  'React with {emoji}': 'تفاعل بـ {emoji}',
  'Remove reaction': 'إزالة التفاعل',
  'Message deleted': 'تم حذف الرسالة',
  'Save or share document': 'حفظ أو مشاركة المستند',
  'Could not download the document. Try again.':
      'تعذّر تنزيل المستند. جرّب تاني.',
  'Choose a PDF, Excel, CSV or text file up to 10 MB.':
      'اختار ملف PDF أو Excel أو CSV أو نص، بحد أقصى 10 ميجابايت.',

  'Extra attendance records the authorized shift and its actual working time.':
      'الحضور الإضافي بيسجّل الشيفت المصرّح به ووقت الشغل الفعلي.',
  'Changes apply to this date only. Recorded attendance cannot be changed.':
      'التغيير لليوم ده بس، ومينفعش تغيّر حضور اتسجل بالفعل.',
  'This day has started or its attendance is already saved. Choose an unused future day.':
      'اليوم ده بدأ أو حضوره اتسجّل. اختار يوم جاي لسه متسجّلش فيه حضور.',

  'Manage your tasks': 'رتّب مهامك',
  'Keep your daily tasks organized and track what is done.':
      'رتّب مهام يومك وتابع اللي خلص منها.',

  ...arabicWorkdayTranslations,
  'Your workday, in sync': 'يوم شغلك.. كله في مكانه',
  'View all tasks': 'تابع كل المهام',
  'View all announcements': 'شوف إعلانات الفريق',
  ...deviceSessionsTranslations,
  ...taskTranslations,
  ...arabicScheduleExceptionTranslations,
  'Error code: {code}': 'رمز الخطأ: {code}',
  'Workspace groups appear here once a manager creates one.':
      'جروبات الشغل هتظهر هنا لما المدير يعمل جروب.',
  'Active employees': 'الموظفين النشطين',
  'Non-cancelled shifts': 'الشيفتات اللي متلغتش',
  'Open attendance': 'حضور لسه مفتوح',
  'Missed': 'غياب',
  "Today's shifts": 'شيفتات النهارده',
  'Create a shift': 'اعمل شيفت',
  'No shifts are scheduled for this workspace day.':
      'مفيش شيفتات متحددة ليوم الشغل ده.',
  'No chat groups yet.': 'لسه مفيش جروبات شات.',
  'Refresh chat': 'حدّث الشات',
  'below': 'تحت',
  'in My Shifts': 'من صفحة شيفتاتي',
  'Your last request is saved. Confirm its outcome {location} before starting another shift.':
      'طلبك الأخير محفوظ. أكّد نتيجته {location} قبل ما تبدأ شيفت تاني.',
  'When you finish working, use Clock out {location}.':
      'لما تخلّص شغل، اضغط «سجّل خروجك» {location}.',
  'Refresh or review the saved attendance {location} before clocking in again.':
      'حدّث البيانات أو راجع الحضور المحفوظ {location} قبل تسجيل حضور جديد.',
  'Choose {name} {location} to start your attendance.':
      'اختار {name} {location} عشان تسجّل حضورك.',
  'Check your assigned schedule {location}. If a shift is missing, ask your manager to review your assignment.':
      'راجع جدولك {location}. لو فيه شيفت مش ظاهر، اطلب من مديرك يراجع تعيينك.',
  'Choose an available shift to clock in. Your active shift will show the clock-out action.': 'اختار شيفت متاح وسجّل حضورك. زر تسجيل الخروج هيظهر في الشيفت اللي شغال عليه.',
  'Earlier shifts': 'الشيفتات السابقة',
  'Recommended': 'بنرشّحه ليك',
};
