import 'package:shiftly/core/localization/arabic_error_translations.dart';
import 'package:shiftly/core/localization/arabic_interface_translations.dart';
import 'package:shiftly/core/localization/arabic_points_translations.dart';
import 'package:shiftly/core/localization/arabic_report_translations.dart';
import 'package:shiftly/core/localization/arabic_workflow_translations.dart';

const arabicTranslations = <String, String>{
  'Error code: {code}': 'رمز الخطأ: {code}',
  'This reversal would subtract points that are no longer available. Reverse the related deduction adjustment first, then reverse the original award.': 'هذا الإلغاء سيخصم نقاطًا لم تعد متاحة. اعكس تعديل السحب المرتبط أولًا، ثم ألغِ المنحة الأصلية.',
  'Workspace groups appear here once a manager creates one.':
      'ستظهر مجموعات العمل هنا بعد أن ينشئها المدير.',
  'Active employees': 'الموظفون النشطون',
  'Non-cancelled shifts': 'الشيفتات غير الملغاة',
  'Open attendance': 'حضور لم يُغلق بعد',
  'Missed': 'غياب',
  "Today's shifts": 'شيفتات اليوم',
  'Create a shift': 'إنشاء شيفت',
  'No shifts are scheduled for this workspace day.':
      'لا توجد شيفتات مجدولة في يوم العمل الحالي.',
  'No chat groups yet.': 'لا توجد مجموعات محادثة بعد.',
  'Refresh chat': 'تحديث المحادثات',
  'below': 'بالأسفل',
  'in My Shifts': 'من صفحة شيفتاتي',
  'Your last request is saved. Confirm its outcome {location} before starting another shift.':
      'طلبك الأخير محفوظ. أكّد نتيجته {location} قبل بدء شيفت آخر.',
  'When you finish working, use Clock out {location}.':
      'عندما تنتهي من العمل، اضغط تسجيل الانصراف {location}.',
  'Refresh or review the saved attendance {location} before clocking in again.':
      'حدّث البيانات أو راجع الحضور المحفوظ {location} قبل تسجيل حضور جديد.',
  'Choose {name} {location} to start your attendance.':
      'اختر {name} {location} لتسجيل حضورك.',
  'Check your assigned schedule {location}. If a shift is missing, ask your manager to review your assignment.': 'راجع جدولك {location}. إذا كان هناك شيفت غير ظاهر، اطلب من مديرك مراجعة تعيينك.',
  'Choose an available shift to clock in. Your active shift will show the clock-out action.':
      'اختر شيفتًا متاحًا لتسجيل حضورك. سيظهر زر الانصراف في الشيفت النشط.',
  'Earlier shifts': 'الشيفتات السابقة',
  'Recommended': 'مُوصى به',
  'Assigned BASELINE': 'الشيفت الأساسي المعيّن',
  'Authorized EXTRA': 'شيفت إضافي مصرّح به',
  'Authorized EXTRA ? no automatic BLUE award':
      'شيفت إضافي مصرّح به · لا يمنح نقاط BLUE تلقائيًا',
  'Historical attendance ? assignment evidence not recorded':
      'حضور سابق · بيانات التعيين غير مسجّلة',
  'Unknown occurrence; read-only': 'شيفت غير معروف؛ للعرض فقط',
  'Already used; cannot reopen': 'تم تسجيله بالفعل؛ لا يمكن إعادة فتحه',
  'Outside check-in window / read-only': 'خارج وقت تسجيل الحضور؛ للعرض فقط',

  'Clocked in: {time}': 'وقت الحضور: {time}',
  'Schedule: {start} – {end}': 'موعد الشيفت: {start} – {end}',
  'Operational date: {date}': 'تاريخ يوم العمل: {date}',
  'Unavailable': 'غير متاح',
  'Fixed shift': 'شيفت ثابت',
  'Elapsed (display only): {duration}': 'الوقت المنقضي (للعرض فقط): {duration}',
  'Get Started': 'ابدأ الآن',
  'Saving…': 'جارٍ الحفظ…',
  'Retry preference check': 'إعادة التحقق من الإعدادات',
  'Preparing your dashboard…': 'جارٍ تجهيز صفحتك الرئيسية…',
  'Active attendance': 'حضور نشط',
  'Shifts': 'الشيفتات',
  'Requests': 'الطلبات',
  'Invite someone': 'دعوة موظف',
  'Plan the day': 'خطّط لليوم',
  'Review leave': 'مراجعة الإجازات',
  'Employee points, policies, disputes and warnings':
      'نقاط الموظفين والسياسات والاعتراضات والتنبيهات',
  'Contact information': 'بيانات التواصل',
  'Email address': 'البريد الإلكتروني',
  'Workplace': 'مكان العمل',
  'Leave Requests': 'طلبات الإجازة',
  'Completed': 'مكتمل',
  'No shift scheduled.': 'لا يوجد شيفت مجدول.',
  'Create your Shiftly account': 'أنشئ حسابك على Shiftly',

  'Use at least 8 characters': 'استخدم ٨ أحرف على الأقل',
  'Passwords do not match': 'كلمتا المرور غير متطابقتين',
  'Show password': 'إظهار كلمة المرور',
  'Hide password': 'إخفاء كلمة المرور',
  'Show password confirmation': 'إظهار تأكيد كلمة المرور',
  'Hide password confirmation': 'إخفاء تأكيد كلمة المرور',
  'Already have an account? Sign in': 'لديك حساب بالفعل؟ سجّل الدخول',
  'Good morning, Manager!': 'أهلًا بك!',
  "Here's what's happening with your team today.":
      'إليك آخر أخبار فريقك اليوم.',
  'Your shifts, clearly organized': 'شيفتاتك مرتّبة بوضوح',
  'Know what’s next, and keep your working day in view.':
      'اعرف موعد شيفتك القادم وتابع يوم عملك بسهولة.',
  'Assigned fixed shifts': 'شيفتاتك الثابتة المعيّنة',
  'Check in and check out': 'تسجيل الحضور والانصراف',
  'Manager-authorized extra shifts': 'شيفتات إضافية بتصريح من المدير',
  'See your progress': 'تابع تقدّمك',
  'Follow your attendance and celebrate the progress you make.':
      'تابع حضورك واحتفل بتقدّمك.',
  'Attendance points': 'نقاط الحضور',
  'Performance history': 'سجل الأداء',
  'Achievements along the way': 'إنجازاتك مع كل خطوة',
  'Stay connected': 'خليك على تواصل',
  'Keep your workspace conversations and updates together.':
      'محادثات مساحة عملك وآخر أخبارها في مكان واحد.',
  'Workspace group chat': 'محادثات مجموعات العمل',
  'Images and voice messages': 'صور ورسائل صوتية',
  'Notifications and updates': 'إشعارات وآخر الأخبار',
  'Your workday, in one place · Times in {timezone}':
      'يوم عملك في مكان واحد · التوقيت: {timezone}',
  'Your last request is saved. Confirm its outcome in My Shifts before starting another shift.':
      'طلبك الأخير محفوظ. أكّد نتيجته من صفحة شيفتاتي قبل بدء شيفت آخر.',
  'When you finish working, use Clock out in My Shifts.':
      'عندما تنتهي من العمل، سجّل الانصراف من صفحة شيفتاتي.',
  'Refresh or review the saved attendance in My Shifts before clocking in again.': 'حدّث البيانات أو راجع الحضور المحفوظ من صفحة شيفتاتي قبل تسجيل حضور جديد.',
  'Choose {name} in My Shifts to start your attendance.':
      'اختر {name} من صفحة شيفتاتي لتسجيل حضورك.',
  'Check your assigned schedule in My Shifts. If a shift is missing, ask your manager to review your assignment.': 'راجع جدولك من صفحة شيفتاتي. إذا كان هناك شيفت غير ظاهر، اطلب من مديرك مراجعة تعيينك.',
  'Request cancelled.': 'تم إلغاء الطلب.',
  'You appear to be offline. Check your connection and retry.':
      'يبدو أنك غير متصل بالإنترنت. تحقق من الاتصال وحاول مجددًا.',
  'The email or password is incorrect.':
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
  'Complete your profile to continue.': 'أكمل ملفك الشخصي للمتابعة.',
  'Too many requests. Please wait and try again.':
      'هناك طلبات كثيرة. انتظر قليلًا ثم حاول مجددًا.',
  'You have already clocked in for this shift.':
      'سجّلت حضورك في هذا الشيفت بالفعل.',
  'You have already clocked out for this shift.':
      'سجّلت انصرافك من هذا الشيفت بالفعل.',
  'Clock-in is not available yet for this shift.':
      'لم يبدأ وقت تسجيل الحضور لهذا الشيفت بعد.',
  'This shift has already ended.': 'انتهى هذا الشيفت بالفعل.',
  'This shift is already completed.': 'هذا الشيفت مكتمل بالفعل.',
  'This employee already has an overlapping shift.':
      'لدى الموظف شيفت آخر في نفس الوقت.',
  'We could not save your profile. Refresh your profile to check its latest details before saving again.':
      'تعذّر حفظ ملفك الشخصي. حدّث البيانات وتحقق منها قبل الحفظ مجددًا.',
  'We could not confirm your latest points information. Refresh your balance and history before trying again.': 'تعذّر تأكيد بيانات نقاطك الحالية. حدّث الرصيد والسجل قبل المحاولة مجددًا.',
  'Language': 'اللغة',
  'Device language': 'لغة الجهاز',
  'Choose Arabic, English or your device language':
      'اختر العربية أو الإنجليزية أو لغة الجهاز',
  'Could not save language. Please try again.':
      'تعذّر حفظ اللغة. حاول مرة أخرى.',
  'Dashboard': 'الرئيسية',
  'Overview': 'نظرة عامة',
  'Employees': 'الموظفون',

  'Chat': 'المحادثات',
  'Profile': 'الملف الشخصي',
  'Performance': 'الأداء',
  'My Shifts': 'شيفتاتي',
  'Employee workspace': 'مساحة عمل الموظف',
  'Manager Profile': 'الملف الشخصي للمدير',

  'Switch workspace': 'تغيير مساحة العمل',
  'Sign out': 'تسجيل الخروج',

  'Sign in': 'تسجيل الدخول',
  'Unable to sign in.': 'تعذّر تسجيل الدخول.',
  'Email': 'البريد الإلكتروني',
  'Password': 'كلمة المرور',
  'Confirm password': 'تأكيد كلمة المرور',
  'Enter a valid email address': 'أدخل بريدًا إلكترونيًا صحيحًا',
  'Password is required': 'أدخل كلمة المرور',

  'Create account': 'إنشاء حساب',
  'Create your account': 'أنشئ حسابك',
  'Full name': 'الاسم الكامل',
  'Phone': 'رقم الهاتف',
  'Phone number': 'رقم الهاتف',
  'Cancel': 'إلغاء',
  'Create': 'إنشاء',
  'Save': 'حفظ',
  'Save changes': 'حفظ التغييرات',
  'Edit': 'تعديل',
  'Delete': 'حذف',
  'Close': 'إغلاق',
  'Retry': 'إعادة المحاولة',
  'Try again': 'حاول مرة أخرى',
  'Refresh': 'تحديث',
  'Search': 'بحث',
  'Next': 'التالي',
  'Back': 'رجوع',
  'Continue': 'متابعة',
  'Skip': 'تخطّي',
  'Get started': 'ابدأ الآن',
  'Add Employee': 'إضافة موظف',
  'Add employee': 'إضافة موظف',
  'Create Shift': 'إنشاء شيفت',
  'Create shift': 'إنشاء شيفت',
  'Review Requests': 'مراجعة الطلبات',
  'Review requests': 'مراجعة الطلبات',
  'Employee details': 'تفاصيل الموظف',
  'Search employees': 'البحث عن موظف',
  'Active': 'نشط',
  'Inactive': 'غير نشط',
  'All': 'الكل',

  'Name': 'الاسم',
  'Description (optional)': 'الوصف (اختياري)',
  'Members': 'الأعضاء',
  'New group': 'مجموعة جديدة',
  'Create chat group': 'إنشاء مجموعة محادثة',
  'Message': 'رسالة',
  'Save image': 'حفظ الصورة',
  'Notifications': 'الإشعارات',
  'Mark all as read': 'تحديد الكل كمقروء',
  'No notifications yet': 'لا توجد إشعارات بعد',
  'Clear': 'مسح',
  'Chat media cache': 'ملفات المحادثات المحفوظة مؤقتًا',

  'Edit profile': 'تعديل الملف الشخصي',
  'Personal information': 'البيانات الشخصية',
  'Work information': 'بيانات العمل',
  'Workspace': 'مساحة العمل',
  'Role': 'الدور',
  'Status': 'الحالة',
  'Manager': 'مدير',
  'Employee': 'موظف',
  'Department': 'القسم',

  'Preparing your dashboard': 'جارٍ تجهيز صفحتك الرئيسية',

  'Total employees': 'إجمالي الموظفين',
  'Scheduled today': 'المجدولون اليوم',
  'Clocked in now': 'حاضرون الآن',
  'Completed today': 'أكملوا العمل اليوم',
  'Late today': 'المتأخرون اليوم',
  'Missed today': 'الغائبون اليوم',
  'On approved leave': 'في إجازة معتمدة',
  'Today at a glance': 'ملخّص اليوم',
  'Ready for your workday?': 'جاهز ليوم العمل؟',
  'Your shifts, attendance and time off are a tap away.':
      'تابع شيفتاتك وحضورك وإجازاتك بسهولة.',
  'Hello, {name}': 'أهلًا، {name}',
  'Request leave': 'طلب إجازة',
  'Pending leave': 'إجازات قيد المراجعة',

  'Fixed shifts': 'الشيفتات الثابتة',
  'Earlier shifts & clock-out': 'الشيفتات السابقة وتسجيل الانصراف',
  'Open My Shifts': 'افتح شيفتاتي',
  'Clock in': 'تسجيل الحضور',
  'Clock out': 'تسجيل الانصراف',
  'Clocked in': 'حاضر',
  'Clocked out': 'انصرف',
  'Recorded': 'مسجّل',
  'On time': 'في الموعد',
  'Early': 'مبكر',

  'Your clock-in needs confirmation': 'تسجيل حضورك يحتاج إلى تأكيد',
  'Your last request is saved. Confirm its outcome below before starting another shift.':
      'طلبك الأخير محفوظ. أكّد نتيجته بالأسفل قبل بدء شيفت آخر.',
  'Confirming your clock-out': 'جارٍ تأكيد انصرافك',
  'Confirming your clock-in': 'جارٍ تأكيد حضورك',
  'Waiting for your workspace to confirm the attendance change.':
      'ننتظر تأكيد مساحة عملك لتغيير حالة الحضور.',
  'You are clocked in': 'تم تسجيل حضورك',
  'An earlier attendance is still open': 'لديك حضور سابق لم يُغلق بعد',
  'When you finish working, use Clock out below.':
      'عندما تنتهي من العمل، اضغط تسجيل الانصراف بالأسفل.',
  'Your last confirmed status is clocked in. Refresh to confirm the latest status before finishing.': 'آخر حالة مؤكّدة لك هي الحضور. حدّث البيانات لتأكيد حالتك الحالية قبل الانصراف.',
  'Open Earlier shifts & clock-out to finish this attendance.':
      'افتح الشيفتات السابقة وتسجيل الانصراف لإغلاق هذا الحضور.',
  'Refresh your attendance before taking another action.':
      'حدّث حالة حضورك قبل اتخاذ إجراء آخر.',
  'Checking your attendance': 'جارٍ التحقق من حضورك',
  'Loading your latest status and available shifts.':
      'جارٍ تحميل حالتك الحالية والشيفتات المتاحة.',
  'Your attendance needs a status check': 'حالة حضورك تحتاج إلى مراجعة',
  'Refresh or review the saved attendance below before clocking in again.':
      'حدّث البيانات أو راجع الحضور المحفوظ بالأسفل قبل تسجيل حضور جديد.',
  'Ready to clock in': 'يمكنك تسجيل الحضور',
  'Choose {name} below to start your attendance.':
      'اختر {name} بالأسفل لتسجيل حضورك.',
  'Your next check-in window': 'موعد تسجيل الحضور القادم',
  'Your workspace lists {name} as upcoming. Refresh when its check-in window opens.': 'تعرض مساحة عملك شيفت {name} كموعد قادم. حدّث البيانات عندما يبدأ وقت تسجيله.',
  'No regular shift assigned yet': 'لم يُعيّن لك شيفت أساسي بعد',
  'Ask your manager to assign your regular shift. Extra shifts need separate authorization.': 'اطلب من مديرك تعيين شيفتك الأساسي. الشيفتات الإضافية تحتاج إلى تصريح منفصل.',
  'Your last attendance is closed': 'تم إغلاق حضورك الأخير',
  'No new check-in is available right now. Refresh to check your next authorized shift.': 'لا يوجد تسجيل حضور متاح الآن. حدّث البيانات للتحقق من الشيفت القادم المصرّح لك به.',
  'No check-in available right now': 'لا يوجد تسجيل حضور متاح الآن',
  'Check your assigned schedule below. If a shift is missing, ask your manager to review your assignment.': 'راجع جدولك بالأسفل. إذا كان هناك شيفت غير ظاهر، اطلب من مديرك مراجعة تعيينك.',
  'View and confirm your attendance in My Shifts.':
      'راجع حالة حضورك وأكّدها من صفحة شيفتاتي.',
  'Shift date: {date}': 'تاريخ الشيفت: {date}',
  'Check-in opens: {time}': 'يبدأ تسجيل الحضور: {time}',
  'Last checked: {time}': 'آخر تحقق: {time}',
  'Connection unavailable': 'الاتصال غير متاح',
  'The request took too long': 'استغرق الطلب وقتًا أطول من المعتاد',
  'Sign in to continue': 'سجّل الدخول للمتابعة',
  'Access needs attention': 'راجع صلاحية الوصول',
  'Review this action': 'راجع هذا الإجراء',
  'Service temporarily unavailable': 'الخدمة غير متاحة مؤقتًا',

  'Unable to confirm the latest status': 'تعذّر تأكيد الحالة الحالية',
  'Support reference: {id}': 'رقم مرجعي للدعم: {id}',
  'Refresh status': 'تحديث الحالة',
  'Refreshing status…': 'جارٍ تحديث الحالة…',
  'We could not read the latest information. Refresh to load it again.':
      'تعذّرت قراءة أحدث البيانات. حدّث الصفحة لتحميلها مرة أخرى.',
  'We could not complete this request. Refresh and check its status before trying again.':
      'تعذّر إكمال الطلب. حدّث البيانات وتحقق من نتيجته قبل المحاولة مجددًا.',
  'This information changed or conflicts with an existing record. Refresh its status before trying again.': 'تغيّرت البيانات أو تعارضت مع سجل موجود. حدّث الحالة قبل المحاولة مجددًا.',
  'The request timed out. Please try again.':
      'انتهت مهلة الطلب. تحقق من حالته قبل المحاولة مجددًا.',
  'Use Clock out when you finish. Your workspace confirms the final worked duration.':
      'سجّل الانصراف عند انتهاء العمل. تؤكّد مساحة عملك مدة العمل النهائية.',
  ...arabicInterfaceTranslations,
  ...arabicPointsTranslations,
  ...arabicErrorTranslations,
  ...arabicWorkflowTranslations,
  ...arabicReportTranslations,
};
