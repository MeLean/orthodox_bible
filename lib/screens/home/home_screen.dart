import 'package:bulgarian.orthodox.bible/app/mixins/file_loader.dart';
import 'package:flutter/material.dart';

import '../../app/mixins/cache.dart';
import '../../app/models/passage.dart';
import '../../app/routes.dart';
import '../../app/widgets/head_page.dart';
import 'package:easy_localization/easy_localization.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with PassageLoader, AppCache {
  static const _maxTextSize = 36;
  static const _minTextSize = 12;
  static const _startingFileNum = 1;
  static const _defaultFileNum = 3;
  static const _defaultTextSize = 16.0;
  static const _defaultLocaleName = 'bg';
  static const _defaultDuration = Duration(milliseconds: 500);
  static const _defaultCurve = Curves.ease;
  static const _defaultHeadIndex = 0;
  static const _maxFileNum = 3;
  static const _minFileNum = 1;
  late PageController _pageController;
  late String _localeName = _defaultLocaleName;
  Passage? _passage;
  double _custFontSize = _defaultTextSize;
  int _fileNum = 1;
  int _headIndex = _defaultHeadIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
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
    _pageController = PageController();

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (_passage?.heads.isNotEmpty == true) {
        _pageController.animateToPage(
          _headIndex,
          duration: _defaultDuration,
          curve: _defaultCurve,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_passage?.title ?? ''),
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
          child: PageView.builder(
              itemCount: _passage?.heads.length,
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return HeadPage(
                  text: _passage?.heads[index] ?? '',
                  custFontSize: _custFontSize,
                );
              }),
        ),
      ),
    );
  }

  List<Widget> get _createActions {
    return [
      IconButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.info),
        icon: const Icon(Icons.info_outline),
      ),
      IconButton(
        onPressed: () async {
          final result =
              await Navigator.of(context).pushNamed(AppRoutes.navigation);
          if (result != null) {
            final int fileNum = result as int;
            final passage = await loadPassage(context, _localeName, fileNum);

            _cacheAndUpdate(fileNum, _defaultHeadIndex, passage);
          }
        },
        icon: const Icon(Icons.navigation_outlined),
      ),
      IconButton(
        onPressed: () => _getPreviusHead(),
        icon: const Icon(Icons.arrow_back),
      ),
      IconButton(
        onPressed: () => _getNextHead(),
        icon: const Icon(Icons.arrow_forward),
      ),
      PopupMenuButton(
          itemBuilder: (_) => [
                PopupMenuItem(
                  onTap: () => _increaseTextsize(),
                  child: MenuItem(
                    text: tr('increase_text'),
                    icon: Icons.add,
                  ),
                ),
                PopupMenuItem(
                  onTap: () => _decreseTextsize(),
                  child: MenuItem(
                    text: tr('decrease_text'),
                    icon: Icons.remove,
                  ),
                ),
              ]),
    ];
  }

  void _increaseTextsize() {
    if (_custFontSize <= _maxTextSize) {
      final size = _custFontSize += 2;
      saveTextSize(size);
      setState(() {
        _custFontSize = size;
      });
    }
  }

  void _decreseTextsize() {
    if (_custFontSize >= _minTextSize) {
      final size = _custFontSize -= 2;
      saveTextSize(size);
      setState(() {
        _custFontSize = size;
      });
    }
  }

  void _getNextHead() {
    int pasageLenght =
        _passage?.heads.length != null ? _passage!.heads.length : 1 << 63;

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
          _localeName,
          fileNum,
        );
        final headIndex = passage.heads.length - 1;

        _cacheAndUpdate(fileNum, headIndex, passage);
      }
    }
  }

  void _cacheAndUpdate(int fileNum, int headIndex, Passage passage) async {
    await saveFileNum(fileNum);
    await saveHeadIndex(headIndex);

    setState(() {
      _fileNum = fileNum;
      _headIndex = headIndex;
      _passage = passage;
    });
  }

  void _calculateNextFileNum() async {
    if (_fileNum < _minFileNum || _fileNum >= _maxFileNum) {
      final passage = await loadPassage(
        context,
        _localeName,
        _minFileNum,
      );

      _cacheAndUpdate(_minFileNum, _defaultHeadIndex, passage);
      return;
    }

    if (_fileNum < _maxFileNum) {
      final fileNum = _fileNum + 1;
      final passage = await loadPassage(
        context,
        _localeName,
        fileNum,
      );

      _cacheAndUpdate(fileNum, _defaultHeadIndex, passage);
    }
  }

  void _initFromCacheOrDefault() async {
    final fileNum = await loadFileNum(_defaultFileNum);
    final headIndex = await loadHeadIndex(_defaultHeadIndex);
    final custFontSize = await loadTextSize(_defaultTextSize);
    final locale = await loadCachedLocale(_defaultLocaleName);

    final newPassage = await loadPassage(
      context,
      _localeName,
      fileNum,
    );

    setState(() {
      _fileNum = fileNum;
      _headIndex = headIndex;
      _passage = newPassage;
      _custFontSize = custFontSize;
      _localeName = locale;
    });
  }
}

class MenuItem extends StatelessWidget {
  final String text;
  final IconData icon;

  const MenuItem({
    Key? key,
    required this.text,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}
