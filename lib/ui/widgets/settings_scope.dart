import 'package:flutter/material.dart';
import '../view_models/settings_view_model.dart';

class SettingsScope extends InheritedNotifier<SettingsViewModel> {
  const SettingsScope({
    super.key,
    required SettingsViewModel notifier,
    required super.child,
  }) : super(notifier: notifier);

  static SettingsViewModel of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(scope != null, 'No SettingsScope found in context');
    return scope!.notifier!;
  }

  static SettingsViewModel? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    return scope?.notifier;
  }
}
