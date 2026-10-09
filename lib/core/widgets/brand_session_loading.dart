import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';

import 'brand_logo.dart';

class BrandSessionLoading extends StatelessWidget {
  const BrandSessionLoading({super.key});
  @override
  Widget build(BuildContext context) {
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? AppColors.ink : AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandLogo(size: 120),
                const SizedBox(height: 24),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'Getting Shiftly ready',
                    style: TextStyle(
                      color: dark ? Colors.white : AppColors.ink,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CircularProgressIndicator(
                  color: dark ? Colors.white : AppColors.ink,
                  semanticsLabel: 'Restoring your session',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
