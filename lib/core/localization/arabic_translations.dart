import 'package:shiftly/core/localization/arabic_error_translations.dart';
import 'package:shiftly/core/localization/arabic_exchange_translations.dart';
import 'package:shiftly/core/localization/arabic_interface_translations.dart';
import 'package:shiftly/core/localization/arabic_points_translations.dart';
import 'package:shiftly/core/localization/arabic_report_translations.dart';
import 'package:shiftly/core/localization/arabic_schedule_exception_translations.dart';
import 'package:shiftly/core/localization/arabic_team_work_translations.dart';
import 'package:shiftly/core/localization/arabic_workday_translations.dart';
import 'package:shiftly/core/localization/arabic_workflow_translations.dart';
import 'package:shiftly/features/device_sessions/device_sessions_translations.dart';
import 'package:shiftly/features/operations/operations_translations.dart';
import 'package:shiftly/features/tasks/presentation/task_translations.dart';

// Egyptian Arabic: friendly everyday copy, with precise review and hours rules.
// Keep source keys and placeholders stable; employee-written content stays as is.
const arabicTranslations = <String, String>{
  ...arabicWorkdayTranslations,
  'Your workday, in sync': 'يوم شغلك.. كله في مكانه',
  'View all tasks': 'تابع كل المهام',
  'View all announcements': 'شوف إعلانات الفريق',
  ...deviceSessionsTranslations,
  ...operationsTranslations,
  ...taskTranslations,
  ...arabicExchangeTranslations,
  ...arabicScheduleExceptionTranslations,
  'Error code: {code}': 'رمز الخطأ: {code}',
  'This reversal would subtract points that are no longer available. Reverse the related deduction adjustment first, then reverse the original award.': 'الإلغاء ده هيخصم نقاط مبقتش موجودة. ارجع في تعديل الخصم المرتبط الأول، وبعدها الغي المنحة الأصلية.',
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
  'Assigned BASELINE': 'الشيفت الأساسي المعيّن',
  'Authorized EXTRA': 'شيفت إضافي مصرّح بيه',
  'Authorized EXTRA ? no automatic BLUE award':
      'إضافي مصرّح بيه · مفيش نقاط BLUE تلقائي',
  'Historical attendance ? assignment evidence not recorded':
      'حضور سابق · بيانات التعيين مش متسجّلة',
  'Unknown occurrence; read-only': 'شيفت مش معروف؛ للعرض بس',
  'Already used; cannot reopen': 'اتسجّل بالفعل؛ مينفعش تفتحه تاني',
  'Outside check-in window / read-only': 'خارج وقت تسجيل الحضور؛ للعرض بس',

  'Clocked in: {time}': 'وقت الحضور: {time}',
  'Schedule: {start} – {end}': 'موعد الشيفت: {start} – {end}',
  'Operational date: {date}': 'تاريخ يوم الشغل: {date}',
  'Unavailable': 'مش متاح',
  'Fixed shift': 'شيفت ثابت',
  'Elapsed (display only): {duration}': 'الوقت اللي عدى (للعرض بس): {duration}',
  'Get Started': 'يلا نبدأ',
  'Saving…': 'بنحفظ…',
  'Retry preference check': 'راجع الإعدادات تاني',
  'Preparing your dashboard…': 'بنجهّز صفحتك الرئيسية…',
  'Active attendance': 'حضور نشط',
  'Shifts': 'الشيفتات',
  'Requests': 'الطلبات',
  'Invite someone': 'دعوة موظف',
  'Plan the day': 'رتّب اليوم',
  'Review leave': 'مراجعة الإجازات',
  'Employee points, policies, disputes and warnings':
      'نقاط الموظفين والسياسات والاعتراضات والتنبيهات',
  'Contact information': 'بيانات التواصل',
  'Email address': 'الإيميل',
  'Workplace': 'مكان الشغل',
  'Leave Requests': 'طلبات الإجازة',
  'Completed': 'مكتمل',
  'No shift scheduled.': 'مفيش شيفت مجدول.',
  'Create your Shiftly account': 'اعمل حسابك على Shiftly',

  'Use at least 8 characters': 'استخدم ٨ أحرف على الأقل',
  'Passwords do not match': 'الباسورد وتأكيده مش زي بعض',
  'Show password': 'بيّن الباسورد',
  'Hide password': 'خبّي الباسورد',
  'Show password confirmation': 'بيّن تأكيد الباسورد',
  'Hide password confirmation': 'خبّي تأكيد الباسورد',
  'Already have an account? Sign in': 'عندك حساب؟ ادخل من هنا',
  'Good morning, Manager!': 'صباح الفل يا مدير!',
  "Here's what's happening with your team today.":
      'تعالى نشوف أخبار فريقك النهارده.',
  'Your shifts, clearly organized': 'شيفتاتك مترتّبة قدامك',
  'Know what’s next, and keep your working day in view.':
      'اعرف شيفتك الجاي إمتى، وخليك متابع يوم شغلك.',
  'Assigned fixed shifts': 'شيفتاتك الثابتة المعيّنة',
  'Check in and check out': 'تسجيل الحضور والخروج',
  'Manager-authorized extra shifts': 'شيفتات إضافية بتصريح من المدير',
  'See your progress': 'تابع تقدّمك',
  'Follow your attendance and celebrate the progress you make.':
      'تابع حضورك وشوف كل خطوة بتتقدمها.',
  'Attendance points': 'نقاط الحضور',
  'Performance history': 'سجل الأداء',
  'Achievements along the way': 'إنجازاتك مع كل خطوة',
  'Stay connected': 'خليك على تواصل',
  'Keep your workspace conversations and updates together.':
      'شات الشغل وآخر الأخبار، كلهم في مكان واحد.',
  'Workspace group chat': 'شات جروبات العمل',
  'Images and voice messages': 'صور ورسايل صوتية',
  'Notifications and updates': 'تنبيهات وآخر الأخبار',
  'Your workday, in one place · Times in {timezone}':
      'يوم شغلك في مكان واحد · التوقيت: {timezone}',
  'Your last request is saved. Confirm its outcome in My Shifts before starting another shift.':
      'طلبك الأخير محفوظ. أكّد نتيجته من صفحة شيفتاتي قبل ما تبدأ شيفت تاني.',
  'When you finish working, use Clock out in My Shifts.':
      'لما تخلّص شغل، سجّل خروجك من صفحة شيفتاتي.',
  'Refresh or review the saved attendance in My Shifts before clocking in again.': 'حدّث البيانات أو راجع الحضور المحفوظ من صفحة شيفتاتي قبل تسجيل حضور جديد.',
  'Choose {name} in My Shifts to start your attendance.':
      'اختار {name} من صفحة شيفتاتي عشان تسجّل حضورك.',
  'Check your assigned schedule in My Shifts. If a shift is missing, ask your manager to review your assignment.': 'راجع جدولك من صفحة شيفتاتي. لو فيه شيفت مش ظاهر، اطلب من مديرك يراجع تعيينك.',
  'Request cancelled.': 'اتلغى الطلب.',
  'You appear to be offline. Check your connection and retry.':
      'شكلك مش متصل بالنت. راجع الاتصال وجرّب تاني.',
  'The email or password is incorrect.': 'الإيميل أو الباسورد مش صح.',
  'Complete your profile to continue.':
      'كمّل بروفايلك عشان تقدر تكمّل استخدام التطبيق.',
  'Too many requests. Please wait and try again.':
      'فيه طلبات كتير. استنى شوية وجرّب تاني.',
  'You have already clocked in for this shift.':
      'إنت سجّلت حضورك للشيفت ده بالفعل.',
  'You have already clocked out for this shift.':
      'إنت سجّلت خروجك من الشيفت ده بالفعل.',
  'Clock-in is not available yet for this shift.':
      'وقت تسجيل الحضور للشيفت ده لسه مبدأش.',
  'This shift has already ended.': 'الشيفت ده خلص بالفعل.',
  'This shift is already completed.': 'الشيفت ده مكتمل بالفعل.',
  'This employee already has an overlapping shift.':
      'الموظف ده عليه شيفت تاني في نفس الوقت.',
  'We could not save your profile. Refresh your profile to check its latest details before saving again.':
      'معرفناش نحفظ بروفايلك. حدّث البيانات واتأكد منها قبل الحفظ تاني.',
  'We could not confirm your latest points information. Refresh your balance and history before trying again.': 'معرفناش نأكد بيانات نقاطك الحالية. حدّث الرصيد والسجل قبل ما تجرّب تاني.',
  'Language': 'اللغة',
  'Device language': 'لغة الجهاز',
  'Choose Arabic, English or your device language':
      'اختار المصري أو الإنجليزي أو لغة جهازك',
  'Could not save language. Please try again.':
      'معرفناش نحفظ اللغة. جرّب تاني.',
  'Dashboard': 'الرئيسية',
  'Overview': 'نظرة عامة',
  'Employees': 'الموظفين',

  'Chat': 'الشات',
  'Profile': 'البروفايل',
  'Performance': 'الأداء',
  'My Shifts': 'شيفتاتي',
  'Employee workspace': 'مكان شغل الموظف',
  'Manager Profile': 'بروفايل المدير',

  'Switch workspace': 'تغيير مكان الشغل',
  'Sign out': 'خروج من الحساب',

  'Sign in': 'دخول',
  'Unable to sign in.': 'معرفناش نسجّل الدخول.',
  'Email': 'الإيميل',
  'Password': 'الباسورد',
  'Confirm password': 'تأكيد الباسورد',
  'Enter a valid email address': 'اكتب إيميل صحيح',
  'Password is required': 'اكتب الباسورد',

  'Create account': 'اعمل حساب',
  'Create your account': 'اعمل حسابك',
  'Full name': 'اسمك بالكامل',
  'Phone': 'رقم الموبايل',
  'Phone number': 'رقم الموبايل',
  'Cancel': 'إلغاء',
  'Create': 'اعمل',
  'Save': 'احفظ',
  'Save changes': 'احفظ التغييرات',
  'Edit': 'عدّل',
  'Delete': 'امسح',
  'Close': 'اقفل',
  'Retry': 'جرّب تاني',
  'Try again': 'جرّب تاني',
  'Refresh': 'حدّث',
  'Search': 'دوّر',
  'Next': 'اللي بعده',
  'Back': 'رجوع',
  'Continue': 'كمّل',
  'Skip': 'عدّي',
  'Get started': 'يلا نبدأ',
  'Add Employee': 'ضيف موظف',
  'Add employee': 'ضيف موظف',
  'Create Shift': 'اعمل شيفت',
  'Create shift': 'اعمل شيفت',
  'Review Requests': 'راجع الطلبات',
  'Review requests': 'راجع الطلبات',
  'Employee details': 'تفاصيل الموظف',
  'Search employees': 'دوّر على موظف',
  'Active': 'نشط',
  'Inactive': 'مش نشط',
  'All': 'الكل',

  'Name': 'الاسم',
  'Description (optional)': 'الوصف (اختياري)',
  'Members': 'الأعضاء',
  'New group': 'جروب جديد',
  'Create chat group': 'اعمل جروب شات',
  'Message': 'رسالة',
  'Save image': 'احفظ الصورة',
  'Notifications': 'التنبيهات',
  'Mark all as read': 'علّم الكل مقروء',
  'No notifications yet': 'لسه مفيش تنبيهات',
  'Clear': 'امسح',
  'Chat media cache': 'ملفات الشات المحفوظة مؤقتًا',

  'Edit profile': 'عدّل البروفايل',
  'Personal information': 'البيانات الشخصية',
  'Work information': 'بيانات الشغل',
  'Workspace': 'مكان الشغل',
  'Role': 'الدور',
  'Status': 'الحالة',
  'Manager': 'مدير',
  'Employee': 'موظف',
  'Department': 'القسم',

  'Preparing your dashboard': 'بنجهّز صفحتك الرئيسية',

  'Total employees': 'إجمالي الموظفين',
  'Scheduled today': 'عليهم شيفت النهارده',
  'Clocked in now': 'حاضرين دلوقتي',
  'Completed today': 'خلّصوا شغل النهارده',
  'Late today': 'اتأخروا النهارده',
  'Missed today': 'غايبين النهارده',
  'On approved leave': 'في إجازة معتمدة',
  'Today at a glance': 'ملخّص النهارده',
  'Ready for your workday?': 'جاهز للشغل يا صاحبي؟',
  'Your shifts, attendance and time off are a tap away.':
      'شيفتاتك وحضورك وإجازاتك، كلهم هنا قدامك.',
  'Hello, {name}': 'أهلًا يا {name}',
  'Request leave': 'عايز إجازة؟',
  'Pending leave': 'إجازات مستنية المراجعة',

  'Fixed shifts': 'الشيفتات الثابتة',
  'Earlier shifts & clock-out': 'الشيفتات السابقة وتسجيل الخروج',
  'Open My Shifts': 'افتح شيفتاتي',
  'Clock in': 'سجّل حضورك',
  'Clock out': 'سجّل خروجك',
  'Clocked in': 'حاضر',
  'Clocked out': 'خرج',
  'Recorded': 'مسجّل',
  'On time': 'في المعاد',
  'Early': 'بدري',

  'Your clock-in needs confirmation': 'تسجيل حضورك محتاج تأكيد',
  'Your last request is saved. Confirm its outcome below before starting another shift.':
      'طلبك الأخير محفوظ. أكّد نتيجته تحت قبل ما تبدأ شيفت تاني.',
  'Confirming your clock-out': 'بنتأكد من خروجك',
  'Confirming your clock-in': 'بنتأكد من حضورك',
  'Waiting for your workspace to confirm the attendance change.':
      'مستنيين تأكيد تغيير حالة الحضور من النظام.',
  'You are clocked in': 'حضورك اتسجّل يا صاحبي',
  'An earlier attendance is still open': 'عندك حضور قديم لسه مفتوح',
  'When you finish working, use Clock out below.':
      'لما تخلّص شغل، اضغط «سجّل خروجك» تحت.',
  'Your last confirmed status is clocked in. Refresh to confirm the latest status before finishing.': 'آخر حالة اتأكدنا منها إنك حاضر. حدّث البيانات عشان تتأكد من حالتك دلوقتي قبل ما تسجّل خروجك.',
  'Open Earlier shifts & clock-out to finish this attendance.':
      'افتح الشيفتات السابقة وتسجيل الخروج لإغلاق الحضور ده.',
  'Refresh your attendance before taking another action.':
      'حدّث حالة حضورك قبل ما تعمل حاجة تانية.',
  'Checking your attendance': 'بنتأكد من حضورك',
  'Loading your latest status and available shifts.':
      'بنحمّل آخر حالة ليك والشيفتات المتاحة.',
  'Your attendance needs a status check': 'حضورك محتاج مراجعة',
  'Refresh or review the saved attendance below before clocking in again.':
      'حدّث البيانات أو راجع الحضور المحفوظ تحت قبل تسجيل حضور جديد.',
  'Ready to clock in': 'جاهز تسجّل حضورك؟',
  'Choose {name} below to start your attendance.':
      'اختار {name} تحت عشان تسجّل حضورك.',
  'Your next check-in window': 'معاد تسجيل حضورك الجاي',
  'Your workspace lists {name} as upcoming. Refresh when its check-in window opens.': 'شيفت {name} هو اللي جاي في جدولك. حدّث البيانات لما وقت تسجيل حضوره يفتح.',
  'No regular shift assigned yet': 'لسه متحددلكش شيفت أساسي',
  'Ask your manager to assign your regular shift. Extra shifts need separate authorization.': 'اطلب من مديرك يحدد لك شيفتك الأساسي. الشيفتات الإضافية محتاجة تصريح لوحدها.',
  'Your last attendance is closed': 'آخر حضور ليك اتقفل',
  'No new check-in is available right now. Refresh to check your next authorized shift.': 'مفيش تسجيل حضور جديد متاح دلوقتي. حدّث البيانات وشوف شيفتك الجاي المصرّح بيه.',
  'No check-in available right now': 'مفيش تسجيل حضور متاح دلوقتي',
  'Check your assigned schedule below. If a shift is missing, ask your manager to review your assignment.':
      'راجع جدولك تحت. لو فيه شيفت مش ظاهر، اطلب من مديرك يراجع تعيينك.',
  'View and confirm your attendance in My Shifts.':
      'راجع حالة حضورك وأكّدها من صفحة شيفتاتي.',
  'Shift date: {date}': 'تاريخ الشيفت: {date}',
  'Check-in opens: {time}': 'تسجيل الحضور بيفتح: {time}',
  'Last checked: {time}': 'آخر مرة اتأكدنا: {time}',
  'Connection unavailable': 'الاتصال مش متاح',
  'The request took too long': 'الطلب أخد وقت أطول من المعتاد',
  'Sign in to continue': 'ادخل عشان تكمّل',
  'Access needs attention': 'راجع صلاحية الوصول',
  'Review this action': 'راجع العملية دي',
  'Service temporarily unavailable': 'الخدمة واقفة مؤقتًا، جرّب كمان شوية',

  'Unable to confirm the latest status': 'معرفناش نأكد الحالة الحالية',
  'Support reference: {id}': 'رقم مرجعي للدعم: {id}',
  'Refresh status': 'حدّث الحالة',
  'Refreshing status…': 'بنحدّث الحالة…',
  'We could not read the latest information. Refresh to load it again.':
      'معرفناش نقرا أحدث البيانات. حدّث الصفحة عشان تحمّلها تاني.',
  'We could not complete this request. Refresh and check its status before trying again.':
      'معرفناش نكمّل الطلب. حدّث البيانات واتأكد من نتيجته قبل ما تجرّب تاني.',
  'This information changed or conflicts with an existing record. Refresh its status before trying again.':
      'تغيّرت البيانات أو تعارضت مع سجل موجود. حدّث الحالة قبل ما تجرّب تاني.',
  'The request timed out. Please try again.':
      'انتهت مهلة الطلب. اتأكد من حالته قبل ما تجرّب تاني.',
  'Use Clock out when you finish. Your workspace confirms the final worked duration.':
      'سجّل خروجك لما تخلّص شغل. النظام هيأكد مدة الشغل النهائية.',
  ...arabicInterfaceTranslations,
  ...arabicPointsTranslations,
  ...arabicErrorTranslations,
  ...arabicWorkflowTranslations,
  ...arabicReportTranslations,
  ...arabicTeamWorkTranslations,
};
