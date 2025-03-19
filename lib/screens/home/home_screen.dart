import 'package:bulgarian.orthodox.bible/app/localization.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/passage_manager.dart';
import 'package:flutter/material.dart';

import '../../app/mixins/cache.dart';
import '../../app/models/passage.dart';
import '../../app/routes.dart';
import '../../app/widgets/app_lcon_button.dart';
import '../../app/widgets/app_text_title.dart';
import '../../app/widgets/head_page.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with PassageManager, AppCache {
  static const _maxTextSize = 36;
  static const _minTextSize = 12;
  static const _startingFileNum = 1;
  static const _defaultTextSize = 16.0;
  static const _defaultTitleSize = 18.0;
  static const _defaultTextDiff = 0.0;
  static const _defaultDuration = Duration(milliseconds: 500);
  static const _defaultCurve = Curves.ease;
  static const _defaultHeadIndex = 0;
  late PageController _pageController;
  final int _defaultFileNum = int.tryParse(tr("new_order_file_num_str")) ?? _startingFileNum;
  Passage? _passage;
  double _textDiff = _defaultTextDiff;
  double _custTextSize = _defaultTextSize;
  double _custTitleSize = _defaultTitleSize;
  int _fileNum = 1;
  int _headIndex = _defaultHeadIndex;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      goToAndScroll();
    });

    print(" [BIBLE_APP_LOGGING] 🏠 HomeScreen reached");

    return Scaffold(
      appBar: AppBar(
        actions: _createActions,
      ),
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (dragEndDetails) {
            double velocity = dragEndDetails.primaryVelocity ?? 0;

            if (velocity < 0) {
              _getNextHead();
            }

            if (velocity > 0) {
              _getPreviusHead();
            }
          },
          child: Column(
            children: [
              TextTitle(
                text: _passage?.title ?? '',
                custFontSize: _custTitleSize,
              ),
              Expanded(
                child: PageView.builder(
                    itemCount: _passage?.heads.length,
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return HeadPage(
                        text: _passage?.heads[index] ?? '',
                        custFontSize: _custTextSize,
                      );
                    }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void goToAndScroll() async {
    if (_passage?.heads.isNotEmpty == true) {
      await _pageController.animateToPage(
        _headIndex,
        duration: _defaultDuration,
        curve: _defaultCurve,
      );
    }
  }

  List<Widget> get _createActions {
    return [
      AppIconButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.info),
        icon: const Icon(Icons.info_outline),
        disableAfterClick: _defaultDuration,
      ),
      AppIconButton(
        onPressed: () => _getPreviusHead(),
        icon: const Icon(Icons.arrow_back),
        disableAfterClick: _defaultDuration,
      ),
      AppIconButton(
        onPressed: () => _getNextHead(),
        icon: const Icon(Icons.arrow_forward),
        disableAfterClick: _defaultDuration,
      ),
      AppIconButton(
        onPressed: () => _increaseTextsize(),
        icon: const Icon(Icons.add),
        disableAfterClick: _defaultDuration,
      ),
      AppIconButton(
        onPressed: () => _decreseTextsize(),
        icon: const Icon(Icons.remove),
        disableAfterClick: _defaultDuration,
      ),
      AppIconButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.search),
        icon: const Icon(Icons.navigation_outlined),
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
              ]),
    ];
  }

  void _increaseTextsize() {
    if (_custTextSize <= _maxTextSize) {
      saveDiffSize(_textDiff += 2);
      setState(() {
        _custTextSize = _calcualteTextSize(_textDiff);
        _custTitleSize = _calculateTitleSize(_textDiff);
      });
    }
  }

  void _decreseTextsize() {
    if (_custTextSize >= _minTextSize) {
      saveDiffSize(_textDiff -= 2);
      setState(() {
        _custTextSize = _calcualteTextSize(_textDiff);
        _custTitleSize = _calculateTitleSize(_textDiff);
      });
    }
  }

  void _getNextHead() {
    int pasageLenght = _passage?.heads.length != null ? _passage!.heads.length : 1 << 63;

    if (_headIndex < pasageLenght - 1) {
      _pageController.nextPage(
        duration: _defaultDuration,
        curve: _defaultCurve,
      );
      _headIndex += 1;
      saveHeadIndex(_headIndex);
    } else {
      _calculateNextFileNum();
    }
  }

  void _getPreviusHead() async {
    if (_headIndex > _defaultHeadIndex) {
      _pageController.previousPage(
        duration: _defaultDuration,
        curve: _defaultCurve,
      );
      _headIndex -= 1;
      saveHeadIndex(_headIndex);
    } else {
      if (_fileNum > _startingFileNum) {
        final fileNum = _fileNum - 1;
        final passage = await loadPassage(
          context,
          fileNum,
          AppLocalization.getCurrentLanguageCode(context),
        );
        final headIndex = passage.heads.length - 1;

        _cacheAndUpdate(fileNum, headIndex, passage);
      }
    }
  }

  void _cacheAndUpdate(int fileNum, int headIndex, Passage passage) async {
    await saveFileNum(fileNum);
    await saveHeadIndex(headIndex);

    if (mounted) {
      setState(() {
        _fileNum = fileNum;
        _headIndex = headIndex;
        _passage = passage;
      });
    }
  }

  void _calculateNextFileNum() async {
    int maxNum = maxFileNum();

    if (_fileNum < PassageManager.minFileNum || _fileNum >= maxNum) {
      final passage = await loadPassage(
        context,
        PassageManager.minFileNum,
        AppLocalization.getCurrentLanguageCode(context),
      );

      _cacheAndUpdate(PassageManager.minFileNum, _defaultHeadIndex, passage);
      return;
    }

    if (_fileNum < maxNum) {
      final fileNum = _fileNum + 1;
      final passage = await loadPassage(
        context,
        fileNum,
        AppLocalization.getCurrentLanguageCode(context),
      );

      _cacheAndUpdate(fileNum, _defaultHeadIndex, passage);
    }
  }

  void _initFromCacheOrDefault() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      try {
        final fileNum = await loadFileNum(_defaultFileNum);
        final headIndex = await loadHeadIndex(_defaultHeadIndex);
        final textDiff = await loadTextSizeDiff(_defaultTextDiff);
        final themeMode = await loadlightMode();

        if (themeMode == ThemeMode.dark.name) {
          MyApp.themeNotifier.value = ThemeMode.dark;
        }

        if (!mounted) return;

        final languageCode = AppLocalization.getCurrentLanguageCode(context);
        final newPassage = await loadPassage(context, fileNum, languageCode);

        setState(() {
          _fileNum = fileNum;
          _headIndex = headIndex;
          _passage = newPassage;
          _textDiff = textDiff;
          _custTitleSize = _calculateTitleSize(textDiff);
          _custTextSize = _calcualteTextSize(textDiff);
        });
      } catch (e, stackTrace) {
        debugPrint("Error in _initFromCacheOrDefault: $e\n$stackTrace");
      }
    });
  }

  double _calculateTitleSize(diff) => _defaultTitleSize + diff;
  double _calcualteTextSize(diff) => _defaultTextSize + diff;
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
          child: Icon(
            icon,
            color: iconTint,
          ),
        ),
        Text(text),
      ],
    );
  }
}
