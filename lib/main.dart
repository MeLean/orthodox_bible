import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'app/localization.dart';
import 'package:wakelock/wakelock.dart';

import 'app/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    AppLocalization(child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Wakelock.enable();
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      debugShowCheckedModeBanner: false,
      routes: AppRoutes.getRouteDestinations(context),
    );
  }
}
