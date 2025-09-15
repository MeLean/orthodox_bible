import 'dart:async';

import 'package:bulgarian.orthodox.bible/app/mixins/cache.dart';
import 'package:bulgarian.orthodox.bible/app_loger.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'app/localization.dart';

import 'app/routes.dart';
import 'themes/app_themes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() {
  FlutterError.onError = (details) {
    AppLogger.info("Flutter error: ${details.exception}\n${details.stack}");
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppLogger.info("🚀 Step 1: Widgets initialized");

    AppLogger.info("🌍 Step 2: Starting EasyLocalization initialization...");
    try {
      await EasyLocalization.ensureInitialized();
      AppLogger.info("✅ Step 2: EasyLocalization initialized successfully");
    } catch (e, stacktrace) {
      AppLogger.error("Step 2: EasyLocalization failed: $e\n$stacktrace");
    }

    AppLogger.info("🔥 Step 3: Starting Firebase initialization...");
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          AppLogger.error("Step 3: Firebase initialization timeout!");
          throw Exception("Firebase timeout");
        },
      );
      AppLogger.info("✅ Step 3: Firebase initialized successfully");
    } catch (e, stacktrace) {
      AppLogger.error("Step 3: Firebase initialization failed: $e\n$stacktrace");
    }

    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FirebaseCrashlytics.instance.log("Crashlytics initialized OK");
    } catch (e, stack) {
      AppLogger.error("Crashlytics init failed: $e\n$stack");
    }

    AppLogger.info("🚀 Step 4: Running MyApp...");
    runApp(AppLocalization(child: const MyApp()));
    AppLogger.info("🎉 Step 5: App started successfully!");
  }, (error, stack) {
    AppLogger.error("UNHANDLED ERROR: $error\n$stack");
  });
}

class MyApp extends StatelessWidget with AppCache {
  const MyApp({Key? key}) : super(key: key);

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    AppLogger.info("Building MyApp...");
    WakelockPlus.enable();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        AppLogger.info("🎨 Applying theme: $currentMode");

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
