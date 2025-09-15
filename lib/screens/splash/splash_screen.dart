import 'dart:io';
import 'dart:ui';

import 'package:bulgarian.orthodox.bible/app/localization.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/cache.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/loading.dart';
import 'package:bulgarian.orthodox.bible/app/routes.dart';
import 'package:bulgarian.orthodox.bible/app/widgets/app_locale_picker.dart';
import 'package:bulgarian.orthodox.bible/screens/splash/pasages_repo.dart';
import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';

import '../../api/rest_client.dart';
import '../../app/mixins/passage_manager.dart';
import '../../app_loger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with PassageManager, LoadingIndicatorProvider, AppCache {
  bool _shouldShowPicker = false;
  bool _allPassagesAvailable = false;
  bool _isLoading = false;
  String? _cachedLanguageCode;

  String _msg = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    var bottomPadding = 160.0;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _createDataLoadingScreen(bottomPadding),
            _isLoading ? provideLoadingIndicator(context) : Container(),
            _shouldShowPicker ? _provideLanguagePicker(bottomPadding) : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _createDataLoadingScreen(double bottomPadding) {
    return Padding(
      padding: EdgeInsets.only(
        top: 0,
        left: 24.0,
        right: 24.0,
        bottom: bottomPadding,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/orthodox_cross.png'),
            fit: BoxFit.fitWidth,
          ),
        ),
        child: Align(alignment: FractionalOffset.bottomCenter, child: _showButtonIfNeeded()),
      ),
    );
  }

  void _initApp() async {
    AppLogger.info("START: _initApp()");

    try {
      _cachedLanguageCode = await loadCachedLanguageCodeOrNull();
      AppLogger.info(" 🔤 Cached Language Code Loaded: $_cachedLanguageCode");
    } catch (e, stack) {
      AppLogger.info(" ❌ Decryption Error: $e\n$stack");
    }

    if (_cachedLanguageCode == null) {
      AppLogger.info("Language code is null, checking locale support...");
      _checkIfUserLocaleSupported();
    }

    _allPassagesAvailable = await arePassagesLoaded(_cachedLanguageCode);
    AppLogger.info("Passages available: $_allPassagesAvailable");

    _updateUiState();
  }

  void _updateUiState() async {
    AppLogger.info("START: _updateUiState()");

    if (_cachedLanguageCode != null) {
      AppLogger.info("Applying locale: $_cachedLanguageCode");
      await AppLocalization.applyLocaleByLanguageCodeOrDefault(context, _cachedLanguageCode!);

      if (_allPassagesAvailable) {
        AppLogger.info("✅ All passages available, navigating to home...");
        _goToHomeScreen();
      } else {
        AppLogger.info("Passages not available, loading...");
        _loadPassages();
      }
    } else {
      AppLogger.info("Showing language picker...");
      setState(() {
        _shouldShowPicker = true;
      });
    }
  }

  Future<void> _goToHomeScreen() async {
    AppLogger.info("🚀 Navigating to HomeScreen...");
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
  }

  Future<void> _loadPassages() async {
    AppLogger.info("START: _loadPassages()");
    setState(() => _isLoading = true);

    try {
      final result = await InternetAddress.lookup(RestClient.baseUrl);
      AppLogger.info("Internet check successful: $result");

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        AppLogger.info("Loading passages...");
        await PassagesRepo().loadAndCachePassages(_cachedLanguageCode!);
        AppLogger.info("Passages loaded, navigating to home...");
        _goToHomeScreen();
      }
    } catch (ex) {
      AppLogger.error("_initApp()] ERROR: Failed to load passages: $ex");
      setErrorState(ex);
    }
  }

  void setErrorState(Object ex) {
    setState(() {
      _isLoading = false;
      _msg = tr('internet_needed') + ex.toString();
    });
  }

  Widget _showButtonIfNeeded() {
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

  Widget _provideLanguagePicker(double bottomPadding) {
    return Positioned(
      left: 8.0,
      right: 8.0,
      bottom: 8.0,
      child: SizedBox(
        height: bottomPadding,
        width: MediaQuery.of(context).size.width,
        child: AppLocalePicker(
          supportedLocales: AppLocalization.getSupprotedLanguageCodes(),
          localePickedCallback: (String languageCode) {
            _setLocaleAndLoadPassages(languageCode);
          },
        ),
      ),
    );
  }

  void _checkIfUserLocaleSupported() {
    var languageCode = PlatformDispatcher.instance.locale.languageCode;
    if (AppLocalization.isLanguageCodeSupported(languageCode)) {
      _setLocaleAndLoadPassages(languageCode);
    }
  }

  void _setLocaleAndLoadPassages(String languageCode) async {
    saveLanguageCode(languageCode);
    setState(() {
      _cachedLanguageCode = languageCode;
      _isLoading = true;
    });

    _updateUiState();
  }
}
