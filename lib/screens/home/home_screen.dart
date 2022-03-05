import 'package:flutter/material.dart';

import '../../app/models/passage.dart';
import '../../app/routes.dart';
import '../../app/widgets/head_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _maxTextSize = 36;
  static const _minTextSize = 12;
  static const _startingHeadIndex = 0;
  static const _startingFileNum = 1;
  static const _defaultDuration = Duration(milliseconds: 500);
  static const _defaultCurve = Curves.ease;

  //TODO CHECK
  static const _maxFileNum = 72;
  static const _minFileNum = 1;
  late PageController _pageController;
  Passage? _passage;
  double _custFontSize = 16;
  int _fileNum = 1;
  int _headIndex = _startingHeadIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _loadFile();
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
        onPressed: () => {},
        icon: const Icon(Icons.navigation_outlined),
      ),
      IconButton(
        onPressed: () => {Navigator.of(context).pushNamed(AppRoutes.info)},
        icon: const Icon(Icons.info_outline),
      ),
      IconButton(
        onPressed: () => _getPreviusHead(),
        icon: const Icon(Icons.arrow_back),
      ),
      IconButton(
        onPressed: () => _getNextHead(),
        icon: const Icon(Icons.arrow_forward),
      ),
      IconButton(
        onPressed: () => _decreseTextsize(),
        icon: const Icon(Icons.remove),
      ),
      IconButton(
        onPressed: () => _increaseTextsize(),
        icon: const Icon(Icons.add),
      ),
    ];
  }

  void _increaseTextsize() {
    if (_custFontSize <= _maxTextSize) {
      setState(() {
        _custFontSize += 2;
      });
    }
  }

  void _decreseTextsize() {
    if (_custFontSize >= _minTextSize) {
      setState(() {
        _custFontSize -= 2;
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
    } else {
      _calculateNextFileNum();
      _loadFile();
    }
  }

  void _calculateNextFileNum() {
    if (_fileNum < _minFileNum || _fileNum >= _maxFileNum) {
      _fileNum = _minFileNum;
      return;
    }

    if (_fileNum < _maxFileNum) {
      _fileNum += 1;
    }
  }

  void _getPreviusHead() {
    if (_headIndex > _startingHeadIndex) {
      _pageController.previousPage(
        duration: _defaultDuration,
        curve: _defaultCurve,
      );
      _headIndex -= 1;
    } else {
      if (_fileNum > _startingFileNum) {
        _fileNum -= 1;
        _loadFile(showLast: true);
      }
    }
  }

  void _loadFile({bool showLast = false}) async {
    String data = await DefaultAssetBundle.of(context)
        .loadString('assets/json/bg_$_fileNum.json');

    setState(() {
      _passage = Passage.fromJson(data);
      if (showLast) {
        _headIndex = _passage!.heads.length - 1;
      } else {
        _headIndex = _startingHeadIndex;
      }
    });
  }
}
