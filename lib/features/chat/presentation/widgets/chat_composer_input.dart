import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class ChatComposerInput extends StatelessWidget {
  const ChatComposerInput({
    super.key,
    required this.controller,
    required this.enabled,
    required this.canSend,
    required this.sendOnEnter,
    required this.hint,
    required this.onChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled, canSend, sendOnEnter;
  final String hint;
  final VoidCallback onChanged;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) => Focus(
    onKeyEvent: (_, event) {
      if (!sendOnEnter ||
          (event.logicalKey != LogicalKeyboardKey.enter &&
              event.logicalKey != LogicalKeyboardKey.numpadEnter) ||
          HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isAltPressed ||
          HardwareKeyboard.instance.isMetaPressed ||
          !controller.value.composing.isCollapsed) {
        return KeyEventResult.ignored;
      }
      if (event is KeyDownEvent) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          if (enabled) {
            final value = controller.value;
            final selection = value.selection.isValid
                ? value.selection
                : TextSelection.collapsed(offset: value.text.length);
            final updated = value.text.replaceRange(
              selection.start,
              selection.end,
              '\n',
            );
            if (updated.length <= 4000) {
              controller.value = TextEditingValue(
                text: updated,
                selection: TextSelection.collapsed(offset: selection.start + 1),
              );
              onChanged();
            }
          }
        } else if (canSend) {
          onSend();
        }
        return KeyEventResult.handled;
      }
      return event is KeyRepeatEvent
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    },
    child: TextField(
      key: const Key('chat-message-input'),
      controller: controller,
      enabled: enabled,
      maxLength: 4000,
      minLines: 1,
      maxLines: 5,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      decoration: InputDecoration(
        hintText: context.tr(hint),
        counterText: '',
        border: InputBorder.none,
      ),
      onChanged: (_) => onChanged(),
      onSubmitted: (_) {
        if (canSend) onSend();
      },
    ),
  );
}
