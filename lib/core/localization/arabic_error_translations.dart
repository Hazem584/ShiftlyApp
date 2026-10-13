const arabicErrorTranslations = <String, String>{
  'This email is linked to another account. Contact support to complete setup.':
      'الإيميل ده مرتبط بحساب تاني. كلّم الدعم عشان تكمّل إعداد حسابك.',
  'An account with this email already exists. Try signing in.':
      'فيه حساب بالإيميل ده بالفعل. جرّب تسجيل الدخول.',
  'That employee could not be found.': 'الموظف ده مش موجود.',
  'Choose a change before saving.': 'حدّد تغييرًا قبل الحفظ.',
  'This person is already a workspace member.':
      'الشخص ده عضو في مكان الشغل بالفعل.',
  'A pending invitation already exists for this email.':
      'فيه دعوة للإيميل ده لسه مستنية الرد.',
  'This invitation is not valid.': 'الدعوة دي مش صالحة.',
  'This invitation has already been used.': 'الدعوة دي اتستخدمت بالفعل.',
  'This invitation belongs to a different email address.':
      'الدعوة دي لإيميل تاني.',
  'This invitation has expired.': 'صلاحية الدعوة خلصت.',
  'Choose an active employee from this workspace.':
      'اختار موظف نشط من مكان الشغل الحالي.',
  'The selected employee is not active.': 'الموظف المحدّد مش نشط.',
  'Shift end must be after its start and the break must be shorter.':
      'الشيفت لازم يخلص بعد ما يبدأ، والبريك لازم يكون أقصر من مدته.',
  'A shift cannot be longer than 24 hours.':
      'مدة الشيفت مينفعش تزيد عن 24 ساعة.',
  'This shift has been cancelled.': 'اتلغى الشيفت ده.',
  'That shift could not be found.': 'الشيفت ده مش موجود.',
  'Rejected attendance cannot be clocked out.':
      'مينفعش تسجيل الخروج لحضور مرفوض.',
  'This attendance request has already been reviewed.':
      'طلب الحضور ده اتراجع بالفعل.',
  'That attendance record could not be found.': 'سجل الحضور ده مش موجود.',
  'Only active employees can manage leave requests.':
      'إدارة طلبات الإجازة متاحة للموظفين النشطين بس.',
  'Leave end must be after its start.': 'الإجازة لازم تخلص بعد وقت بدايتها.',
  'A leave request cannot be longer than 365 days.':
      'مدة الإجازة مينفعش تزيد عن 365 يوم.',
  'This leave overlaps another pending or approved request.':
      'الإجازة دي بتتداخل مع طلب تاني مستني المراجعة أو متوافق عليه.',
  'That leave request could not be found.': 'طلب الإجازة ده مش موجود.',
  'This leave request has already been reviewed.':
      'طلب الإجازة ده اتراجع بالفعل.',
  'This leave request has already been cancelled.': 'اتلغى طلب الإجازة بالفعل.',
  'Only pending leave requests can be changed.':
      'تقدر تعدّل طلبات الإجازة اللي لسه مستنية المراجعة بس.',
  'That notification is no longer available.': 'التنبيه ده مبقاش متاح.',
  'Enter a reason for rejection.': 'اكتب سبب الرفض.',
  'A rejection reason is only allowed when rejecting.':
      'تقدر تكتب سبب الرفض بس لو هترفض الطلب.',
  'Your workspace membership does not allow this action.':
      'صلاحياتك في مكان الشغل مش بتسمح بالعملية دي.',
  'Minimum work time cannot exceed the shift duration.':
      'الحد الأدنى لمدة الشغل مينفعش يزيد عن مدة الشيفت.',
  'An active template already uses this name.':
      'فيه قالب نشط بالاسم ده بالفعل.',
  'That shift template could not be found.': 'قالب الشيفت ده مش موجود.',
  'This shift template is archived and read only.':
      'قالب الشيفت مؤرشف وللعرض بس.',
  'Ask your manager to assign a baseline fixed shift.':
      'اطلب من المدير تعيين شيفت أساسي ثابت لك.',
  'This template is not your assigned baseline. Ask your manager for an extra authorization.':
      'القالب ده مش شيفتك الأساسي المعيّن. اطلب تصريح شيفت إضافي من المدير.',
  'This shift template is unavailable. Refresh or contact your manager.':
      'قالب الشيفت مش متاح. حدّث البيانات أو كلّم المدير.',
  'Captured attendance protects this assignment. Choose a later effective date.':
      'مينفعش تعدّل التعيين عشان ليه حضور محفوظ. اختار تاريخ سريان بعده.',
  'This assignment overlaps an authorized extra. Review the employee schedule.':
      'التعيين ده بيتداخل مع شيفت إضافي مصرّح بيه. راجع جدول الموظف.',
  'This occurrence has already been used and cannot be reopened.':
      'الشيفت ده اتستخدم بالفعل ومينفعش تفتحه تاني.',
  'This extra authorization is unavailable. Refresh and ask your manager.':
      'تصريح الشيفت الإضافي مش متاح. حدّث البيانات وراجع المدير.',
  'This extra occurrence is already reserved or attended. Review history.':
      'الشيفت الإضافي ده اتحجز أو اتسجّل حضوره بالفعل. راجع السجل.',
  'This occurrence is the assigned baseline. An extra must be a separate occurrence.':
      'ده الشيفت الأساسي المتعيّن. الشيفت الإضافي لازم يكون شيفت منفصل عنه.',
  'This extra has been consumed and cannot be revoked.':
      'تصريح الشيفت الإضافي اتستخدم بالفعل ومينفعش تلغيه.',
  'The saved extra request conflicts with an earlier operation. Keep its evidence and contact support.': 'الطلب الإضافي المحفوظ متعارض مع عملية قبل كده. احتفظ بتفاصيله وكلّم الدعم.',
  'This extra overlaps a baseline or another reserved extra. Choose a different occurrence.': 'الشيفت الإضافي ده بيتداخل مع شيفت أساسي أو إضافي محجوز. اختار معاد تاني.',
  'The check-in window has expired. Record actual attendance for already-worked extras.': 'وقت تسجيل الحضور خلص. لو اشتغلت الشيفت الإضافي بالفعل، سجّل الحضور الفعلي.',
  'Choose a valid operational date.': 'اختار تاريخ يوم شغل صحيح.',
  'Actual clock-out must follow clock-in and both times must be in the past.':
      'الخروج الفعلي لازم يكون بعد الحضور، والوقتين لازم يكونوا قبل دلوقتي.',
  'Actual clock-in must fall within the occurrence check-in window.':
      'وقت الحضور الفعلي لازم يكون جوه فترة التسجيل المسموحة للشيفت.',
  'The employee membership was not established at that clock-in time.':
      'الموظف مكنش عضو في مكان الشغل وقت الحضور المحدد.',
  'This extra authorization is unavailable. Refresh history.':
      'تصريح الشيفت الإضافي مش متاح. حدّث السجل.',
  'This historical schedule needs daylight saving policy review. Contact your manager.':
      'الجدول القديم ده محتاج مراجعة إعدادات التوقيت الصيفي. كلّم مديرك.',
  'This schedule produces an invalid time interval. Review its daylight saving boundaries.':
      'مواعيد الجدول ده مش صحيحة. راجع تغييرات التوقيت الصيفي.',
  'This schedule policy is unsupported. Update the app or contact support.':
      'إعدادات الجدول ده مش مدعومة. حدّث التطبيق أو كلّم الدعم.',
  'Legacy clock-in is disabled. Use your assigned fixed shift or an authorized extra.': 'تسجيل الحضور في الجداول السابقة مش متاح. استخدم شيفتك الثابت أو شيفت إضافي مصرّح بيه.',
  'Choose today or a future date in the workspace timezone.':
      'اختار النهارده أو تاريخ بعده، حسب توقيت مكان الشغل.',
  'Select one or more unique weekdays.': 'اختار يوم شغل أو أكتر من غير تكرار.',
  'Choose a valid effective date.': 'اختار تاريخ سريان صحيح.',
  'Only active employees can receive a new work pattern.':
      'تقدر تعيّن جدول شغل جديد للموظفين النشطين بس.',
  'That employee work pattern is unavailable.': 'جدول شغل الموظف ده مش متاح.',
  'The work pattern changed. Refresh before trying again.':
      'تغيّر جدول الشغل. حدّث البيانات قبل ما تجرّب تاني.',
  'The workspace timezone is invalid. Ask a manager to correct it.':
      'المنطقة الزمنية لمكان الشغل مش صحيحة. اطلب من المدير تصحيحها.',
  'You are not scheduled to work on this operational date.':
      'مفيش عمل مجدول لك في اليوم ده.',
  'This template is outside its current check-in window.':
      'وقت تسجيل الحضور للقالب ده مش متاح دلوقتي.',
  'You already have an open attendance. Refresh to view it.':
      'عندك حضور مفتوح بالفعل. حدّث البيانات لعرضه.',
  'This attendance would overlap another attendance record.':
      'الحضور ده هيتداخل مع سجل حضور تاني.',
  'This clock-in retry no longer matches the original request.':
      'محاولة تسجيل الحضور دي مش مطابقة للطلب الأصلي.',
  'Attendance changed at the same time. Refresh and retry.':
      'تغيّر الحضور وقت تنفيذ العملية. حدّث البيانات وجرّب تاني.',
  'The start date must not be after the end date.':
      'مينفعش تاريخ البداية يكون بعد تاريخ النهاية.',
  'This chat group is archived and read only.':
      'جروب الشات ده متأرشف وللقراءة بس.',
  'That chat group could not be found.': 'جروب الشات ده مش موجود.',
  'Choose active members from the current workspace.':
      'اختار أعضاء نشطين من مكان الشغل الحالي.',
  'Messages changed. Refresh the conversation.': 'تغيّرت الرسايل. حدّث الشات.',
  'This message conflicts with an earlier send attempt.':
      'الرسالة دي متعارضة مع محاولة إرسال قبل كده.',
  'Your read position is already ahead of that message.':
      'إنت متسجّل إنك قريت رسايل أحدث من الرسالة دي بالفعل.',
  'The read position changed. Refreshing will synchronize it.':
      'آخر مكان قريت لحده اتغيّر. حدّث الشات عشان يتزامن.',
  'The message being replied to is no longer available.':
      'الرسالة اللي بترد عليها مبقتش متاحة.',
  'This media format is not supported.': 'صيغة الوسائط مش مدعومة.',
  'The selected media is too large.': 'حجم الوسائط المحدّدة كبير جدًا.',
  'The media details are invalid.': 'تفاصيل الوسائط مش صحيحة.',
  'Media authorization is no longer available.':
      'تصريح الوصول إلى الوسائط مبقاش متاح.',
  'The upload service is temporarily unavailable.':
      'خدمة رفع الملفات مش متاحة مؤقتًا.',
  'The uploaded media could not be verified.':
      'معرفناش نتأكد من الملفات اللي اترفعت.',
  'The uploaded media could not be found. Please retry.':
      'الملفات اللي اترفعت مش موجودة. جرّب تاني.',
  'The uploaded media did not pass verification.':
      'الملفات اللي اترفعت معدّتش التحقق.',
  'The upload destination is invalid. Please retry.':
      'وجهة رفع الملفات مش صحيحة. جرّب تاني.',
  'The media changed after it was prepared. Please retry.':
      'تغيّرت الوسائط بعد تجهيزها. جرّب تاني.',
  'The media upload failed. Please retry.': 'معرفناش نرفع الملفات. جرّب تاني.',
  'The media upload timed out. Please retry.':
      'وقت رفع الملفات خلص. جرّب تاني.',
  'The media upload was cancelled.': 'اتلغى رفع الوسائط.',
  'That upload is no longer available.': 'الملف المرفوع مبقاش متاح.',
  'The upload does not match this message.':
      'الملف اللي اترفع مش مطابق للرسالة دي.',
  'The upload expired. Please try again.': 'انتهت صلاحية الرفع. جرّب تاني.',
  'This upload has already been sent.': 'الملف ده اتبعت بالفعل.',
  'This upload is no longer pending.': 'الملف ده مبقاش مستني الإرسال.',
  'This message has no available media.': 'مفيش وسائط متاحة للرسالة دي.',
  'The selected message cannot be used as a read position.':
      'مينفعش استخدام الرسالة دي لتحديد موضع القراءة.',
  'You do not have enough GREEN points for this redemption.':
      'معندكش نقاط خضراء كافية للتعويض ده.',
  'You do not have an active RED point to compensate.':
      'معندكش نقطة حمراء نشطة تعوّضها.',
  'This redemption conflicts with an earlier request. Refresh and retry.':
      'التعويض ده متعارض مع طلب قبل كده. حدّث البيانات وجرّب تاني.',
  'Points or compensation are currently disabled for this workspace.':
      'النقاط أو التعويض مقفولين دلوقتي في مكان الشغل.',
  'Choose a future workspace-local policy date.':
      'اختار تاريخ بعد النهارده للسياسة، بتوقيت مكان الشغل.',
  'A policy already covers that date. Refresh the version history.':
      'فيه سياسة سارية في التاريخ ده بالفعل. حدّث سجل النسخ.',
  'Another review already resolved this dispute. Refresh its canonical status.':
      'الاعتراض ده اتحسم في مراجعة تانية بالفعل. حدّث وشوف حالته المؤكّدة.',
  'This record has already been reversed. Refresh its audit history.':
      'العملية دي اتعملها عكس بالفعل. حدّث سجلها.',
  'The saved operation conflicts with an existing UUID. Its outcome needs review before another change.': 'العملية المحفوظة متعارضة مع رقم طلب موجود. راجع نتيجتها قبل ما تغيّر حاجة تانية.',
  'Check the quantity, reason and employee evidence.':
      'راجع العدد والسبب وبيانات الموظف المرتبطة.',
  'This date is unresolved because historical work context is unavailable.':
      'لسه مش متأكدين من حالة التاريخ ده عشان بيانات الشغل القديمة مش متاحة.',
  'Your points balance needs support review.': 'رصيد نقاطك محتاج الدعم يراجعه.',
  'Please check the information you entered.': 'راجع البيانات اللي كتبتها.',
  'Your session has expired. Please sign in again.':
      'جلسة حسابك خلصت. ادخل تاني.',
  'You do not have permission to do that.': 'معندكش صلاحية تعمل العملية دي.',
  'The requested item could not be found.': 'الحاجة اللي طلبتها مش موجودة.',
  'The selected file is too large.': 'حجم الملف المحدّد كبير جدًا.',
  'This file type is not supported.': 'نوع الملف مش مدعوم.',
  'The service is temporarily unavailable. Please retry.':
      'الخدمة مش متاحة مؤقتًا. جرّب تاني.',
};
