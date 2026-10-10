import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeSettings extends Equatable {
  const ThemeSettings({
    this.mode = ThemeMode.system,
    this.saving = false,
    this.saveFailed = false,
  });
  final ThemeMode mode;
  final bool saving;
  final bool saveFailed;
  @override
  List<Object?> get props => [mode, saving, saveFailed];
}
