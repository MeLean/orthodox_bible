// lib/screens/splash/splash_screen.dart
import 'dart:io';
import 'dart:ui';

import 'package:bulgarian.orthodox.bible/app/localization.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/cache.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/loading.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/passage_manager.dart'; // ✅ back
import 'package:bulgarian.orthodox.bible/app/routes.dart';
import 'package:bulgarian.orthodox.bible/app/widgets/app_locale_picker.dart';
import 'package:bulgarian.orthodox.bible/screens/splash/pasages_repo.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../api/rest_client.dart';
import '../../app_logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with PassageManager, LoadingIndicatorProvider, AppCache {
  // ✅ PassageManager restored
  bool _shouldShowPicker = false;
  bool _allPassagesAvailable = false;
  bool _isLoading = false;
  String? _cachedLanguageCode;

  String _msg = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initApp());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Cross image area (keeps ratio on black background)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        image: DecorationImage(
                          image: AssetImage('assets/images/orthodox_cross.png'),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _showButtonIfNeeded(),
                      ),
                    ),
                  ),
                ),

                // Language picker (wraps naturally, no hardcoded height)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _shouldShowPicker
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 12.0, 8.0, 8.0),
                          child: AppLocalePicker(
                            supportedLocales: AppLocalization.getSupprotedLanguageCodes(),
                            localePickedCallback: (String languageCode) {
                              _onLocalePicked(languageCode);
                            },
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            if (_isLoading) provideLoadingIndicator(context),
          ],
        ),
      ),
    );
  }

  // ---------------- lifecycle / flow ----------------

  Future<void> _initApp() async {
    AppLogger.info("START: _initApp()");

    try {
      _cachedLanguageCode = await loadCachedLanguageCodeOrNull();
      AppLogger.info(" 🔤 Cached Language Code Loaded: $_cachedLanguageCode");
    } catch (e, stack) {
      AppLogger.info(" ❌ Decryption Error: $e\n$stack");
    }

    if (_cachedLanguageCode == null) {
      AppLogger.info("Language code is null, checking device locale...");
      final deviceCode = PlatformDispatcher.instance.locale.languageCode;
      if (AppLocalization.isLanguageCodeSupported(deviceCode)) {
        _cachedLanguageCode = deviceCode;
        await saveLanguageCode(deviceCode);
        AppLogger.info("✅ Adopted device locale: $deviceCode");
      } else {
        setState(() => _shouldShowPicker = true);
        return; // stop flow until user picks
      }
    }

    // We have a language → continue once
    await _continueInit();
  }

  Future<void> _continueInit() async {
    _allPassagesAvailable = await arePassagesLoaded(_cachedLanguageCode); // ✅ now resolves
    AppLogger.info("Passages available: $_allPassagesAvailable");

    AppLogger.info("Applying locale: $_cachedLanguageCode");
    await AppLocalization.applyLocaleByLanguageCodeOrDefault(
      context,
      _cachedLanguageCode!,
    );

    if (_allPassagesAvailable) {
      AppLogger.info("✅ All passages available, navigating to home...");
      _goToHomeScreen();
    } else {
      AppLogger.info("Passages not available, loading...");
      await _loadPassages();
    }
  }

  Future<void> _onLocalePicked(String languageCode) async {
    await saveLanguageCode(languageCode);
    setState(() {
      _cachedLanguageCode = languageCode;
      _isLoading = true;
      _shouldShowPicker = false;
    });
    await _continueInit(); // single, linear flow
  }

  Future<void> _goToHomeScreen() async {
    AppLogger.info("🚀 Navigating to HomeScreen...");
    if (!mounted) return;
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
        await _goToHomeScreen();
      }
    } catch (ex) {
      AppLogger.error("_loadPassages() ERROR: $ex");
      setErrorState(ex);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------- errors / UI helpers ----------------

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
          onPressed: _loadPassages,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(_msg, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
