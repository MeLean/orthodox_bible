import 'dart:io';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppLocalization extends EasyLocalization {
  static const appLocales = [
    Locale('bg', 'BG'),
    //TODO uncomment below when english version is available in the BE
    //Locale('en', 'US'),
  ];

  static String _localeCode = appLocales.first.languageCode;

  static void applySystemLocaleOrDefault(BuildContext context) {
    changeLocaleByTextOrDefault(
        context, _extractCodeFromLocaleName(Platform.localeName));
  }

  static String getLocaleCode() {
    return _localeCode;
  }

  static void changeLocaleByTextOrDefault(
    BuildContext context,
    String langStr,
  ) async {
    var locale = appLocales.first;

    for (var appLocale in appLocales) {
      if (appLocale.languageCode.toLowerCase() == langStr.toLowerCase()) {
        locale = appLocale;
        break;
      }
    }

    _localeCode = locale.languageCode;
    await context.setLocale(locale);
  }

  static String _extractCodeFromLocaleName(String localeName) =>
      localeName.split('_')[0];

  AppLocalization({
    Key? key,
    required child,
  }) : super(
          key: key,
          child: child,
          supportedLocales: appLocales,
          fallbackLocale: appLocales.first,
          path: 'assets/translations',
        );
}
