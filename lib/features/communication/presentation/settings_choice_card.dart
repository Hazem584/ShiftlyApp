import 'package:flutter/material.dart';

class SettingsChoiceCard extends StatelessWidget {
  const SettingsChoiceCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String title, subtitle;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Semantics(
      selected: selected,
      button: true,
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Icon(
            selected ? Icons.check : Icons.radio_button_unchecked,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          onTap: onTap,
        ),
      ),
    ),
  );
}
