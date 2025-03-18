import 'package:bulgarian.orthodox.bible/app/mixins/cache.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app/localization.dart';

import 'app/routes.dart';
import 'themes/app_themes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    AppLocalization(
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget with AppCache {
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
          themeMode: currentMode,
          darkTheme: AppThemes.dark,
          theme: AppThemes.light,
        );
      },
    );
  }
}

class DarkLightSwitcher with ChangeNotifier {
  bool isDarkMode = true;

  void toggleMode() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }
}
