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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFromCacheOrDefault();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep controller aligned with current head (single owner for movement)
    WidgetsBinding.instance.addPostFrameCallback((_) => _alignController());

    AppLogger.info(" 🏠 HomeScreen build");

    return Scaffold(
      appBar: AppBar(
        actions: _createActions,
      ),
      body: SafeArea(
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (_passage?.heads.isEmpty ?? true) return false;
            if (_isSwitchingPage) return false;
            if (n is! OverscrollNotification) return false;

            // Only react to HORIZONTAL overscrolls (from PageView)
            final axis = n.metrics.axisDirection;
            final isHorizontal = axis == AxisDirection.left || axis == AxisDirection.right;
            if (!isHorizontal) return false;

            final lastHead = _passage!.heads.length - 1;

            if (n.overscroll > 0 && _headIndex == lastHead) {
              _guardedSwitch(() async => _calculateNextFileNum());
              return true;
            }

            if (n.overscroll < 0 && _headIndex == _defaultHeadIndex) {
              _guardedSwitch(() async => _getPreviusHead());
              return true;
            }

            return false;
          },
          child: PageView.builder(
            controller: _pageController,
            physics: const PageScrollPhysics(),
            itemCount: _passage?.heads.length ?? 0,
            onPageChanged: (index) {
              _headIndex = index;
              saveHeadIndex(_headIndex);
            },
            itemBuilder: (context, index) {
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
                      _passage?.heads[index] ?? '',
                      style: TextStyle(
                        fontSize: _custTextSize,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- Controller alignment: single place in charge of moving pages (always animate) ---
  Future<void> _alignController() async {
    if (!mounted) return;
    final hasItems = _passage?.heads.isNotEmpty ?? false;
    if (!hasItems) return;
    if (!_pageController.hasClients) return;

    // Avoid fighting with user drag
    if (_pageController.position.isScrollingNotifier.value) return;

    final currentPage = _pageController.page?.round();
    if (currentPage == _headIndex) return;

    try {
      await _pageController.animateToPage(
        _headIndex,
        duration: _defaultDuration,
        curve: _defaultCurve,
      );
    } catch (_) {
      // ignore if detached
    }
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
      // If dragging, wait a tick to avoid fighting with gesture
      if (_pageController.hasClients && _pageController.position.isScrollingNotifier.value) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
      await action();
    } finally {
      _isSwitchingPage = false;
    }
  }

  Future<void> _getNextHead() async {
    final passageLength = _passage?.heads.length ?? 0;
    if (passageLength == 0) return;

    if (_headIndex < passageLength - 1) {
      if (_pageController.hasClients) {
        await _pageController.animateToPage(
          _headIndex + 1,
          duration: _defaultDuration,
          curve: _defaultCurve,
        );
      }
      _headIndex += 1;
      await saveHeadIndex(_headIndex);
      setState(() {}); // reflect toolbar/back/forward availability
    } else {
      await _calculateNextFileNum();
    }
  }

  Future<void> _getPreviusHead() async {
    if (_headIndex > _defaultHeadIndex) {
      if (_pageController.hasClients) {
        await _pageController.animateToPage(
          _headIndex - 1,
          duration: _defaultDuration,
          curve: _defaultCurve,
        );
      }
      _headIndex -= 1;
      await saveHeadIndex(_headIndex);
      setState(() {});
    } else if (_fileNum > _startingFileNum) {
      final fileNum = _fileNum - 1;
      final passage = await loadPassage(
        context,
        fileNum,
        AppLocalization.getLanguageCode(context),
      );
      final headIndex = passage.heads.isNotEmpty ? passage.heads.length - 1 : 0;
      await _cacheAndUpdate(fileNum, headIndex, passage);
    }
  }

  Future<void> _cacheAndUpdate(int fileNum, int headIndex, Passage passage) async {
    await saveFileNum(fileNum);
    await saveHeadIndex(headIndex);

    if (!mounted) return;

    setState(() {
      _fileNum = fileNum;
      _headIndex = headIndex.clamp(0, (passage.heads.length - 1).clamp(0, 1 << 30));
      _passage = passage;
    });

    // Animate to the new head after the PageView reattaches
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!_pageController.hasClients) return;
      try {
        await _pageController.animateToPage(
          _headIndex,
          duration: _defaultDuration,
          curve: _defaultCurve,
        );
      } catch (_) {}
    });
  }

  Future<void> _calculateNextFileNum() async {
    final maxNum = maxFileNum();

    if (_fileNum < PassageManager.minFileNum || _fileNum >= maxNum) {
      final passage = await loadPassage(
        context,
        PassageManager.minFileNum,
        AppLocalization.getLanguageCode(context),
      );
      await _cacheAndUpdate(PassageManager.minFileNum, _defaultHeadIndex, passage);
      return;
    }

    if (_fileNum < maxNum) {
      final fileNum = _fileNum + 1;
      final passage = await loadPassage(
        context,
        fileNum,
        AppLocalization.getLanguageCode(context),
      );
      await _cacheAndUpdate(fileNum, _defaultHeadIndex, passage);
    }
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

        AppLogger.info(
          "🏠 initFromCache lang:$languageCode title:${newPassage.title} file:$fileNum head:$headIndex",
        );

        setState(() {
          _fileNum = fileNum;
          _headIndex = (headIndex).clamp(0, (newPassage.heads.length - 1).clamp(0, 1 << 30));
          _passage = newPassage;
          _textDiff = textDiff;
          _custTitleSize = _calculateTitleSize(textDiff);
          _custTextSize = _calcualteTextSize(textDiff);
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
