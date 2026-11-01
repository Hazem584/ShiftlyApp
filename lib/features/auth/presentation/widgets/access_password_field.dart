import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../design/access_field.dart';

class AccessPasswordField extends StatefulWidget {
  const AccessPasswordField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.validator,
    this.last = false,
    this.onSubmitted,
    this.hint,
    this.fieldKey,
    super.key,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled, last;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final Key? fieldKey;
  @override
  State<AccessPasswordField> createState() => _AccessPasswordFieldState();
}

class _AccessPasswordFieldState extends State<AccessPasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) => AccessField(
    label: widget.label,
    child: TextFormField(
      key: widget.fieldKey,
      controller: widget.controller,
      enabled: widget.enabled,
      textDirection: TextDirection.ltr,
      obscureText: _obscure,
      textInputAction: widget.last
          ? TextInputAction.done
          : TextInputAction.next,
      autofillHints: const [AutofillHints.newPassword],
      onFieldSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hint,
        suffixIcon: IconButton(
          tooltip: context.tr(_obscure ? 'Show password' : 'Hide password'),
          onPressed: widget.enabled
              ? () => setState(() => _obscure = !_obscure)
              : null,
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: widget.validator,
    ),
  );
}
