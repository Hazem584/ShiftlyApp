const arabicWorkdayTranslations = <String, String>{
  'Monthly attendance summary': 'ملخص الحضور الشهري',
  'Present days (including late)': 'أيام الحضور (تشمل التأخير)',
  'Absent days': 'أيام الغياب',
  'Late days': 'أيام التأخير',
  'Leave days': 'أيام الإجازة',
  'Friday is off unless you have an assigned shift.':
      'الجمعة إجازة إلا لو عندك شيفت متسجل في اليوم ده.',
  'Off': 'إجازة',
  'Calendar': 'الكالندر',
  'Edit attendance': 'تعديل الحضور',
  'Save attendance': 'حفظ الحضور',
  'Changes are applied immediately and recorded in the audit history.':
      'التعديل هيتطبق فورًا مع تسجيله في سجل التغييرات.',
  'Your attendance changes only after your manager approves this request.':
      'الحضور هيتعدل بعد موافقة المدير على الطلب.',
  'Overtime is calculated from the approved times and your break policy.':
      'الأوفر تايم بيتحسب من الأوقات المعتمدة وقواعد البريك.',
  'Attendance times must overlap the selected shift.':
      'أوقات الحضور لازم تكون مرتبطة بالشيفت المحدد.',
  'Break reduced by {time} for late arrival.':
      'اتخصم {time} من البريك بسبب التأخير.',
  'No break remaining': 'رصيد البريك خلص',

  'Delete workspace for everyone': 'حذف مساحة العمل لكل الأعضاء',
  'Leave workspace': 'مغادرة مساحة العمل',
  'Permanently delete': 'حذف نهائي',
  'Type {name} to confirm': 'اكتب {name} للتأكيد',
  'This permanently deletes this workspace, its chats, files, tasks and attendance for every member. Their accounts and other workspaces stay available.': 'هيتم حذف مساحة العمل والشات والملفات والمهام والحضور نهائيًا لكل الأعضاء. حساباتهم ومساحات العمل التانية هتفضل موجودة.',
  'This workspace cannot be recovered.': 'لا يمكن استعادة مساحة العمل دي.',
  'You will lose access to this workspace and its chats. Any running attendance will be clocked out. You can return only with a new invitation.': 'هتخرج من مساحة العمل والشات بتاعها، وأي حضور مفتوح هيتقفل. الرجوع محتاج دعوة جديدة.',
  'Could not leave workspace. Please retry.':
      'تعذر الخروج من مساحة العمل. حاول تاني.',

  'Overtime is time after the scheduled shift ends, minus arrival delay. Late arrival reduces the available break.': 'الوقت الإضافي هو الوقت بعد نهاية الشيفت مع خصم التأخير. التأخير بيقلل رصيد البريك المتاح.',

  'Break minutes': 'مدة البريك بالدقائق',
  'Break reminder time': 'ميعاد تذكير البريك',
  'Break must fit within the shift.':
      'مدة وميعاد البريك لازم يكونوا داخل الشيفت.',
  'Break at {time}': 'البريك الساعة {time}',
  'Overtime: {time}': 'وقت إضافي: {time}',

  'Employee status': 'حالة الموظف',
  'Team & attendance': 'الفريق والحضور',
  'Work management': 'إدارة الشغل',
  'My tasks': 'مهامي الشخصية',
  'Workspace sections': 'أقسام مساحة العمل',
  'Review work that needs your decision': 'راجع البنود اللي محتاجة قرارك',
  'Manage shift templates and schedules': 'رتّب قوالب الشيفتات والمواعيد',
  'Review team results and points': 'تابع نتائج الفريق والنقاط',
  'Publish updates and follow acknowledgments':
      'انشر التحديثات وتابع تأكيد قراءتها',
  'Build and review the weekly rota': 'جهّز جدول الأسبوع وراجعه قبل الاعتماد',
  'Transfer open work to the next shift': 'سلّم البنود المفتوحة للشيفت الجاي',
  'Review swaps and find shift coverage': 'راجع التبديلات ووفّر بديل للشيفت',
  'Check attendance records and the team calendar':
      'راجع سجلات الحضور وتقويم الفريق',
  'Performance workspace guide': 'نتائج الفريق وإدارة النقاط',
  'Review results first, then manage points rules, warnings and disputes.':
      'ابدأ بنتائج الموظفين، وبعدها راجع قواعد النقاط والتنبيهات والاعتراضات.',

  'Loading content': 'جارٍ تحميل المحتوى',
  'Your team. Every shift. In sync.': 'فريقك وشيفتاتك… في مكان واحد',
  'Tasks': 'المهام',
  'Your progress': 'إنجازك',
  'Task completion progress': 'نسبة إنجاز المهام',
  '{done} done · {open} remaining': '{done} خلصوا · {open} فاضلين',
  'Task totals are unavailable. Refresh to retry.':
      'أعداد المهام مش متاحة حاليًا. حدّث الصفحة للمحاولة.',
  'ON SHIFT NOW': 'في الشيفت دلوقتي',
  'ON BREAK': 'في البريك',
  'Break remaining {duration}': 'المتبقي من البريك {duration}',
  'Break remaining': 'فاضل من البريك',
  'Time worked': 'الوقت اللي اشتغلته',
  'Shift ended · time worked': 'وقت الشيفت خلص · اشتغلت',
  'Left in this shift': 'فاضل في الشيفت',
  'Worked {time}': 'اشتغلت {time}',
  'Start break': 'ابدأ البريك',
  'End break': 'إنهاء البريك',
  'Break used': 'استخدمت البريك',
  'Hand over': 'تسليم الشيفت',
  'Your break has ended.': 'البريك بتاعك خلص.',
  'Timer is running. Enable notifications to receive a background alert.':
      'المؤقت شغال. فعّل الإشعارات عشان يوصلك تنبيه والتطبيق مقفول.',
  'Could not restore the break timer.': 'مش قادر أسترجع مؤقت البريك.',
  'Could not save the break timer. Try again.':
      'مش قادر أحفظ مؤقت البريك. حاول تاني.',
  'Could not clock out. Check your attendance and retry.':
      'تعذّر تسجيل الانصراف. راجع حالة الحضور وحاول تاني.',
  'This week': 'الأسبوع ده',
  'Full schedule': 'الجدول كامل',
  'Continue to workspace': 'متابعة لمساحة العمل',
};
