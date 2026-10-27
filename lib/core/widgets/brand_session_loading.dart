import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/brand_logo.dart';

/// The same quiet branded frame is used while startup checks run invisibly.
class BrandSessionLoading extends StatelessWidget {
  const BrandSessionLoading({super.key});
  static const tagline = 'Your team. Every shift. In sync.';
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B1014),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(size: 156),
              const SizedBox(height: 24),
              Text(
                context.tr(tagline),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Color(0xFFA0B4BF),
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
