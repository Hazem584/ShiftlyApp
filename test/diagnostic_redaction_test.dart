import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/monitoring/diagnostic_redaction.dart';
import 'package:shiftly/core/monitoring/safe_exception_summary.dart';

void main() {
  final cases = jsonDecode(
    File('test/fixtures/diagnostic-redaction-cases.json').readAsStringSync(),
  ) as List;
  for (final entry in cases) {
    final row = Map<String, Object?>.from(entry as Map);
    test('redacts ${row['name']}', () {
      final input = row['input'] as String;
      final secrets = row['secrets'] as List;
      final output = redactDiagnostic(input, 8000);
      for (final secret in secrets) {
        expect(output, isNot(contains(secret as String)));
      }
      if (row.containsKey('expected')) {
        expect(jsonDecode(output), row['expected']);
      }
      if (secrets.isEmpty) {
        expect(output, input);
      }
      expect(redactDiagnostic(output, 8000), output);
    });
  }
  test('sanitizes before truncation and bounds excessive input/depth', () {
    final input = jsonEncode({
      'password': 'truncation-secret-value',
      'status': 500,
    });
    for (var limit = 0; limit < input.length; limit++) {
      final output = redactDiagnostic(input, limit);
      expect(output.length, lessThanOrEqualTo(limit));
      expect(output, isNot(contains('truncation-secret')));
    }
    expect(
      redactDiagnostic('${'x' * 32769} password=oversize-secret-value', 2000),
      isNot(contains('oversize-secret')),
    );
    final deep =
        '${'{"safe":' * 50}{"password":"deep-secret-value"}${'}' * 50}';
    expect(redactDiagnostic(deep, 8000), isNot(contains('deep-secret-value')));
  });
  test('network exception reports omit request and response bodies', () {
    final options = RequestOptions(
      path: '/login',
      data: {'password': 'request-password-value'},
    );
    final error = DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 401,
        data: {'access_token': 'response-token-value'},
      ),
      error: 'raw-exception-secret-value',
      message: 'raw-message-secret-value',
      type: DioExceptionType.badResponse,
    );
    expect(
      diagnosticExceptionSummary(error),
      'DioException badResponse status=401',
    );
  });
  test('API exception reports send only status and a validated error code', () {
    expect(
      diagnosticExceptionSummary(
        const ApiException(
          message: 'raw-body-secret-value',
          statusCode: 403,
          code: 'FORBIDDEN',
        ),
      ),
      'ApiException status=403 code=FORBIDDEN',
    );
  });
  test('generic exception reports keep only a sanitized first line', () {
    final summary = diagnosticExceptionSummary(
      StateError('password=first-line-secret\nraw-payload-secret'),
    );
    expect(summary, isNot(contains('first-line-secret')));
    expect(summary, isNot(contains('raw-payload-secret')));
  });
}
