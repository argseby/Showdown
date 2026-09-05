import 'package:flutter/widgets.dart';

/// True while any text field owns keyboard focus (shortcuts are suppressed).
bool isTextFieldFocused() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return false;
  if (ctx.widget is EditableText) return true;
  return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
}

/// Moves focus away from any text field back to the table.
void unfocusTextField() {
  FocusManager.instance.primaryFocus?.unfocus();
}
