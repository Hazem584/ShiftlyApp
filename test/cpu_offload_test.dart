import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/chat/data/cache/chat_media_inspection.dart';
import 'package:shiftly/features/reports/data/attendance_report_exporter.dart';
import 'package:shiftly/features/reports/data/report_preparation.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';

import 'support/report_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'large media inspection matches SHA-256 and detects same-size corruption',
    () async {
      final bytes = Uint8List(1024 * 1024);
      bytes.setRange(0, 3, [0xff, 0xd8, 0xff]);
      bytes.setRange(bytes.length - 2, bytes.length, [0xff, 0xd9]);
      ChatMediaInspection input() => ChatMediaInspection(
        bytes: bytes,
        type: 'IMAGE',
        mimeType: 'image/jpeg',
        sizeBytes: bytes.length,
      );
      final expected = sha256.convert(bytes).toString();
      expect(await inspectChatMedia(input()), expected);
      bytes[500] = 42;
      expect(await inspectChatMedia(input()), isNot(expected));
      bytes[0] = 0;
      expect(await inspectChatMedia(input()), isNull);
    },
  );

  test(
    'small media validates without changing MIME, length or duration rules',
    () async {
      final bytes = Uint8List.fromList('OggS'.codeUnits);
      expect(
        await inspectChatMedia(
          ChatMediaInspection(
            bytes: bytes,
            type: 'VOICE',
            mimeType: 'audio/ogg',
            sizeBytes: 4,
            durationMs: 1000,
          ),
        ),
        isNotNull,
      );
      expect(
        await inspectChatMedia(
          ChatMediaInspection(
            bytes: bytes,
            type: 'VOICE',
            mimeType: 'audio/ogg',
            sizeBytes: 4,
          ),
        ),
        isNull,
      );
      expect(
        await inspectChatMedia(
          ChatMediaInspection(
            bytes: bytes,
            type: 'IMAGE',
            mimeType: 'image/jpeg',
            sizeBytes: 4,
          ),
        ),
        isNull,
      );
      expect(
        await inspectChatMedia(
          ChatMediaInspection(
            bytes: bytes,
            type: 'DOCUMENT',
            mimeType: 'text/plain',
            fileName: '../bad.txt',
            sizeBytes: 4,
          ),
        ),
        isNull,
      );
      expect(
        await inspectChatMedia(
          ChatMediaInspection(
            bytes: bytes,
            type: 'DOCUMENT',
            mimeType: 'text/plain',
            fileName: 'notes.txt',
            sizeBytes: 5,
          ),
        ),
        isNull,
      );
    },
  );

  test('large report preparation preserves totals, sorting and historical employees', () async {
    final records = List.generate(
      300,
      (i) => reportRecord(
        id: 'r-$i',
        employeeId: i.isEven ? 'employee' : 'former',
        name: i.isEven ? 'أحمد' : 'Former employee',
        work: 60,
        clockIn: DateTime.utc(2026, 10, 1, 7).add(Duration(minutes: 300 - i)),
      ),
    );
    final originalFirst = records.first.id;
    final base = fixtureReport(records: records);
    final prepared = await prepareAttendanceReport(
      ReportPreparation(
        workspaceId: base.workspaceId,
        workspaceName: base.workspaceName,
        timezone: base.timezone,
        range: base.range,
        generatedAt: base.generatedAt,
        employees: base.employees,
        records: records,
      ),
    );
    expect(prepared.totalsFor(null).workMinutes, 300 * 60);
    expect(prepared.totalsFor('former').workMinutes, 150 * 60);
    expect(prepared.employees.any((e) => e.id == 'former'), isTrue);
    expect(prepared.records.first.id, 'r-299');
    expect(records.first.id, originalFirst);
    expect(prepared.range.label, base.range.label);
    expect(prepared.timezone, 'Africa/Cairo');
  });

  test(
    'export snapshots UI-owned labels and keeps event loop responsive',
    () async {
      // A ReceivePort cannot cross an isolate boundary. A widget-owned translation
      // closure could capture similar native state; only its string results may travel.
      final owner = ReceivePort();
      addTearDown(owner.close);
      final labels = ReportLabels((key) {
        if (owner.sendPort.hashCode == -1) throw StateError('Unreachable');
        return key;
      });
      final report = fixtureReport(
        records: List.generate(600, (i) => reportRecord(id: 'record-$i')),
      );
      var ticks = 0;
      final timer = Timer.periodic(
        const Duration(milliseconds: 1),
        (_) => ticks++,
      );
      late ReportExportFile file;
      try {
        file = await AttendanceReportExporter().create(
          report,
          format: ReportFileFormat.excel,
          strings: labels,
        );
      } finally {
        timer.cancel();
      }
      expect(ticks, greaterThan(0));
      expect(file.bytes.take(2), [0x50, 0x4b]);
      final workbook = Excel.decodeBytes(file.bytes);
      expect(workbook.tables['Details']!.rows.length, 601);
      expect(workbook.tables.keys, ['Summary', 'Details']);
    },
  );

  test('large document hashing uses the same bounded snapshot', () async {
    final bytes = Uint8List.fromList(
      utf8.encode('sample,'.padRight(300000, 'a')),
    );
    final digest = await inspectChatMedia(
      ChatMediaInspection(
        bytes: bytes,
        type: 'DOCUMENT',
        mimeType: 'text/csv',
        fileName: 'records.csv',
        sizeBytes: bytes.length,
      ),
    );
    expect(digest, sha256.convert(bytes).toString());
  });
}
