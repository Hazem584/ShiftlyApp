import 'package:flutter/material.dart';
import 'package:shiftly/core/widgets/access_screen.dart';

class ReleaseUpdateScreen extends StatelessWidget {
  const ReleaseUpdateScreen({
    required this.release,
    required this.launching,
    required this.launchFailed,
    required this.attemptedUpdate,
    required this.onUpdate,
    required this.onCheck,
    required this.onDefer,
    super.key,
  });

  final Map<String, dynamic> release;
  final bool launching, launchFailed, attemptedUpdate;
  final VoidCallback onUpdate, onCheck, onDefer;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return AccessScreen(
      title: release['required'] == true ? 'Update required' : 'App update',
      actions: [
        FilledButton(
          onPressed: launching ? null : onUpdate,
          child: Text(ar ? 'حدّث شيفتلي' : 'Update Shiftly'),
        ),
        TextButton(
          onPressed: onCheck,
          child: Text(ar ? 'إعادة التحقق من التحديث' : 'Check update again'),
        ),
        if (attemptedUpdate)
          Text(
            ar
                ? 'لو حساب المختبر أو الجهاز مش قادر يثبت الإصدار، تقدر تكمل مؤقتًا وتحاول لاحقًا.'
                : 'If your tester account or device cannot install this release, continue temporarily and retry later.',
          ),
        if (release['required'] != true || attemptedUpdate)
          TextButton(
            onPressed: onDefer,
            child: Text(
              release['required'] == true
                  ? (ar ? 'المتابعة مؤقتًا' : 'Continue temporarily')
                  : (ar ? 'لاحقًا' : 'Later'),
            ),
          ),
        if (release['required'] == true)
          Text(ar ? 'التحديث مطلوب للمتابعة.' : 'Update required to continue.'),
      ],
      children: [
        const Icon(Icons.system_update, size: 64),
        const SizedBox(height: 24),
        Text(
          ar
              ? (release['required'] == true
                    ? 'حدّث التطبيق للمتابعة'
                    : 'نسخة جديدة من شيفتلي جاهزة')
              : (release['required'] == true
                    ? 'Update to continue.'
                    : 'A fresh Shiftly is ready.'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text('${release['version']} (${release['build']})'),
        const SizedBox(height: 16),
        Text(release['message'] as String, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Text(
          ar
              ? 'هيفتح Firebase App Distribution لتنزيل الإصدار. التثبيت يحتاج موافقة الجهاز وحساب مختبر مصرح له.'
              : 'Opens Firebase App Distribution to download this release. Installation requires device approval and an authorized tester account.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (launchFailed)
          Text(
            ar
                ? 'تعذر فتح رابط التحديث. حاول مرة أخرى.'
                : 'Could not open the update link. Try again.',
          ),
      ],
    );
  }
}
