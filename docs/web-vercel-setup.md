# تشغيل Shiftly على الويب وربطه بـ Vercel

نسخة الويب تستخدم نفس الباك إند ونفس حسابات Supabase. مشروع Vercel الخاص بالواجهة مستقل عن مشروع الباك إند؛ لا تستبدل الباك إند بالواجهة.

## التشغيل المحلي على Windows

1. انسخ ملف المثال مرة واحدة:

```powershell
Set-Location 'E:\MY APPS\shiftly'
Copy-Item config/web.example.json config/web.local.json
```

2. افتح `config/web.local.json` واملأ القيم من إعدادات مشروعك:

| الاسم | القيمة |
| --- | --- |
| `SUPABASE_URL` | رابط مشروع Supabase، مثل `https://PROJECT.supabase.co` |
| `SUPABASE_PUBLISHABLE_KEY` | مفتاح Supabase العام **Publishable**، أو مفتاح `anon` القديم |
| `SHIFTLY_API_BASE_URL` | رابط الباك إند المنشور وينتهي بـ `/api/v1` |

لا تستخدم `service_role` أو مفتاح Firebase Admin هنا. إعدادات الواجهة تدخل في ملفات JavaScript التي ينزلها المتصفح. الملف المحلي مستبعد من Git.

3. في مشروع **الباك إند** على Vercel أضف إلى `CORS_ORIGINS` رابط التشغيل المحلي، مع الاحتفاظ بالروابط الموجودة. القيمة قائمة مفصولة بفواصل، مثل:

```text
http://localhost:5173,https://YOUR_FRONTEND.vercel.app
```

الرابط يكون بدون `/` في النهاية وبدون `/api/v1`. اعمل Redeploy للباك إند بعد تعديل المتغير.

4. شغّل:

```powershell
flutter pub get
flutter run -d chrome --web-port=5173 --dart-define-from-file=config/web.local.json
```

الموقع يفتح على `http://localhost:5173`. استخدم نفس العنوان بالضبط، لأن `127.0.0.1` و`localhost` أصلان مختلفان في CORS.

## ربط GitHub بـ Vercel

1. ارفع التغييرات إلى مستودع **ShiftlyApp** بالطريقة المعتادة.
2. في Vercel اختر **Add New → Project → Import** وحدد مستودع التطبيق.
3. اختَر **Framework Preset: Other**، و**Root Directory: جذر المستودع**. ملف `vercel.json` يحدد تلقائيًا:
   - Build Command: `bash scripts/build-vercel.sh`
   - Output Directory: `build/web`
   - لا تحتاج Install Command مخصصًا؛ سكربت البناء يشغّل `flutter pub get`.
4. أضف المتغيرات الثلاثة الموجودة في الجدول إلى **Environment Variables** في مشروع الواجهة، بالقيم الحقيقية، وفعّلها للـ Production وPreview المطلوبين.
5. اضغط **Deploy**. سكربت البناء يجهّز Flutter `3.47.6`، ويتحقق من الإعدادات، ثم يبني نسخة Release. أول بناء يحتاج وقتًا لتنزيل SDK.
6. بعد ظهور رابط الواجهة، أضفه إلى `CORS_ORIGINS` في مشروع **الباك إند** واعمل Redeploy للباك إند.
7. في Supabase افتح **Authentication → URL Configuration**:
   - **Site URL**: رابط الواجهة النهائي.
   - **Redirect URLs**: أضف `https://YOUR_FRONTEND.vercel.app/email-confirmed.html` و`http://localhost:5173/email-confirmed.html`، مع الاحتفاظ بروابطك الحالية.
   - تسجيل حساب جديد وإعادة إرسال التأكيد يعيدان المستخدم إلى صفحة تأكيد مستقلة، ثم يختار العودة لتسجيل الدخول.

كل Push إلى فرع Production المرتبط بـ Vercel يبني وينشر تلقائيًا. تغيير Environment Variables يحتاج Redeploy. إعدادات Vercel للواجهة والباك إند منفصلة.

روابط Preview تختلف من نشر لآخر. الباك إند يقبل أصولًا محددة؛ أضف أصل Preview المطلوب، أو استخدم دومين اختبار ثابت. لا تفتح CORS لكل المواقع. أضف رابط `/email-confirmed.html` لنفس موقع الاختبار في Supabase أيضًا. خطوات إعداد صفحة التأكيد وقبول دعوة مع عضوية موجودة في [دليل الحسابات والدعوات](account-verification-and-invitations.md).

## ما الذي جهّزناه؟

- تنقل سفلي على الموبايل، Navigation Rail على التابلت، وشريط جانبي موسع على الديسكتوب، مع مراعاة ارتفاع النافذة.
- مساحة محتوى محددة على الشاشات الكبيرة، وتوزيع أعمدة للداشبورد وقائمة الموظفين، وشاشة دخول مناسبة للديسكتوب، ودعم العربية وRTL.
- روابط نظيفة مثل `/attendance/reports`، مع SPA rewrites لتعمل الروابط المباشرة والـ Refresh على Vercel.
- تخزين الشات وملفات الإرسال في IndexedDB على المتصفح، مع استمرار تحقق صلاحيات الحساب والمجموعة ومسح بيانات الحساب السابق. نسخة الموبايل تستخدم التخزين الأصلي.
- رفع الصور، عرضها وتنزيلها، تسجيل صوت بصيغة يدعمها المتصفح، وتشغيل الرسائل الصوتية، وتنزيل Excel وPDF مباشرة.
- اسم الموقع وأيقونته وصفحة تحميل تحمل هوية Shiftly.

الكاميرا/الميكروفون والموقع يحتاجون سماح المستخدم وHTTPS؛ localhost مناسب للتطوير. جودة تحديد الموقع على الكمبيوتر تعتمد على الجهاز والمتصفح. حظر تخزين المتصفح أو مسح بيانات الموقع يؤثر على التخزين المحلي؛ هذه ليست نسخة تعمل بالكامل دون إنترنت.

إشعارات Firebase في الخلفية ما زالت خاصة بـ Android وiOS. شاشة الإشعارات متاحة على الويب، لكن Browser Push يحتاج إعداد Firebase Web وVAPID وService Worker منفصلًا.

## التحقق وحل المشكلات

```powershell
flutter analyze
flutter test
flutter test --platform chrome test/web_storage_test.dart test/web_responsive_test.dart
flutter build web --release --dart-define-from-file=config/web.local.json
```

لو اختبار Chrome على Windows مع Flutter 3.47.6 وقف عند التحميل وظهر 404 لملفات `/canvaskit/`، فده خلل في مسار خادم اختبارات Flutter على Windows. اختبارات التخزين والواجهة نفسها تعمل؛ يمكن تشغيل أمر اختبارات Chrome على Linux. بناء Release وتشغيل التطبيق العادي لا يستخدمان خادم الاختبارات.

- صفحة إعدادات ناقصة: راجع المتغيرات الثلاثة في مشروع الواجهة ثم Redeploy.
- الموقع يفتح لكن البيانات لا تظهر: راجع `SHIFTLY_API_BASE_URL` و`CORS_ORIGINS` في الباك إند؛ خطأ `CORS_ORIGIN_DENIED` يعني أن أصل الموقع لم يُضف.
- رابط تأكيد البريد يذهب لموقع آخر: راجع Redirect URLs وSite URL في Supabase.
- الـ Refresh يعطي 404: تأكد أن `vercel.json` في Root Directory الذي ينشره Vercel.
- تسجيل الصوت لا يبدأ: اسمح بالميكروفون، واستخدم HTTPS، وتأكد من دعم المتصفح للتسجيل.

مراجع: [Flutter web deployment](https://docs.flutter.dev/deployment/web)، [Vercel configuration](https://vercel.com/docs/project-configuration/vercel-json)، [Supabase redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls).

### فشل تنزيل Dart SDK على Vercel

لو السجل يظهر `End-of-central-directory signature not found` بعد تنزيل ملف حجمه مئات البايتات، فالملف ليس أرشيف Dart SDK صالحًا. السكربت الحالي ينزّل أرشيف Flutter Linux الرسمي كاملًا في مجلد مؤقت جديد لكل بناء، ويتحقق من SHA-256 ونسخة Flutter وDart قبل تشغيله. لا يعيد استخدام نسخة SDK الموجودة في كاش Vercel؛ تحميل SDK من جديد يزيد وقت البناء.

بعد رفع تعديل `scripts/build-vercel.sh` إلى GitHub:

1. افتح مشروع واجهة Shiftly في Vercel، ثم **Deployments**، وتأكد أن النشر يستخدم آخر commit الذي يحتوي على إصلاح السكربت.
2. عند إعادة النشر، اختَر **Redeploy** وألغِ **Use existing Build Cache** لهذه المحاولة لإزالة أثر الكاش القديم.
3. ينبغي أن يظهر `Verified Flutter 3.47.6 stable / Dart 3.13.5` قبل بناء التطبيق. لا تحتاج لتغيير إعدادات Supabase أو CORS بسبب هذا الخطأ.

مراجع: [أرشيف Flutter الرسمي](https://docs.flutter.dev/install/archive)، [إعادة النشر بدون كاش Vercel](https://vercel.com/docs/deployments/troubleshoot-a-build#managing-build-cache).
لو يظهر `fatal: detected dubious ownership` ثم يفشل التحقق من نسخة SDK، فـ Git لم يتمكن من قراءة بيانات Flutter بسبب ملكية الملفات المستخرجة. السكربت يستخدم الآن `tar --no-same-owner` ويحدد `safe.directory` لمجلد SDK المتحقق منه فقط، عبر إعدادات Git الخاصة بعملية البناء؛ لا تحتاج لإضافة متغير في Vercel أو تعطيل فحص النسخة. ارفع إصلاح السكربت وأعد النشر من آخر commit.
