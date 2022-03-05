import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppLocalization extends EasyLocalization {
  static const appLocales = [
    Locale('bg', 'BG'),
  ];

  static void changeLocale(
    BuildContext context,
    Locale locale,
  ) async {
    await context.setLocale(locale);
  }

  static void changeByText(
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

    await context.setLocale(locale);
  }

  static void changeLocaleByIndex(
    BuildContext context,
    int index,
  ) async {
    if (index >= appLocales.length || index < 0) {
      return;
    }

    return changeLocale(context, appLocales[index]);
  }

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
