const arabicErrorTranslations = <String, String>{
  'An account with this email already exists. Try signing in.':
      'يوجد حساب بهذا البريد الإلكتروني بالفعل. جرّب تسجيل الدخول.',
  'That employee could not be found.': 'الموظف غير موجود.',
  'Choose a change before saving.': 'حدّد تغييرًا قبل الحفظ.',
  'This person is already a workspace member.':
      'هذا الشخص عضو بالفعل في مساحة العمل.',
  'A pending invitation already exists for this email.':
      'توجد دعوة قيد الانتظار لهذا البريد الإلكتروني.',
  'This invitation is not valid.': 'هذه الدعوة غير صالحة.',
  'This invitation has already been used.': 'تم استخدام هذه الدعوة بالفعل.',
  'This invitation belongs to a different email address.':
      'هذه الدعوة تخص بريدًا إلكترونيًا آخر.',
  'This invitation has expired.': 'انتهت صلاحية الدعوة.',
  'Choose an active employee from this workspace.':
      'اختر موظفًا نشطًا من مساحة العمل الحالية.',
  'The selected employee is not active.': 'الموظف المحدّد غير نشط.',
  'Shift end must be after its start and the break must be shorter.':
      'يجب أن تنتهي فترة العمل بعد بدايتها، وأن تكون الاستراحة أقصر من مدتها.',
  'A shift cannot be longer than 24 hours.':
      'لا يمكن أن تتجاوز مدة الشيفت 24 ساعة.',
  'This shift has been cancelled.': 'تم إلغاء هذا الشيفت.',
  'That shift could not be found.': 'الشيفت غير موجود.',
  'Rejected attendance cannot be clocked out.':
      'لا يمكن تسجيل الانصراف لحضور مرفوض.',
  'This attendance request has already been reviewed.':
      'تمت مراجعة طلب الحضور بالفعل.',
  'That attendance record could not be found.': 'سجل الحضور غير موجود.',
  'Only active employees can manage leave requests.':
      'إدارة طلبات الإجازة متاحة للموظفين النشطين فقط.',
  'Leave end must be after its start.': 'يجب أن تنتهي الإجازة بعد وقت بدايتها.',
  'A leave request cannot be longer than 365 days.':
      'لا يمكن أن تتجاوز مدة الإجازة 365 يومًا.',
  'This leave overlaps another pending or approved request.':
      'هذه الإجازة تتداخل مع طلب آخر قيد المراجعة أو مقبول.',
  'That leave request could not be found.': 'طلب الإجازة غير موجود.',
  'This leave request has already been reviewed.':
      'تمت مراجعة طلب الإجازة بالفعل.',
  'This leave request has already been cancelled.':
      'تم إلغاء طلب الإجازة بالفعل.',
  'Only pending leave requests can be changed.':
      'يمكن تعديل طلبات الإجازة قيد المراجعة فقط.',
  'That notification is no longer available.': 'هذا الإشعار لم يعد متاحًا.',
  'Enter a reason for rejection.': 'أدخل سبب الرفض.',
  'A rejection reason is only allowed when rejecting.':
      'يمكن إدخال سبب رفض عند رفض الطلب فقط.',
  'Your workspace membership does not allow this action.':
      'صلاحيات عضويتك لا تسمح بهذه العملية.',
  'Minimum work time cannot exceed the shift duration.':
      'الحد الأدنى لمدة العمل لا يمكن أن يتجاوز مدة الشيفت.',
  'An active template already uses this name.':
      'يوجد قالب نشط بهذا الاسم بالفعل.',
  'That shift template could not be found.': 'قالب الشيفت غير موجود.',
  'This shift template is archived and read only.':
      'قالب الشيفت مؤرشف وللعرض فقط.',
  'Ask your manager to assign a baseline fixed shift.':
      'اطلب من المدير تعيين شيفت أساسي ثابت لك.',
  'This template is not your assigned baseline. Ask your manager for an extra authorization.':
      'هذا القالب ليس شيفتك الأساسي المعيّن. اطلب تصريح شيفت إضافي من المدير.',
  'This shift template is unavailable. Refresh or contact your manager.':
      'قالب الشيفت غير متاح. حدّث البيانات أو تواصل مع المدير.',
  'Captured attendance protects this assignment. Choose a later effective date.': 'لا يمكن تعديل التعيين بسبب سجلات الحضور المحفوظة. اختر تاريخ سريان لاحقًا.',
  'This assignment overlaps an authorized extra. Review the employee schedule.':
      'هذا التعيين يتداخل مع شيفت إضافي مصرّح به. راجع جدول الموظف.',
  'This occurrence has already been used and cannot be reopened.':
      'تم استخدام هذا الشيفت بالفعل ولا يمكن فتحه مجددًا.',
  'This extra authorization is unavailable. Refresh and ask your manager.':
      'تصريح الشيفت الإضافي غير متاح. حدّث البيانات وراجع المدير.',
  'This extra occurrence is already reserved or attended. Review history.':
      'تم حجز هذا الشيفت الإضافي أو تسجيل حضوره بالفعل. راجع السجل.',
  'This occurrence is the assigned baseline. An extra must be a separate occurrence.':
      'هذا هو الشيفت الأساسي المعيّن. يجب اختيار شيفت منفصل للعمل الإضافي.',
  'This extra has been consumed and cannot be revoked.':
      'تم استخدام تصريح الشيفت الإضافي ولا يمكن إلغاؤه.',
  'The saved extra request conflicts with an earlier operation. Keep its evidence and contact support.': 'الطلب الإضافي المحفوظ يتعارض مع عملية سابقة. احتفظ بتفاصيله وتواصل مع الدعم.',
  'This extra overlaps a baseline or another reserved extra. Choose a different occurrence.':
      'الشيفت الإضافي يتداخل مع شيفت أساسي أو إضافي محجوز. اختر موعدًا آخر.',
  'The check-in window has expired. Record actual attendance for already-worked extras.': 'انتهى وقت تسجيل الحضور. سجّل الحضور الفعلي للشيفتات الإضافية التي انتهى العمل بها.',
  'Choose a valid operational date.': 'اختر تاريخ يوم عمل صحيحًا.',
  'Actual clock-out must follow clock-in and both times must be in the past.':
      'يجب أن يكون الانصراف الفعلي بعد الحضور، وأن يكون الوقتان في الماضي.',
  'Actual clock-in must fall within the occurrence check-in window.':
      'وقت الحضور الفعلي يجب أن يكون ضمن فترة التسجيل المسموح بها للشيفت.',
  'The employee membership was not established at that clock-in time.':
      'لم تكن عضوية الموظف موجودة في وقت الحضور المحدّد.',
  'This extra authorization is unavailable. Refresh history.':
      'تصريح الشيفت الإضافي غير متاح. حدّث السجل.',
  'This historical schedule needs daylight saving policy review. Contact your manager.': 'هذا الجدول السابق يحتاج إلى مراجعة إعدادات التوقيت الصيفي. تواصل مع المدير.',
  'This schedule produces an invalid time interval. Review its daylight saving boundaries.':
      'مواعيد هذا الجدول غير صحيحة. راجع تغييرات التوقيت الصيفي.',
  'This schedule policy is unsupported. Update the app or contact support.':
      'إعدادات هذا الجدول غير مدعومة. حدّث التطبيق أو تواصل مع الدعم.',
  'Legacy clock-in is disabled. Use your assigned fixed shift or an authorized extra.': 'تسجيل الحضور في الجداول السابقة غير متاح. استخدم شيفتك الثابت أو شيفتًا إضافيًا مصرّحًا به.',
  'Choose today or a future date in the workspace timezone.':
      'اختر اليوم أو تاريخًا مستقبليًا حسب توقيت مساحة العمل.',
  'Select one or more unique weekdays.':
      'اختر يوم عمل واحدًا أو أكثر دون تكرار.',
  'Choose a valid effective date.': 'اختر تاريخ سريان صحيحًا.',
  'Only active employees can receive a new work pattern.':
      'يمكن تعيين جدول عمل جديد للموظفين النشطين فقط.',
  'That employee work pattern is unavailable.': 'جدول عمل الموظف غير متاح.',
  'The work pattern changed. Refresh before trying again.':
      'تغيّر جدول العمل. حدّث البيانات قبل المحاولة مجددًا.',
  'The workspace timezone is invalid. Ask a manager to correct it.':
      'المنطقة الزمنية لمساحة العمل غير صحيحة. اطلب من المدير تصحيحها.',
  'You are not scheduled to work on this operational date.':
      'لا يوجد عمل مجدول لك في هذا اليوم.',
  'This template is outside its current check-in window.':
      'وقت تسجيل الحضور لهذا القالب غير متاح حاليًا.',
  'You already have an open attendance. Refresh to view it.':
      'لديك حضور مفتوح بالفعل. حدّث البيانات لعرضه.',
  'This attendance would overlap another attendance record.':
      'هذا الحضور سيتداخل مع سجل حضور آخر.',
  'This clock-in retry no longer matches the original request.':
      'محاولة تسجيل الحضور لا تطابق الطلب الأصلي.',
  'Attendance changed at the same time. Refresh and retry.':
      'تغيّر الحضور أثناء تنفيذ العملية. حدّث البيانات وحاول مجددًا.',
  'The start date must not be after the end date.':
      'تاريخ البداية يجب ألا يكون بعد تاريخ النهاية.',
  'This chat group is archived and read only.':
      'مجموعة المحادثة مؤرشفة وللعرض فقط.',
  'That chat group could not be found.': 'مجموعة المحادثة غير موجودة.',
  'Choose active members from the current workspace.':
      'اختر أعضاء نشطين من مساحة العمل الحالية.',
  'Messages changed. Refresh the conversation.':
      'تغيّرت الرسائل. حدّث المحادثة.',
  'This message conflicts with an earlier send attempt.':
      'هذه الرسالة تتعارض مع محاولة إرسال سابقة.',
  'Your read position is already ahead of that message.':
      'تم تسجيل قراءتك لرسائل أحدث من هذه الرسالة بالفعل.',
  'The read position changed. Refreshing will synchronize it.':
      'تغيّر موضع القراءة. حدّث المحادثة لمزامنته.',
  'The message being replied to is no longer available.':
      'الرسالة التي ترد عليها لم تعد متاحة.',
  'This media format is not supported.': 'صيغة الوسائط غير مدعومة.',
  'The selected media is too large.': 'حجم الوسائط المحدّدة كبير جدًا.',
  'The media details are invalid.': 'تفاصيل الوسائط غير صحيحة.',
  'Media authorization is no longer available.':
      'تصريح الوصول إلى الوسائط لم يعد متاحًا.',
  'The upload service is temporarily unavailable.':
      'خدمة رفع الملفات غير متاحة مؤقتًا.',
  'The uploaded media could not be verified.':
      'تعذّر التحقّق من الوسائط المرفوعة.',
  'The uploaded media could not be found. Please retry.':
      'الوسائط المرفوعة غير موجودة. حاول مجددًا.',
  'The uploaded media did not pass verification.':
      'الوسائط المرفوعة لم تجتز التحقّق.',
  'The upload destination is invalid. Please retry.':
      'وجهة رفع الملفات غير صحيحة. حاول مجددًا.',
  'The media changed after it was prepared. Please retry.':
      'تغيّرت الوسائط بعد تجهيزها. حاول مجددًا.',
  'The media upload failed. Please retry.': 'تعذّر رفع الوسائط. حاول مجددًا.',
  'The media upload timed out. Please retry.':
      'انتهت مهلة رفع الوسائط. حاول مجددًا.',
  'The media upload was cancelled.': 'تم إلغاء رفع الوسائط.',
  'That upload is no longer available.': 'الملف المرفوع لم يعد متاحًا.',
  'The upload does not match this message.':
      'الملف المرفوع لا يطابق هذه الرسالة.',
  'The upload expired. Please try again.': 'انتهت صلاحية الرفع. حاول مجددًا.',
  'This upload has already been sent.': 'تم إرسال هذا الملف بالفعل.',
  'This upload is no longer pending.': 'هذا الملف لم يعد قيد الإرسال.',
  'This message has no available media.': 'لا توجد وسائط متاحة لهذه الرسالة.',
  'The selected message cannot be used as a read position.':
      'لا يمكن استخدام هذه الرسالة لتحديد موضع القراءة.',
  'You do not have enough GREEN points for this redemption.':
      'ليس لديك نقاط خضراء كافية لهذا التعويض.',
  'You do not have an active RED point to compensate.':
      'لا توجد لديك نقطة حمراء نشطة لتعويضها.',
  'This redemption conflicts with an earlier request. Refresh and retry.':
      'هذا التعويض يتعارض مع طلب سابق. حدّث البيانات وحاول مجددًا.',
  'Points or compensation are currently disabled for this workspace.':
      'النقاط أو التعويض غير مفعّل حاليًا في مساحة العمل.',
  'Choose a future workspace-local policy date.':
      'اختر تاريخًا مستقبليًا للسياسة حسب توقيت مساحة العمل.',
  'A policy already covers that date. Refresh the version history.':
      'توجد سياسة سارية في هذا التاريخ بالفعل. حدّث سجل النسخ.',
  'Another review already resolved this dispute. Refresh its canonical status.':
      'تم حسم الاعتراض في مراجعة أخرى. حدّث حالته المؤكّدة.',
  'This record has already been reversed. Refresh its audit history.':
      'تم عكس هذه العملية بالفعل. حدّث سجلها.',
  'The saved operation conflicts with an existing UUID. Its outcome needs review before another change.': 'العملية المحفوظة تتعارض مع معرّف طلب موجود. راجع نتيجتها قبل إجراء تغيير آخر.',
  'Check the quantity, reason and employee evidence.':
      'راجع العدد والسبب وبيانات الموظف المرتبطة.',
  'This date is unresolved because historical work context is unavailable.':
      'لم تُحسم حالة هذا التاريخ لعدم توفر بيانات العمل السابقة.',
  'Your points balance needs support review.':
      'رصيد نقاطك يحتاج إلى مراجعة الدعم.',
  'Please check the information you entered.': 'راجع البيانات التي أدخلتها.',
  'Your session has expired. Please sign in again.':
      'انتهت جلستك. سجّل الدخول مجددًا.',
  'You do not have permission to do that.':
      'ليس لديك صلاحية لتنفيذ هذه العملية.',
  'The requested item could not be found.': 'العنصر المطلوب غير موجود.',
  'The selected file is too large.': 'حجم الملف المحدّد كبير جدًا.',
  'This file type is not supported.': 'نوع الملف غير مدعوم.',
  'The service is temporarily unavailable. Please retry.':
      'الخدمة غير متاحة مؤقتًا. حاول مجددًا.',
};
