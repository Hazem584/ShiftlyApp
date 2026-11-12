import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/utils/workspace_time.dart';

String employeeTime(BuildContext context, DateTime? value, String timezone) =>
    value == null
    ? '—'
    : DateFormat.Hm(Localizations.localeOf(context).toString())
          .format(WorkspaceTime.inWorkspace(value, timezone));
