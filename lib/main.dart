import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app/localization.dart';

import 'app/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    AppLocalization(
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    WakelockPlus.enable();
    return ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, ThemeMode currentMode, __) {
          return MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            debugShowCheckedModeBanner: false,
            routes: AppRoutes.getRouteDestinations(context),
            darkTheme: ThemeData.dark(),
            themeMode: currentMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSwatch().copyWith(
                primary: const Color.fromARGB(255, 0, 38, 99),
                secondary: const Color.fromARGB(255, 86, 147, 245),
                brightness: Brightness.light,
              ),
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
          );
        });
  }
}

class DarkLightSwitcher with ChangeNotifier {
  bool isDarkMode = true;

  void toggleMode() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}
