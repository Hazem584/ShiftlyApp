import 'package:flutter/material.dart';

class OnboardingPageContent {
  const OnboardingPageContent(this.title, this.description, this.icon);

  final String title, description;
  final IconData icon;
  static const pages = [
    OnboardingPageContent(
      'Know your next shift',
      'See your schedule, clock in with confidence, and keep track of your time.',
      Icons.schedule_rounded,
    ),
    OnboardingPageContent(
      'Make space for your day',
      'Plan personal tasks and get a reminder when it’s time to begin.',
      Icons.checklist_rounded,
    ),
    OnboardingPageContent(
      'Stay in the loop',
      'One place for team conversations and important updates.',
      Icons.forum_outlined,
    ),
  ];
}
