import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';

class EmployeeDetailsLoading extends StatelessWidget {
  const EmployeeDetailsLoading({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(18),
    child: Column(
      children: [
        Container(
          height: 245,
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(AppRadii.l),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(AppRadii.l),
          ),
        ),
      ],
    ),
  );
}
