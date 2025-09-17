import 'package:bulgarian.orthodox.bible/app/mixins/cache.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/passage_manager.dart';
import 'package:bulgarian.orthodox.bible/app/models/passage.dart';
import 'package:bulgarian.orthodox.bible/app/routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'head_picker_page.dart';

class HeadNavigatorScreen extends StatefulWidget {
  const HeadNavigatorScreen({Key? key}) : super(key: key);

  @override
  State<HeadNavigatorScreen> createState() => _HeadNavigatorScreenState();
}

class _HeadNavigatorScreenState extends State<HeadNavigatorScreen> with AppCache, PassageManager {
  bool _loading = true;
  final List<_HeadFileEntry> _files = [];
  // Remember the selected head per file (0-based index)
  final Map<int, int> _selectedHeadIndexByFile = {};

  @override
  void initState() {
    super.initState();
    // Load after first frame so localization/context are ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFiles());
  }

  Future<void> _loadFiles() async {
    try {
      final List<Passage> passages = await loadAllPassages(context);

      for (int i = 0; i < passages.length; i++) {
        final fileNum = PassageManager.minFileNum + i;
        final p = passages[i];

        // Each head is a String; preview is the first non-empty line
        final previews = <_HeadPreview>[];
        for (int h = 0; h < p.heads.length; h++) {
          final firstRow = p.heads[h].split('\n').first.trim();
          previews.add(
            _HeadPreview(index: h, firstRow: firstRow.isEmpty ? '—' : firstRow),
          );
        }

        _files.add(
          _HeadFileEntry(fileNum: fileNum, title: p.title, headPreviews: previews),
        );
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _files.clear();
        _loading = false;
      });
    }
  }

  Future<void> _open(int fileNum, int headIndex) async {
    await saveFileNum(fileNum);
    await saveHeadIndex(headIndex);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (r) => false);
  }

  Future<void> _pickAndOpenHeads({
    required String bookTitle,
    required int fileNum,
    required int headsCount,
  }) async {
    final picked = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => HeadPickerPage(
          bookTitle: bookTitle,
          headsCount: headsCount,
        ),
        fullscreenDialog: true,
      ),
    );

    if (picked != null && picked > 0 && picked <= headsCount) {
      final idx = picked - 1;
      setState(() => _selectedHeadIndexByFile[fileNum] = idx);
      await _open(fileNum, idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('navigate_by_head'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_files.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(tr('no_results'), textAlign: TextAlign.center),
                  ),
                )
              : ListView.separated(
                  itemCount: _files.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final f = _files[i];
                    final fileTitle = f.title.isNotEmpty ? f.title : '# ${f.fileNum}';
                    final headsCount = f.headPreviews.length;

                    return ListTile(
                      title: Text('${f.fileNum}. $fileTitle ($headsCount)'),
                      trailing: headsCount > 0
                          ? FilledButton.tonalIcon(
                              icon: const Icon(Icons.grid_view),
                              label: Text(tr('go_there')),
                              onPressed: () => _pickAndOpenHeads(
                                bookTitle: fileTitle,
                                fileNum: f.fileNum,
                                headsCount: headsCount,
                              ),
                            )
                          : null,
                      onTap: headsCount > 0
                          ? () => _pickAndOpenHeads(
                                bookTitle: fileTitle,
                                fileNum: f.fileNum,
                                headsCount: headsCount,
                              )
                          : null,
                    );
                  },
                )),
    );
  }
}

class _HeadFileEntry {
  final int fileNum;
  final String title;
  final List<_HeadPreview> headPreviews;

  _HeadFileEntry({
    required this.fileNum,
    required this.title,
    required this.headPreviews,
  });
}

class _HeadPreview {
  final int index;
  final String firstRow;

  _HeadPreview({required this.index, required this.firstRow});
}
