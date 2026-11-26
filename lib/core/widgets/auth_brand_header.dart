import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/widgets/brand_logo.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    required this.title,
    required this.subtitle,
    this.showWordmark = false,
    super.key,
  });

  final String title, subtitle;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showWordmark) ...[
          Row(
            children: [
              const BrandLogo(size: 56),
              const SizedBox(width: 14),
              Text('Shiftly', style: text.headlineSmall),
            ],
          ),
          const SizedBox(height: 44),
        ],
        Text(
          title,
          style: text.headlineMedium?.copyWith(
            fontSize: showWordmark ? 38 : 28,
            fontWeight: FontWeight.w800,
            height: 1.16,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          subtitle,
          style: text.bodyLarge?.copyWith(
            color: AppPalette.of(context).textSecondary,
          ),
        ),
      ],
    );
  }
}
