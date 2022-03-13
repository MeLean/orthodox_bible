// ignore: import_of_legacy_library_into_null_safe
import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:bulgarian.orthodox.bible/app/mixins/cache.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/loading.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/passage_manager.dart';
import 'package:bulgarian.orthodox.bible/app/routes.dart';
import 'package:bulgarian.orthodox.bible/screens/search/search_result.dart';

import '../../app/models/passage.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with LoadingIndicatorProvider, PassageManager, AppCache {
  final TextEditingController _searchQueryController = TextEditingController();
  static const int _minSearchLenght = 5;
  bool _isLoading = true;
  String _searchQuery = "";
  List<Passage> _passageList = [];
  Map<String, List<SearchResult>?> _searchResults = {};
  List<bool> _expandedTitles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _showAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: _buildSearchField(),
        actions: _buildActions(),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Visibility(
                  visible: _searchResults.isEmpty && _searchQuery.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: Text(tr('no_results'))),
                  ),
                ),
                _createResultsView(),
              ],
            ),
          ),
          Visibility(
            visible: _isLoading,
            child: provideLoadingIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      cursorColor: Colors.white,
      controller: _searchQueryController,
      keyboardType: TextInputType.text,
      autofocus: false,
      decoration: InputDecoration(
        hintText: tr('type_to_search'),
        hintStyle: const TextStyle(color: Colors.white),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: (query) => _searchQuery = query.trim(),
      onSubmitted: (_) => _initSearch(),
    );
  }

  List<Widget> _buildActions() {
    return <Widget>[
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          _initSearch();
        },
      ),
    ];
  }

  void _showAll() async {
    if (_passageList.isEmpty) {
      _passageList = await loadAllPassages(context);
    }

    Map<String, List<SearchResult>> allResults = {};
    for (var i = 0; i < _passageList.length; i++) {
      final passage = _passageList[i];
      allResults.putIfAbsent(passage.title, () => []);
    }

    setState(() {
      _searchResults = allResults;
      _expandedTitles = List<bool>.filled(allResults.length, false);
      _isLoading = false;
    });
  }

  _showMessage(Object? msg, [Color? backgroundColor]) {
    backgroundColor ??= Colors.red[400];
    msg ??= tr('something_wrong');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Text(
          msg.toString(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _initSearch() async {
    _hideKeyboardAdnShowLoading();
    _buildSearchResults(_searchQuery)
        .then(
          (value) => setState(() {
            _searchResults = value;
            _expandedTitles = List<bool>.filled(value.length, true);
          }),
        )
        .onError((error, stackTrace) => _showMessage(error))
        .whenComplete(() => setState(() => _isLoading = false));
  }

  Map<int, String> _extractRows(
    String head,
    String searchQuery,
  ) {
    final Map<int, String> foundedLinesInHead = {};
    final lines = head.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final rowText = lines[i];
      if (rowText.contains(searchQuery)) {
        foundedLinesInHead.putIfAbsent(i, () => rowText);
      }
    }

    return foundedLinesInHead;
  }

  void _hideKeyboardAdnShowLoading() {
    FocusScope.of(context).requestFocus(FocusNode());
    setState(() => _isLoading = true);
  }

  Future<Map<String, List<SearchResult>>> _buildSearchResults(
      String searchQuery) async {
    if (searchQuery.length < _minSearchLenght) {
      return Future.error(
          tr('search_to_short').replaceAll('%s', _minSearchLenght.toString()));
    }

    if (_passageList.isEmpty) {
      _passageList = await loadAllPassages(context);
    }

    final Map<String, List<SearchResult>> results = {};

    for (var passage in _passageList) {
      final passageHeads = passage.heads;

      for (var headIndex = 0; headIndex < passageHeads.length; headIndex++) {
        final head = passageHeads[headIndex];

        if (head.toLowerCase().contains(searchQuery.toLowerCase())) {
          final Map<int, String> lineMap = _extractRows(head, searchQuery);
          final List<SearchResult> resultList = [];
          lineMap.forEach((key, value) {
            resultList.add(
              SearchResult(
                passageTitle: passage.title,
                headIndex: headIndex,
                rowNum: key,
                text: value,
              ),
            );
          });

          results.putIfAbsent(passage.title, () => resultList);
        }
      }
    }

    return results;
  }

  _goTo(int num, {int headIndex = 0}) async {
    await saveFileNum(num);
    await saveHeadIndex(headIndex);

    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  int _calculateNum(String item) {
    int result = -1;
    for (var i = 0; i < _passageList.length; i++) {
      if (_passageList[i].title == item) {
        result = (i + 1);
        break;
      }
    }

    return result;
  }

  _copyToClipboard(SearchResult result) {
    ClipboardManager.copyToClipBoard(result.prityPrint());
    _showMessage(tr('done'), Colors.green[400]);
  }

  Widget _createResultsView() {
    return ExpansionPanelList(
      elevation: 4,
      animationDuration: const Duration(seconds: 2),
      key: UniqueKey(),
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _expandedTitles[index] = !isExpanded;
        });
      },
      children: _searchResults.keys.map<ExpansionPanel>((String passageTitle) {
        int num = _calculateNum(passageTitle);
        int searchIndex = _searchResults.keys.toList().indexOf(passageTitle);
        List<SearchResult> results = _searchResults[passageTitle] ?? [];
        return ExpansionPanel(
          canTapOnHeader: true,
          isExpanded: _expandedTitles[searchIndex],
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              key: UniqueKey(),
              style: ListTileStyle.drawer,
              title: Text(passageTitle),
              trailing: InkWell(
                onTap: () => _goTo(num),
                child: Text(tr('go_to')),
              ),
            );
          },
          body: Column(
            key: UniqueKey(),
            children: [..._createResultList(num, results)],
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _createResultList(int num, List<SearchResult> results) => results
      .map(
        (result) => ListTile(
          key: UniqueKey(),
          title: Text(result.prityPrint()),
          subtitle: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _goTo(num, headIndex: result.headIndex),
                  child: Text(tr('go_to')),
                ),
                InkWell(
                  onTap: () => _copyToClipboard(result),
                  child: Text(tr('copy')),
                ),
              ],
            ),
          ),
        ),
      )
      .toList();
}
