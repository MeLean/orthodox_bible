import 'package:bulgarian.orthodox.bible/app/localization.dart';
import 'package:bulgarian.orthodox.bible/app/routes.dart';
import 'package:bulgarian.orthodox.bible/screens/splash/pasages_repo.dart';
import 'package:flutter/material.dart';

import '../../app/mixins/passage_manager.dart';
import '../../app/mixins/loading.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with PassageManager, LoadingIndicatorProvider {
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _initApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _isLoading
            ? getLoadingIndicator()
            : const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("DONE"),
              ));
  }

  void _initApp() async {
    AppLocalization.applySystemLocaleOrDefault(context);

    if (await arePassagesLoaded()) {
      _goToHomeScreen();
    } else {
      _loadPassages();
    }
  }

  void _goToHomeScreen() {
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.home, (route) => false);
  }

  void _loadPassages() {
    PassagesRepo()
        .loadAndCachePassages()
        .then(
          (_) => _goToHomeScreen(),
        )
        .onError(
          (error, stackTrace) => debugPrint(error.toString()),
        );
  }
}
