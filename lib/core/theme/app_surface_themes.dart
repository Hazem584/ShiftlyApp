import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_dimensions.dart';
import 'package:shiftly/core/theme/app_palette.dart';

CardThemeData buildCardTheme(AppPalette colors) => CardThemeData(
  color: colors.surface,
  elevation: 0,
  margin: EdgeInsets.zero,
  shape: RoundedRectangleBorder(
    side: BorderSide(color: colors.borderColor),
    borderRadius: BorderRadius.circular(AppRadii.l),
  ),
);

ChipThemeData buildChipTheme(AppPalette colors) => ChipThemeData(
  backgroundColor: colors.field,
  selectedColor: colors.selected,
  disabledColor: colors.field,
  checkmarkColor: colors.ink,
  iconTheme: IconThemeData(color: colors.ink),
  secondaryLabelStyle: TextStyle(
    color: colors.ink,
    fontFamily: 'Cairo',
    fontWeight: FontWeight.w700,
    fontSize: 12,
  ),
  side: BorderSide(color: colors.borderColor),
  labelStyle: TextStyle(
    color: colors.ink,
    fontFamily: 'Cairo',
    fontWeight: FontWeight.w700,
    fontSize: 12,
  ),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
);

DialogThemeData buildDialogTheme(AppPalette colors) => DialogThemeData(
  backgroundColor: colors.surface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadii.l),
  ),
);

SnackBarThemeData buildSnackBarTheme(ColorScheme colorScheme) =>
    SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colorScheme.inverseSurface,
      contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.m),
      ),
    );

BottomSheetThemeData buildBottomSheetTheme(AppPalette colors) =>
    BottomSheetThemeData(
      backgroundColor: colors.surface,
      showDragHandle: true,
      dragHandleColor: colors.borderColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.xl),
        ),
      ),
      clipBehavior: Clip.antiAlias,
    );
