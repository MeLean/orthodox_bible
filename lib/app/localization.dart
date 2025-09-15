import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppLocalization extends EasyLocalization {
  static const _appSupportedLocales = [
    Locale('bg', 'BG'),
    Locale('ka', 'GE'),
    Locale('ru', 'RU'),
  ];

  static final appDefaultLocale = _appSupportedLocales.first;

  static bool isLanguageCodeSupported(String? laguageCode) {
    if (laguageCode == null) return false;

    return _appSupportedLocales.any((e) => e.languageCode == laguageCode);
  }

  static List<String> getSupprotedLanguageCodes() {
    return _appSupportedLocales.map((e) => e.languageCode).toList();
  }

  static Future<void> applyLocaleByLanguageCodeOrDefault(
    BuildContext context,
    String langStr,
  ) async {
    var locale = appDefaultLocale;

    for (var appSupportedLocale in _appSupportedLocales) {
      if (appSupportedLocale.languageCode.toLowerCase() == langStr.toLowerCase()) {
        locale = appSupportedLocale;
        break;
      }
    }

    return await context.setLocale(locale);
  }

  static String getCurrentLanguageCode(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }

  AppLocalization({
    Key? key,
    required child,
  }) : super(
          key: key,
          child: child,
          supportedLocales: _appSupportedLocales,
          fallbackLocale: appDefaultLocale,
          path: 'assets/translations',
        );
}
