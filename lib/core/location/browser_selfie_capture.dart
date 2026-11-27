import 'dart:js_interop';

import 'package:image_picker/image_picker.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/location/native_selfie_capture.dart' as native;

@JS('eval')
external JSAny? _jsEval(JSString script);

const _frontCameraOverlayScript = r'''
(() => new Promise(async (resolve) => {
  let stream = null;
  const host = document.createElement('div');
  host.style.cssText = 'position:fixed;inset:0;z-index:999999;background:rgba(10,14,26,0.94);display:flex;flex-direction:column;align-items:center;justify-content:center;padding:16px;color:#fff;font-family:Cairo,sans-serif;text-align:center;';
  host.innerHTML = `
    <div style="max-width:420px;width:100%;background:#161c2e;border-radius:20px;padding:18px;box-shadow:0 16px 40px rgba(0,0,0,0.5);">
      <div style="font-size:17px;font-weight:700;margin-bottom:6px;">التحقق بالوجه (الكاميرا الأمامية فقط)</div>
      <div style="font-size:13px;color:#cbd5e1;line-height:1.5;margin-bottom:12px;">
        • وجّه وجهك مباشرة للكاميرا داخل الإطار<br/>
        • بدون نظارة شمسية أو كمامة أو غطاء للرأس/الوجه<br/>
        • تأكد من إضاءة واضحة على الوجه بالكامل
      </div>
      <div style="position:relative;width:100%;aspect-ratio:1/1;background:#000;border-radius:16px;overflow:hidden;margin-bottom:14px;">
        <video id="shiftly-selfie-video" autoplay playsinline muted style="width:100%;height:100%;object-fit:cover;transform:scaleX(-1);"></video>
        <div style="position:absolute;inset:14% 20%;border:2.5px dashed #6ee7b7;border-radius:50%;pointer-events:none;box-shadow:0 0 0 999px rgba(0,0,0,0.32);"></div>
      </div>
      <div style="display:flex;gap:10px;justify-content:center;">
        <button id="shiftly-selfie-cancel" type="button" style="flex:1;padding:12px;border-radius:12px;border:1px solid #475569;background:transparent;color:#fff;font-family:inherit;font-size:14px;cursor:pointer;">إلغاء</button>
        <button id="shiftly-selfie-snap" type="button" style="flex:2;padding:12px;border-radius:12px;border:none;background:#6ee7b7;color:#0f172a;font-family:inherit;font-weight:700;font-size:14px;cursor:pointer;">التقاط سيلفي</button>
      </div>
    </div>`;
  document.body.appendChild(host);
  const cleanup = (val) => {
    if (stream) stream.getTracks().forEach((t) => t.stop());
    host.remove();
    resolve(val);
  };
  host.querySelector('#shiftly-selfie-cancel').onclick = () => cleanup('');
  try {
    try {
      stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: { exact: 'user' }, width: { ideal: 640 }, height: { ideal: 640 } }, audio: false });
    } catch (_) {
      stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user', width: { ideal: 640 }, height: { ideal: 640 } }, audio: false });
    }
    const video = host.querySelector('#shiftly-selfie-video');
    video.srcObject = stream;
    await video.play();
    host.querySelector('#shiftly-selfie-snap').onclick = () => {
      const c = document.createElement('canvas');
      c.width = 480; c.height = 480;
      const ctx = c.getContext('2d');
      ctx.translate(480, 0); ctx.scale(-1, 1);
      ctx.drawImage(video, 0, 0, 480, 480);
      const dataUrl = c.toDataURL('image/jpeg', 0.72);
      cleanup(dataUrl.split(',')[1] || '');
    };
  } catch (_) {
    cleanup('__ERROR__');
  }
}))()
''';

Future<String?> platformCaptureFrontCameraSelfieBase64({
  required bool requiredForPunch,
  ImagePicker? picker,
}) async {
  if (picker != null) {
    return native.platformCaptureFrontCameraSelfieBase64(
      requiredForPunch: requiredForPunch,
      picker: picker,
    );
  }
  try {
    final promise =
        _jsEval(_frontCameraOverlayScript.toJS) as JSPromise<JSString?>;
    final result = (await promise.toDart)?.toDart ?? '';
    if (result == '__ERROR__') {
      throw const ApiException(
        code: 'SELFIE_CAMERA_UNAVAILABLE',
        message:
            'Allow camera access and take a front-camera selfie to clock in.',
        kind: FailureKind.validation,
      );
    }
    if (result.isEmpty) {
      if (requiredForPunch) {
        throw const ApiException(
          code: 'SELFIE_REQUIRED',
          message: 'Take a front-camera selfie to clock in at this workspace.',
          kind: FailureKind.validation,
        );
      }
      return null;
    }
    return result;
  } on ApiException {
    rethrow;
  } catch (_) {
    if (requiredForPunch) {
      throw const ApiException(
        code: 'SELFIE_CAMERA_UNAVAILABLE',
        message:
            'Allow camera access and take a front-camera selfie to clock in.',
        kind: FailureKind.validation,
      );
    }
    return null;
  }
}
