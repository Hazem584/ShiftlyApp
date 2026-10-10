import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';

class NativeReportFileDelivery implements ReportFileDelivery {
  @override
  Future<void> deliver(
    ReportExportFile file, {
    required ReportShareOrigin origin,
    required bool Function() isCurrent,
  }) async {
    if (!isCurrent()) return;
    final desktop =
        !kIsWeb &&
        const [
          TargetPlatform.windows,
          TargetPlatform.linux,
          TargetPlatform.macOS,
        ].contains(defaultTargetPlatform);
    final data = XFile.fromData(
      file.bytes,
      mimeType: file.mimeType,
      name: file.name,
    );
    if (desktop) {
      final location = await getSaveLocation(
        suggestedName: file.name,
        acceptedTypeGroups: [
          XTypeGroup(
            label: file.name.endsWith('.pdf') ? 'PDF' : 'Excel',
            extensions: [file.name.split('.').last],
          ),
        ],
      );
      if (location == null || !isCurrent()) return;
      await data.saveTo(location.path);
      return;
    }
    if (!isCurrent()) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [data],
        fileNameOverrides: [file.name],
        sharePositionOrigin: Rect.fromLTWH(
          origin.x,
          origin.y,
          origin.width,
          origin.height,
        ),
      ),
    );
  }
}
