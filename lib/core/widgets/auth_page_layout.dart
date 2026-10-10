import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/widgets/brand_logo.dart';

class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 1100 || constraints.maxHeight < 600) {
        return child;
      }
      return Material(
        color: AppColors.canvas,
        child: Row(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.ink, Color(0xFF34314D)],
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BrandLogo(size: 88),
                        const SizedBox(height: 32),
                        const Text(
                          'Shiftly',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('Your team. One workspace.'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.tr(
                            'Manage shifts, attendance and team conversations in one place.',
                          ),
                          style: const TextStyle(
                            color: Color(0xFFDDDBE8),
                            fontSize: 17,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      );
    },
  );
}
