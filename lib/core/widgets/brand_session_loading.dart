import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/brand_logo.dart';

/// The same quiet branded frame is used while startup checks run invisibly.
class BrandSessionLoading extends StatelessWidget {
  const BrandSessionLoading({super.key});
  static const tagline = 'Your team. Every shift. In sync.';
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF101426) : const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandLogo(size: 108),
                const SizedBox(height: 24),
                Text(
                  context.tr(tagline),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: dark
                        ? const Color(0xFFB2BDD4)
                        : const Color(0xFF657087),
                    fontSize: 16,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
