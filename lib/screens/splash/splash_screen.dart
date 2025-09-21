import 'dart:ui';

import 'package:bulgarian.orthodox.bible/app/localization.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/cache.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/loading.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/passage_manager.dart';
import 'package:bulgarian.orthodox.bible/app/routes.dart';
import 'package:bulgarian.orthodox.bible/app/widgets/app_locale_picker.dart';
import 'package:bulgarian.orthodox.bible/screens/splash/pasages_repo.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../app_logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with PassageManager, LoadingIndicatorProvider, AppCache {
  bool _shouldShowPicker = false;
  bool _isLoading = false;
  String? _cachedLanguageCode;
  String? _errorMsg; // generic error, no “internet required” text

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
                        child: _retryButtonIfError(),
                      ),
                    ),
                  ),
                ),

                // Language picker (appears only when needed)
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
      final deviceCode = PlatformDispatcher.instance.locale.languageCode;
      if (AppLocalization.isLanguageCodeSupported(deviceCode)) {
        _cachedLanguageCode = deviceCode;
        await saveLanguageCode(deviceCode);
        AppLogger.info("✅ Adopted device locale: $deviceCode");
      } else {
        setState(() => _shouldShowPicker = true);
        return; // wait for user to pick
      }
    }

    await _continueInit();
  }

  Future<void> _continueInit() async {
    AppLogger.info("Applying locale: $_cachedLanguageCode");
    await AppLocalization.applyLocaleByLanguageCodeOrDefault(
      context,
      _cachedLanguageCode!,
    );

    final alreadyLoaded = await arePassagesLoaded(_cachedLanguageCode);
    AppLogger.info("Passages available (cached/local): $alreadyLoaded");

    if (alreadyLoaded) {
      _goToHomeScreen();
    } else {
      await _loadPassages(); // attempt loading (e.g., from Firebase / assets)
    }
  }

  Future<void> _onLocalePicked(String languageCode) async {
    await saveLanguageCode(languageCode);
    setState(() {
      _cachedLanguageCode = languageCode;
      _isLoading = true;
      _shouldShowPicker = false;
      _errorMsg = null;
    });
    await _continueInit();
  }

  void _goToHomeScreen() {
    AppLogger.info("🚀 Navigating to HomeScreen...");
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
  }

  Future<void> _loadPassages() async {
    AppLogger.info("START: _loadPassages()");
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      // No internet/DNS check. Just try to load.
      await PassagesRepo().loadAndCachePassages(_cachedLanguageCode!);
      AppLogger.info("✅ Passages loaded, navigating to home...");
      _goToHomeScreen();
    } catch (ex, st) {
      AppLogger.error("_loadPassages() ERROR: $ex\n$st");
      setState(() {
        _errorMsg = tr('something_wrong'); // keep it neutral & localized
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------- errors / UI helpers ----------------

  Widget _retryButtonIfError() {
    if (_errorMsg == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: _loadPassages,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(_errorMsg!, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
