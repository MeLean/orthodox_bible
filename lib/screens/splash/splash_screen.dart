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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _createDataLoadingScreen(),
            _isLoading ? provideLoadingIndicator(context) : Container(),
            _shouldShowPicker ? _provideLanguagePicker() : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _createDataLoadingScreen() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 12.0,
        left: 24.0,
        right: 24.0,
        bottom: 12.0,
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
    print("🟢 [BIBLE_APP_LOGGING] START: _initApp()");

    _cachedLanguageCode = await loadCachedLanguageCodeOrNull();
    print("🟡 [BIBLE_APP_LOGGING] Cached language code: $_cachedLanguageCode");

    if (_cachedLanguageCode == null) {
      print("🟡 [BIBLE_APP_LOGGING] Language code is null, checking locale support...");
      _checkIfUserLocaleSupported();
    }

    _allPassagesAvailable = await arePassagesLoaded(_cachedLanguageCode);
    print("🟢 [BIBLE_APP_LOGGING] Passages available: $_allPassagesAvailable");

    _updateUiState();
  }

  void _updateUiState() async {
    print("🟢 [BIBLE_APP_LOGGING] START: _updateUiState()");

    if (_cachedLanguageCode != null) {
      print("🟡 [BIBLE_APP_LOGGING] Applying locale: $_cachedLanguageCode");
      await AppLocalization.applyLocaleByLanguageCodeOrDefault(context, _cachedLanguageCode!);

      if (_allPassagesAvailable) {
        print("✅ [BIBLE_APP_LOGGING] All passages available, navigating to home...");
        _goToHomeScreen();
      } else {
        print("🟡 [BIBLE_APP_LOGGING] Passages not available, loading...");
        _loadPassages();
      }
    } else {
      print("🟡 [BIBLE_APP_LOGGING] Showing language picker...");
      setState(() {
        _shouldShowPicker = true;
      });
    }
  }

  Future<void> _goToHomeScreen() async {
    print("🚀 [BIBLE_APP_LOGGING] Navigating to HomeScreen...");
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
  }

  Future<void> _loadPassages() async {
    print("🟢 [BIBLE_APP_LOGGING] START: _loadPassages()");
    setState(() => _isLoading = true);

    try {
      final result = await InternetAddress.lookup(RestClient.baseUrl);
      print("✅ [BIBLE_APP_LOGGING] Internet check successful: $result");

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print("🟢 [BIBLE_APP_LOGGING] Loading passages...");
        await PassagesRepo().loadAndCachePassages(_cachedLanguageCode!);
        print("✅ [BIBLE_APP_LOGGING] Passages loaded, navigating to home...");
        _goToHomeScreen();
      }
    } catch (ex) {
      print("❌ [BIBLE_APP_LOGGING] ERROR: Failed to load passages: $ex");
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

  Widget _provideLanguagePicker() {
    return Positioned(
      left: 8.0,
      right: 8.0,
      bottom: 8.0,
      child: SizedBox(
        height: 160.0,
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
