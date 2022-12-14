import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/storage_manager.dart';
import 'own_theme_fields.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

ThemeManager themeManager = ThemeManager();

class ThemeManager with ChangeNotifier {
  final ThemeData lightTheme = ThemeData.light().copyWith(useMaterial3: true)..addOwn(const OwnThemeFields());
  final ThemeData darkTheme = ThemeData.dark().copyWith(useMaterial3: true)
    ..addOwn(const OwnThemeFields(onSuccess: Colors.black, onWarning: Colors.black));

  late ThemeMode currentThemeMode;

  Future<void> loadTheme() async {
    await StorageManager.readData('themeMode').then((value) {
      switch (value) {
        case 'system':
          currentThemeMode = ThemeMode.system;
          break;
        case 'light':
          currentThemeMode = ThemeMode.light;
          break;
        case 'dark':
          currentThemeMode = ThemeMode.dark;
          break;
        default:
          currentThemeMode = ThemeMode.system;
      }
      notifyListeners();
    });
  }

  void setTheme(ThemeMode? value) {
    if (value == null) return;

    currentThemeMode = value;
    StorageManager.saveData('themeMode', value.name);
    notifyListeners();
  }
}

extension ThemeModeName on ThemeMode {
  String getName(BuildContext context) {
    switch (this) {
      case ThemeMode.system:
        return S.of(context).pageAccountThemesSystem;
      case ThemeMode.light:
        return S.of(context).pageAccountThemesLight;
      case ThemeMode.dark:
        return S.of(context).pageAccountThemesDark;
    }
  }
}
