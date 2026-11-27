import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class AttendanceSelfieViewer extends StatefulWidget {
  const AttendanceSelfieViewer({
    super.key,
    required this.workspaceId,
    required this.attendanceId,
  });
  final String workspaceId;
  final String attendanceId;

  @override
  State<AttendanceSelfieViewer> createState() => _AttendanceSelfieViewerState();
}

class _AttendanceSelfieViewerState extends State<AttendanceSelfieViewer> {
  Future<Uint8List>? _future;

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<Dio>()) {
      _future = getIt<Dio>()
          .get<List<int>>(
            '/workspaces/${widget.workspaceId}/attendance/${widget.attendanceId}/selfie',
            options: Options(responseType: ResponseType.bytes),
          )
          .then((r) => Uint8List.fromList(r.data ?? const []));
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Clock-in verification selfie'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          FutureBuilder<Uint8List>(
            future: future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
                return Text(context.tr('Could not load selfie photo.'));
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  snap.data!,
                  height: 220,
                  width: 220,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
