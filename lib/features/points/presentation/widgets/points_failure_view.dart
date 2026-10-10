import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/points/presentation/cubit/points_cubit.dart';

class PointsFailureView extends StatelessWidget {
  const PointsFailureView({required this.message, super.key});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: context.read<PointsCubit>().load,
            icon: const Icon(Icons.refresh),
            label: Text(context.tr('Try again')),
          ),
        ],
      ),
    ),
  );
}
