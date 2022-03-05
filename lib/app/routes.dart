import 'package:bulgarian.orthodox.bible/screens/info/info_screen.dart';
import 'package:flutter/material.dart';

import '../screens/home/home_screen.dart';
import '../screens/navigation/navigation_screen.dart';

abstract class AppRoutes {
  static const String home = '/';
  static const String info = '/info';
  static const String navigation = '/navigation';

  static Map<String, Widget Function(BuildContext)> getRouteDestinations(
      BuildContext ctx) {
    return <String, Widget Function(BuildContext)>{
      AppRoutes.home: (ctx) => const HomeScreen(),
      AppRoutes.info: (ctx) => const InfoScreen(),
      AppRoutes.navigation: (ctx) => const NavigationScreen(),
    };
  }
}
