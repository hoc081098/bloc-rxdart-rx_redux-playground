import 'package:flutter/material.dart';
import 'package:flutter_change_theme/generated/i18n.dart';
import 'package:flutter_change_theme/theme_model.dart';

class ThemesLocalesProvider {
  final List<ThemeModel> themes;
  final List<Locale> supportedLocales;
  final ThemeModel Function(String) findThemeByTitle;
  final Locale Function(String) findLocaleByLanguageCode;
  final String Function(String) getLanguageNameStringByLanguageCode;

  const ThemesLocalesProvider._(
    this.themes,
    this.findThemeByTitle,
    this.supportedLocales,
    this.findLocaleByLanguageCode,
    this.getLanguageNameStringByLanguageCode,
  );

  factory ThemesLocalesProvider() {
    final themes = <ThemeModel>[
      ThemeModel(
        ThemeData.dark(),
        'dark_theme',
        (s) => s.dark_theme,
      ),
      ThemeModel(
        ThemeData.light(),
        'light_theme',
        (s) => s.light_theme,
      ),
    ];

    const supportedLocaleNames = <String, String>{
      'en': 'English',
      'vi': 'Tiếng Việt'
    };

    return ThemesLocalesProvider._(
      themes,
      (title) => themes.firstWhere(
        (theme) => theme.themeId == title,
      ),
      S.delegate.supportedLocales,
      (code) => S.delegate.supportedLocales.firstWhere(
        (locale) => locale.languageCode == code,
      ),
      (code) => supportedLocaleNames[code],
    );
  }
}
