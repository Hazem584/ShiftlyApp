import 'package:flutter/material.dart';
import 'package:shiftly/core/widgets/feature_placeholder.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Profile',
      icon: Icons.manage_accounts_outlined,
      message: 'Manager account and workplace settings will be available here.',
    );
  }
}
