import 'package:bulgarian.orthodox.bible/app/localization.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/passage_manager.dart';
import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/mixins/cache.dart';
import '../../app/models/passage.dart';
import '../../app/routes.dart';
import '../../app/widgets/app_lcon_button.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../app_logger.dart';
import '../../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with PassageManager, AppCache {
  // ---- Config ----
  static const _maxTextSize = Constants.maxTextSize;
  static const _minTextSize = Constants.minTextSize;
  static const _startingFileNum = 1;
  static const _defaultTextSize = Constants.defaultTextSize;
  static const _defaultTitleSize = Constants.defaultTitleSize;
  static const _defaultTextDiff = Constants.defaultTextDiff;
  static const _defaultDuration = Duration(milliseconds: 400);
  static const _defaultCurve = Curves.easeOutCubic;
  static const _defaultHeadIndex = 0;

  // ---- State ----
  late final PageController _pageController;
  final int _defaultFileNum = int.tryParse(tr("new_order_file_num_str")) ?? _startingFileNum;

  Passage? _passage;
  double _textDiff = _defaultTextDiff;
  double _custTextSize = _defaultTextSize;
  double _custTitleSize = _defaultTitleSize;
  int _fileNum = _startingFileNum;
  int _headIndex = _defaultHeadIndex;

  // guards
  bool _isSwitchingPage = false; // serialize page/file switches
  bool _handlingEdgeSwipe = false; // guard ghost-page transitions
  bool _didSetInitialPage = false; // prevent brief ghost on first attach

  // ---- Ghost-page helpers (sentinels at both ends) ----
  int get _virtualItemCount => (_passage?.heads.length ?? 0) + 2; // leading + trailing ghost
  int _logicalToPage(int headIndex) => headIndex + 1; // [0..N-1] -> [1..N]
  int _pageToLogical(int pageIndex) => pageIndex - 1; // [1..N]   -> [0..N-1]

  @override
  void initState() {
    super.initState();
    // Start on page 1 because page 0 is a leading ghost page.
    _pageController = PageController(initialPage: 1, keepPage: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromCacheOrDefault());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasHeads = _passage?.heads.isNotEmpty ?? false;

    // As soon as heads attach, instantly place the controller on the REAL page (no flash of ghost).
    if (hasHeads && !_didSetInitialPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureInitialPage());
    }

    return Scaffold(
      appBar: AppBar(actions: _createActions),
      body: SafeArea(
        child: hasHeads
            ? PageView.builder(
                key: ValueKey('file:$_fileNum:heads:${_passage!.heads.length}'),
                controller: _pageController,
                physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
                itemCount: _virtualItemCount, // heads + 2 ghosts
                onPageChanged: (pageIndex) async {
                  if (_handlingEdgeSwipe) return;

                  final lastVirtual = _virtualItemCount - 1;

                  if (pageIndex == 0) {
                    // Leading ghost → previous file (once)
                    _handlingEdgeSwipe = true;
                    await _switchToPreviousFile();
                    _handlingEdgeSwipe = false;
                    return;
                  }

                  if (pageIndex == lastVirtual) {
                    // Trailing ghost → next file (once)
                    _handlingEdgeSwipe = true;
                    await _switchToNextFile();
                    _handlingEdgeSwipe = false;
                    return;
                  }

                  // Normal head page
                  final newHeadIndex = _pageToLogical(pageIndex);
                  if (newHeadIndex != _headIndex) {
                    _headIndex = newHeadIndex;
                    saveHeadIndex(_headIndex);
                    setState(() {}); // reflect toolbar/back/forward availability
                  }
                },
                itemBuilder: (context, pageIndex) {
                  final heads = _passage!.heads;
                  final lastVirtual = _virtualItemCount - 1;

                  // Ghost pages (empty spacers)
                  if (pageIndex == 0 || pageIndex == lastVirtual) {
                    return const SizedBox.expand();
                  }

                  final logicalIndex = _pageToLogical(pageIndex);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _passage?.title ?? '',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: _custTitleSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          heads.isNotEmpty ? heads[logicalIndex] : '',
                          style: TextStyle(
                            fontSize: _custTextSize,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            : const SizedBox.expand(), // nothing until data attaches (no ghost flash)
      ),
    );
  }

  // Ensure we never show the leading ghost on first attach (jump, not animate).
  Future<void> _ensureInitialPage() async {
    if (!mounted) return;
    if (!_pageController.hasClients) return;
    try {
      _didSetInitialPage = true;
      _pageController.jumpToPage(_logicalToPage(_headIndex));
    } catch (_) {}
  }

  // ---- UI actions ----
  List<Widget> get _createActions {
    return [
      AppIconButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.info),
        icon: const Icon(Icons.info_outline),
        disableAfterClick: _defaultDuration,
      ),
      AppIconButton(
        onPressed: _safePrevHeadTap,
        icon: const Icon(Icons.arrow_back),
        disableAfterClick: _defaultDuration,
      ),
      AppIconButton(
        onPressed: _safeNextHeadTap,
        icon: const Icon(Icons.arrow_forward),
        disableAfterClick: _defaultDuration,
      ),
      AppIconButton(
        onPressed: _increaseTextsize,
        icon: const Icon(Icons.add),
        disableAfterClick: _defaultDuration,
      ),
      AppIconButton(
        onPressed: _decreseTextsize,
        icon: const Icon(Icons.remove),
        disableAfterClick: _defaultDuration,
      ),
      AppIconButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.search),
        icon: const Icon(Icons.manage_search),
        disableAfterClick: _defaultDuration,
      ),
      PopupMenuButton(
        offset: const Offset(0, kToolbarHeight),
        itemBuilder: (_) => [
          PopupMenuItem(
            onTap: () {
              MyApp.themeNotifier.value =
                  MyApp.themeNotifier.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
              saveLightMode(MyApp.themeNotifier.value.name);
            },
            child: MenuItem(
              text: MyApp.themeNotifier.value == ThemeMode.dark ? tr('go_light') : tr('go_dark'),
              icon: MyApp.themeNotifier.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
              tint: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          PopupMenuItem(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.navigator),
            child: MenuItem(
              text: tr('navigate_by_head'),
              icon: Icons.navigation_outlined,
              tint: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    ];
  }

  // ---- Text size ----
  void _increaseTextsize() {
    if (_custTextSize < _maxTextSize) {
      final newDiff = _textDiff + 2;
      saveDiffSize(newDiff);
      setState(() {
        _textDiff = newDiff;
        _custTextSize = _calcualteTextSize(_textDiff);
        _custTitleSize = _calculateTitleSize(_textDiff);
      });
    }
  }

  void _decreseTextsize() {
    if (_custTextSize > _minTextSize) {
      final newDiff = _textDiff - 2;
      saveDiffSize(newDiff);
      setState(() {
        _textDiff = newDiff;
        _custTextSize = _calcualteTextSize(_textDiff);
        _custTitleSize = _calculateTitleSize(_textDiff);
      });
    }
  }

  // ---- Navigation (serialize + await animations) ----
  Future<void> _safeNextHeadTap() async {
    await _guardedSwitch(() async => _getNextHead());
  }

  Future<void> _safePrevHeadTap() async {
    await _guardedSwitch(() async => _getPreviusHead());
  }

  Future<void> _guardedSwitch(Future<void> Function() action) async {
    if (_isSwitchingPage) return;
    _isSwitchingPage = true;
    try {
      if (_pageController.hasClients && _pageController.position.isScrollingNotifier.value) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
      await action();
    } finally {
      _isSwitchingPage = false;
    }
  }

  Future<void> _getNextHead() async {
    final len = _passage?.heads.length ?? 0;
    if (len == 0) return;

    if (_headIndex < len - 1) {
      _headIndex += 1;
      await saveHeadIndex(_headIndex);
      setState(() {});
      if (_pageController.hasClients) {
        await _pageController.animateToPage(
          _logicalToPage(_headIndex),
          duration: _defaultDuration,
          curve: _defaultCurve,
        );
      }
    } else {
      await _switchToNextFile(); // direct file switch
    }
  }

  Future<void> _getPreviusHead() async {
    if (_headIndex > 0) {
      _headIndex -= 1;
      await saveHeadIndex(_headIndex);
      setState(() {});
      if (_pageController.hasClients) {
        await _pageController.animateToPage(
          _logicalToPage(_headIndex),
          duration: _defaultDuration,
          curve: _defaultCurve,
        );
      }
    } else if (_fileNum > _startingFileNum) {
      await _switchToPreviousFile(); // direct file switch
    }
  }

  // ---- Direct file switches for ghost pages ----
  Future<void> _switchToNextFile() async {
    final maxNum = maxFileNum();
    final nextFile =
        (_fileNum < PassageManager.minFileNum || _fileNum >= maxNum) ? PassageManager.minFileNum : _fileNum + 1;

    final passage = await loadPassage(
      context,
      nextFile,
      AppLocalization.getLanguageCode(context),
    );
    await _cacheAndUpdate(nextFile, _defaultHeadIndex, passage); // first head in next file
  }

  Future<void> _switchToPreviousFile() async {
    final maxNum = maxFileNum();
    final prevFile = (_fileNum <= PassageManager.minFileNum) ? maxNum : _fileNum - 1;

    final passage = await loadPassage(
      context,
      prevFile,
      AppLocalization.getLanguageCode(context),
    );
    final lastHead = passage.heads.isNotEmpty ? passage.heads.length - 1 : 0;
    await _cacheAndUpdate(prevFile, lastHead, passage); // last head in previous file
  }

  Future<void> _cacheAndUpdate(int fileNum, int headIndex, Passage passage) async {
    await saveFileNum(fileNum);
    await saveHeadIndex(headIndex);
    if (!mounted) return;

    setState(() {
      _fileNum = fileNum;
      _headIndex = headIndex.clamp(0, (passage.heads.length - 1).clamp(0, 1 << 30));
      _passage = passage;
      // prevent the PageView from flashing a ghost on the first frame of a new file
      _didSetInitialPage = true;
    });

    // Animate to the new head after the PageView (with ghosts) reattaches
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_pageController.hasClients) return;
      try {
        await _pageController.animateToPage(
          _logicalToPage(_headIndex),
          duration: _defaultDuration,
          curve: _defaultCurve,
        );
      } catch (_) {}
    });
  }

  void _initFromCacheOrDefault({int retryCount = 1}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      AppLogger.info("🏠 _initFromCacheOrDefault reached");
      try {
        final fileNum = await loadFileNum(_defaultFileNum);
        final headIndex = await loadHeadIndex(_defaultHeadIndex);
        final textDiff = await loadTextSizeDiff(_defaultTextDiff);
        final themeMode = await loadLightMode();

        if (themeMode == ThemeMode.dark.name) {
          MyApp.themeNotifier.value = ThemeMode.dark;
        }

        if (!mounted) return;

        final languageCode = AppLocalization.getLanguageCode(context);
        final newPassage = await loadPassage(context, fileNum, languageCode);

        AppLogger.info("🏠 initFromCache lang:$languageCode title:${newPassage.title} file:$fileNum head:$headIndex");

        setState(() {
          _fileNum = fileNum;
          _headIndex = (headIndex).clamp(0, (newPassage.heads.length - 1).clamp(0, 1 << 30));
          _passage = newPassage;
          _textDiff = textDiff;
          _custTitleSize = _calculateTitleSize(textDiff);
          _custTextSize = _calcualteTextSize(textDiff);
          _didSetInitialPage = false; // allow _ensureInitialPage() to jump once
        });
      } catch (e, stackTrace) {
        AppLogger.info(" ❌ Error loading passage (Attempt: $retryCount): $e\n$stackTrace");

        if (retryCount < 2) {
          AppLogger.info(" 🔄 Retrying passage load...");
          await Future.delayed(const Duration(milliseconds: 300));
          _initFromCacheOrDefault(retryCount: retryCount + 1);
        } else {
          AppLogger.info(" ❌ Final failure - showing default passage.");
          if (!mounted) return;
          setState(() {
            _passage = Passage(tr("something_wrong"), [tr("no_results")]);
            _headIndex = 0;
            _didSetInitialPage = false;
          });
        }
      }
    });
  }

  // ---- Utils ----
  double _calculateTitleSize(double diff) => _defaultTitleSize + diff;
  double _calcualteTextSize(double diff) => _defaultTextSize + diff;
}

class MenuItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? tint;

  const MenuItem({
    Key? key,
    required this.text,
    required this.icon,
    this.tint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconTint = tint ?? Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(icon, color: iconTint),
        ),
        Text(text),
      ],
    );
  }
}
