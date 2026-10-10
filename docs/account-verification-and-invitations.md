# تسجيل الحساب وتأكيد البريد والدعوات

## إعداد Supabase بعد نشر الواجهة

1. افتح **Authentication → URL Configuration → Redirect URLs** في مشروع Supabase.
2. أضف الرابط التالي مع الاحتفاظ بروابطك الحالية:

   ```text
   https://shiftly-app-smoky.vercel.app/email-confirmed.html
   ```

3. للتطوير المحلي أضف `http://localhost:5173/email-confirmed.html`. لأي Preview أضف نفس المسار على دومين الـ Preview المقصود.
4. في **Authentication → Email Templates → Confirm signup**، تأكد أن زر التأكيد يستخدم `{{ .ConfirmationURL }}`. لا تستبدله برابط صفحة النجاح مباشرة؛ Supabase يجب أن يتحقق من الرابط أولًا.
5. أبقِ **Confirm email** مفعّلًا. لو **Confirm phone** مفعّل في إعدادات Auth ولا تستخدم تسجيل الهاتف، يمكنك تعطيله ليعيد Supabase خطأ صريحًا للحساب المؤكد الموجود بدل الرد الذي يخفي وجود الحساب. التطبيق يتعامل مع الحالتين.

صفحة `email-confirmed.html` مستقلة عن Flutter. بعد تحقق Supabase، تعرض:

> Email verified successfully
>
> You’re all set! Return to Shiftly and sign in to your account.

لا تتبادل الصفحة كود PKCE للحصول على جلسة، ولا تحفظ رموز الدخول أو تسجّل المستخدم تلقائيًا. تمسح معاملات الرابط من شريط العنوان. الرابط المنتهي أو المستخدم يعرض رسالة خطأ، وفتح الصفحة مباشرة لا يعرض نجاحًا.

تسجيل الويب يوجّه البريد إلى هذه الصفحة على أصل الموقع الحالي. Android وiOS يستخدمان رابط الإنتاج أعلاه. عند تغيير دومين الإنتاج، مرر `AUTH_EMAIL_REDIRECT_URL` في إعدادات بناء الموبايل إلى الرابط الجديد وأضفه لقائمة Supabase.

إعادة التسجيل بحساب **مؤكد** موجود تعرض خطأ وتبقى على شاشة التسجيل، سواء أعاد Supabase خطأ صريحًا أو مستخدمًا بغير identities. الحساب الذي لم يؤكد بريده بعد قد يعيد Supabase إرسال التأكيد عند محاولة التسجيل مجددًا؛ هذا ليس إنشاء حساب ثانٍ. لا يوفّر التطبيق نقطة عامة للبحث عن حسابات البريد.

## قبول دعوة مع وجود عضوية بالفعل

1. سجّل الدخول بالبريد الذي دُعي إلى مساحة العمل الجديدة.
2. على الموظف اضغط أيقونة المبنى في الشريط العلوي. على المدير افتح الملف الشخصي ثم **Switch workspace**.
3. اضغط **Workspaces and invitations**.
4. الصق رمز الدعوة الذي شاركه المدير واضغط **Accept invitation**.

تظل الدعوات ظاهرة حتى لو للحساب عضوية واحدة أو عدة عضويات. قائمة الدعوات لا تحتوي رمز القبول؛ المدير يشارك رمزًا مرة واحدة عند إنشاء الدعوة. بعد القبول، يعيد التطبيق تحميل العضويات والصلاحيات من السيرفر ويفتح المساحة الجديدة، ويمكن العودة للقديمة من زر تبديل مساحة العمل.

## التحقق

```powershell
flutter test test/supabase_registration_test.dart test/session_routing_test.dart test/profile_widget_test.dart test/workspaces_cubit_test.dart
node scripts/email-confirmation.test.mjs
```

مراجع: [Supabase signUp](https://supabase.com/docs/reference/dart/auth-signup)، [Redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls)، [Email templates](https://supabase.com/docs/guides/auth/auth-email-templates).
