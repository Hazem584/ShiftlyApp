import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/app_shimmer.dart';

class EmployeesLoadingView extends StatelessWidget {
  const EmployeesLoadingView({super.key});
  @override
  Widget build(BuildContext context) => AppShimmer(
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: 92,
        decoration: BoxDecoration(
          color: AppPalette.of(context).field,
          borderRadius: BorderRadius.circular(AppRadii.l),
        ),
      ),
    ),
  );
}
