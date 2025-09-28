import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bulgarian.orthodox.bible/app/mixins/cache.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/passage_manager.dart';
import 'package:bulgarian.orthodox.bible/app/routes.dart';
import 'package:bulgarian.orthodox.bible/screens/search/search_result.dart';
import '../../app/models/passage.dart';
import 'search_details_screen.dart';

class SearchTextsScreen extends StatefulWidget {
  const SearchTextsScreen({Key? key}) : super(key: key);

  @override
  State<SearchTextsScreen> createState() => _SearchTextsScreenState();
}

class _SearchTextsScreenState extends State<SearchTextsScreen> with PassageManager, AppCache {
  // ---- config
  static const int _minSearchLenght = 3;
  static const String _kSearchHistoryKey = 'search_history_v1';
  static const int _kHistoryCap = 10;

  // ---- controllers/state
  final TextEditingController _searchQueryController = TextEditingController();
  bool _isLoading = false;

  /// Whether the user has attempted a search in this session
  bool _hasSearched = false;

  String _searchQuery = "";
  List<Passage> _passageList = []; // lazy-loaded only on demand
  Map<String, List<SearchResult>?> _searchResults = {};
  List<bool> _expandedTitles = [];
  List<String> _history = const [];

  @override
  void initState() {
    super.initState();
    // Load only history on first frame; do NOT load passages or results.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadHistory();
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchQueryController.dispose();
    super.dispose();
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: _buildSearchField(),
        actions: _buildActions(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 🔹 Non-blocking loading bar (keeps results visible)
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0),
              secondChild: const LinearProgressIndicator(minHeight: 2),
              crossFadeState: _isLoading ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- history block
                    Text(tr('recent_searches'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_history.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(tr('no_results'), style: Theme.of(context).textTheme.bodyMedium),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _history
                            .map(
                              (q) => InputChip(
                                label: Text(q),
                                onPressed: () => _onHistoryTap(q, runNow: true),
                              ),
                            )
                            .toList(),
                      ),

                    const SizedBox(height: 12),

                    if (_hasSearched) ...[
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const SizedBox.shrink()
                      else if (_searchResults.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: Text(tr('no_results'))),
                        )
                      else
                        _createResultsView(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchQueryController,
      keyboardType: TextInputType.text,
      autofocus: false,
      decoration: InputDecoration(
        hintText: tr('type_to_search'),
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.tertiary),
        border: InputBorder.none,
      ),
      onChanged: (query) => _searchQuery = query.trim(),
      onSubmitted: (_) => _commitSearch(),
      textInputAction: TextInputAction.search,
    );
  }

  List<Widget> _buildActions() {
    return <Widget>[
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: _commitSearch,
        tooltip: tr('search'),
      ),
      PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'clear') _clearHistory();
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'clear',
            child: Text(tr('clear')),
          ),
        ],
      ),
    ];
  }

  // ==================== History ====================

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_kSearchHistoryKey) ?? <String>[];
    _history = List.unmodifiable(saved);
  }

  Future<void> _saveHistory(List<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kSearchHistoryKey, items);
  }

  Future<void> _addToHistory(String query) async {
    if (query.isEmpty) return;
    final list = List<String>.from(_history);
    // de-dup (case-insensitive), move to front
    list.removeWhere((e) => e.toLowerCase() == query.toLowerCase());
    list.insert(0, query);
    if (list.length > _kHistoryCap) list.removeRange(_kHistoryCap, list.length);
    await _saveHistory(list);
    if (!mounted) return;
    setState(() => _history = List.unmodifiable(list));
  }

  Future<void> _clearHistory() async {
    await _saveHistory(<String>[]);
    if (!mounted) return;
    setState(() => _history = const []);
  }

  void _onHistoryTap(String q, {bool runNow = false}) {
    _searchQueryController.text = q;
    _searchQuery = q;
    HapticFeedback.selectionClick();
    if (runNow) _commitSearch();
  }

  // ==================== Search ====================

  void _commitSearch() async {
    // Hide the keyboard first
    FocusScope.of(context).unfocus();

    final q = _searchQuery.trim();
    if (q.length < _minSearchLenght) {
      _showMessage(tr('search_to_short').replaceAll('%s', _minSearchLenght.toString()));
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true; // ensure results area appears
    });

    try {
      await _addToHistory(q);
      final value = await _buildSearchResults(q);
      if (!mounted) return;
      setState(() {
        _searchResults = value;
        _expandedTitles = List<bool>.filled(value.length, true);
      });
    } catch (e) {
      _showMessage(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, List<SearchResult>>> _buildSearchResults(String searchQuery) async {
    if (_passageList.isEmpty) {
      // Lazy-load passages only when a search is executed
      _passageList = await loadAllPassages(context);
    }

    final Map<String, List<SearchResult>> results = {};
    for (var passage in _passageList) {
      final passageHeads = passage.heads;
      for (var headIndex = 0; headIndex < passageHeads.length; headIndex++) {
        final head = passageHeads[headIndex];
        if (head.containsIcnoreCase(searchQuery)) {
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

  Map<int, String> _extractRows(String head, String searchQuery) {
    final Map<int, String> foundedLinesInHead = {};
    final lines = head.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final rowText = lines[i];
      if (rowText.containsIcnoreCase(searchQuery)) {
        foundedLinesInHead.putIfAbsent(i, () => rowText);
      }
    }
    return foundedLinesInHead;
  }

  // ==================== Navigation + helpers ====================

  void _openDetails(Passage passage, int headIndex) {
    Navigator.of(context).pushNamed(
      AppRoutes.searchDetails,
      arguments: SearchDetailsArgs(passage: passage, headIndex: headIndex),
    );
  }

  int _calculateNum(String item) {
    for (var i = 0; i < _passageList.length; i++) {
      if (_passageList[i].title == item) {
        return (i + 1);
      }
    }
    return -1;
  }

  _copyToClipboard(SearchResult result) {
    final toCopy = result.prityPrint();
    Clipboard.setData(ClipboardData(text: toCopy));
    _showMessage(tr('done'), Colors.green[400]);
  }

  Widget _createResultsView() {
    if (_searchResults.isEmpty) return const SizedBox.shrink();

    return ExpansionPanelList(
      elevation: 4,
      animationDuration: const Duration(milliseconds: 300),
      key: UniqueKey(),
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _expandedTitles[index] = !isExpanded;
        });
      },
      children: _searchResults.keys.map<ExpansionPanel>((String passageTitle) {
        final num = _calculateNum(passageTitle);
        final searchIndex = _searchResults.keys.toList().indexOf(passageTitle);
        final results = _searchResults[passageTitle] ?? [];
        return ExpansionPanel(
          canTapOnHeader: true,
          isExpanded: _expandedTitles[searchIndex],
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              key: UniqueKey(),
              style: ListTileStyle.drawer,
              title: Text(passageTitle),
              trailing: InkWell(
                onTap: () {
                  final passage = _passageList[num - 1];
                  _openDetails(passage, 0);
                },
                child: Text(tr('go_there')),
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
                  onTap: () {
                    final passage = _passageList[num - 1];
                    _openDetails(passage, 0);
                  },
                  child: Text(tr('go_there')),
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

  void _showMessage(Object? msg, [Color? backgroundColor]) {
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
}

extension ContainsIgnoreCase on String {
  bool containsIcnoreCase(String text) {
    return toLowerCase().contains(text.toLowerCase());
  }
}
