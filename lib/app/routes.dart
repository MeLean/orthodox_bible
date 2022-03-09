import 'package:bulgarian.orthodox.bible/screens/info/info_screen.dart';
import 'package:bulgarian.orthodox.bible/screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';

import '../screens/home/home_screen.dart';
import '../screens/navigation/navigation_screen.dart';

abstract class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String info = '/info';
  static const String navigation = '/navigation';

  static Map<String, Widget Function(BuildContext)> getRouteDestinations(
      BuildContext ctx) {
    return <String, Widget Function(BuildContext)>{
      AppRoutes.splash: (ctx) => const SplashScreen(),
      AppRoutes.home: (ctx) => const HomeScreen(),
      AppRoutes.info: (ctx) => const InfoScreen(),
      AppRoutes.navigation: (ctx) => const NavigationScreen(),
    };
  }
}
