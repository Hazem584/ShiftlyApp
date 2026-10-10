import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/widgets/brand_logo.dart';

class WorkspaceBrand extends StatelessWidget {
  const WorkspaceBrand({
    this.extended = false,
    this.employee = false,
    super.key,
  });
  final bool extended;
  final bool employee;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    child: extended
        ? SizedBox(
            width: 192,
            child: Row(
              children: [
                const BrandLogo(size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shiftly',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        context.tr(
                          employee ? 'Employee workspace' : 'Manager workspace',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Icon(
            Icons.layers_rounded,
            color: AppPalette.of(context).orange,
            size: 32,
          ),
  );
}
