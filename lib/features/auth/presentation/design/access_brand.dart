import 'package:flutter/material.dart';
import 'package:shiftly/core/widgets/brand_logo.dart';

class AccessBrand extends StatelessWidget {
  const AccessBrand({super.key});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const BrandLogo(size: 56),
      const SizedBox(width: 14),
      Text(
        'Shiftly',
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontSize: 27),
      ),
    ],
  );
}
