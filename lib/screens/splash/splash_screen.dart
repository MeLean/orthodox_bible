import 'dart:io';

import 'package:bulgarian.orthodox.bible/app/localization.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/loading.dart';
import 'package:bulgarian.orthodox.bible/app/routes.dart';
import 'package:bulgarian.orthodox.bible/screens/splash/pasages_repo.dart';
import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';

import '../../api/rest_client.dart';
import '../../app/mixins/passage_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with PassageManager, LoadingIndicatorProvider {
  bool _shouldLoadData = false;
  bool _isLoading = true;
  String _msg = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _initApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        _shouldLoadData ? _createDataLoadingScreen() : Container(),
        _isLoading ? provideLoadingIndicator() : Container(),
      ]),
    );
  }

  Widget _createDataLoadingScreen() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 12.0,
        left: 24.0,
        right: 24.0,
        bottom: 64.0,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/orthodox_cross.png'),
            fit: BoxFit.fitWidth,
          ),
        ),
        child: Align(
            alignment: FractionalOffset.bottomCenter,
            child: showButtonIfNeeded()),
      ),
    );
  }

  void _initApp() async {
    AppLocalization.applySystemLocaleOrDefault(context);
    final passagesAvailable = await arePassagesLoaded();

    if (passagesAvailable) {
      _goToHomeScreen();
    } else {
      setState(() => _shouldLoadData = true);
      _loadPassages();
    }
  }

  Future<void> _goToHomeScreen() async {
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.home, (route) => false);
  }

  Future<void> _loadPassages() async {
    setState(() => _isLoading = true);
    try {
      final result = await InternetAddress.lookup(RestClient.baseUrl);
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        PassagesRepo()
            .loadAndCachePassages()
            .then(
              (_) => _goToHomeScreen(),
            )
            .onError(
              (error, stackTrace) => debugPrint(error.toString()),
            );
      }
    } catch (ex) {
      setState(() {
        _isLoading = false;
        _msg = tr('internet_needed' + ex.toString());
      });
    }
  }

  Widget showButtonIfNeeded() {
    if (_msg.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
            onPressed: () => _loadPassages(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_msg, textAlign: TextAlign.center),
            )),
      );
    } else {
      return Container();
    }
  }
}
