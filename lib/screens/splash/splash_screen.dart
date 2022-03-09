import 'dart:io';

import 'package:bulgarian.orthodox.bible/app/localization.dart';
import 'package:bulgarian.orthodox.bible/app/routes.dart';
import 'package:bulgarian.orthodox.bible/screens/splash/pasages_repo.dart';
import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';

import '../../api/rest_client.dart';
import '../../app/mixins/passage_manager.dart';
import '../../app/widgets/app_text_title.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with PassageManager {
  static const int _goHomeDelayMilis = 1000;
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
      body: Padding(
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
          child: Expanded(
            child: Align(
                alignment: FractionalOffset.bottomCenter,
                child: showButtonIfNeeded()),
          ),
        ),
      ),
    );
  }

  void _initApp() async {
    AppLocalization.applySystemLocaleOrDefault(context);

    if (await arePassagesLoaded()) {
      _goToHomeScreen();
    } else {
      _loadPassages();
    }
  }

  Future<void> _goToHomeScreen({int dalay = _goHomeDelayMilis}) async {
    await Future.delayed(Duration(milliseconds: dalay), () {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.home, (route) => false);
    });
  }

  Future<void> _loadPassages() async {
    try {
      final result = await InternetAddress.lookup(RestClient.baseUrl);
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        PassagesRepo()
            .loadAndCachePassages()
            .then(
              (_) => _goToHomeScreen(dalay: 0),
            )
            .onError(
              (error, stackTrace) => debugPrint(error.toString()),
            );
      }
    } on SocketException catch (_) {
      setState(() {
        _msg = tr('internet_needed');
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
