import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    required this.buttonKey,
    required this.label,
    required this.loading,
    required this.onSubmit,
    super.key,
  });
  final Key buttonKey;
  final String label;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => FilledButton(
    key: buttonKey,
    onPressed: loading ? null : onSubmit,
    child: loading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Text(context.tr(label)),
  );
}
