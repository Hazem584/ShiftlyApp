import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/surface_card.dart';

class AttendanceItem {
  const AttendanceItem({
    required this.day,
    required this.weekday,
    required this.checkIn,
    required this.checkOut,
    required this.hours,
    required this.location,
    this.status = 'Present',
  });
  final String day;
  final String weekday;
  final String checkIn;
  final String checkOut;
  final String hours;
  final String location;
  final String status;
}

class AttendanceRecordsList extends StatelessWidget {
  const AttendanceRecordsList({required this.records, super.key});
  final List<AttendanceItem> records;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Recent Attendance', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.s),
      for (final record in records) ...[
        _AttendanceRecordCard(record: record),
        const SizedBox(height: 10),
      ],
    ],
  );
}

class _AttendanceRecordCard extends StatelessWidget {
  const _AttendanceRecordCard({required this.record});
  final AttendanceItem record;

  @override
  Widget build(BuildContext context) {
    final isLeave = record.status != 'Present';
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Text(
                  record.day,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Text(
                  'Jan',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.weekday,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  'In: ${record.checkIn}   Out: ${record.checkOut}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        record.location,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.hours,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isLeave ? AppColors.purpleSoft : AppColors.successSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    record.status,
                    style: TextStyle(
                      color: isLeave
                          ? const Color(0xFF7A27A8)
                          : AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
