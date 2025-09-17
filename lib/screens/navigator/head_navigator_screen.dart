import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/localization.dart';
import '../../app/mixins/cache.dart';
import '../../app/routes.dart';

class HeadNavigatorScreen extends StatefulWidget {
  const HeadNavigatorScreen({Key? key}) : super(key: key);

  @override
  State<HeadNavigatorScreen> createState() => _HeadNavigatorScreenState();
}

class _HeadNavigatorScreenState extends State<HeadNavigatorScreen> with AppCache {
  static const String _passagesFolderName = 'passgaes'; // matches PassageManager
  static const String _filePrefix = 'p_'; // matches PassageManager

  bool _loading = true;
  List<_HeadFileEntry> _files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      // Determine locale code (match existing app behavior)
      final localeCode = AppLocalization.getCurrentLanguageCode(context);

      // Locate the folder used for cached passages
      final docs = await getApplicationDocumentsDirectory();
      final folder = Directory('${docs.path}${Platform.pathSeparator}$_passagesFolderName');

      if (!await folder.exists()) {
        setState(() {
          _files = [];
          _loading = false;
        });
        return;
      }

      final regex = RegExp('^${RegExp.escape(localeCode)}$_filePrefix(\\d+)\\.json\$');
      final entries = <_HeadFileEntry>[];

      // Scan files and parse minimal JSON (title + heads length)
      await for (final ent in folder.list(recursive: false, followLinks: false)) {
        if (ent is File) {
          final name = ent.uri.pathSegments.isNotEmpty ? ent.uri.pathSegments.last : '';
          final m = regex.firstMatch(name);
          if (m != null) {
            final numStr = m.group(1);
            final fileNum = int.tryParse(numStr ?? '');
            if (fileNum != null) {
              String? title;
              int? headsCount;
              try {
                final raw = await ent.readAsString();
                final map = json.decode(raw);
                if (map is Map<String, dynamic>) {
                  title = map['title'] is String ? map['title'] as String : null;
                  if (map['heads'] is List) {
                    headsCount = (map['heads'] as List).length;
                  }
                }
              } catch (_) {
                // If parsing fails, we still show the file number
              }
              entries.add(_HeadFileEntry(fileNum: fileNum, title: title, headsCount: headsCount));
            }
          }
        }
      }

      entries.sort((a, b) => a.fileNum.compareTo(b.fileNum));
      if (!mounted) return;
      setState(() {
        _files = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _files = [];
        _loading = false;
      });
    }
  }

  Future<void> _openFile(int fileNum, {int headIndex = 0}) async {
    await saveFileNum(fileNum);
    await saveHeadIndex(headIndex);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final titleText = tr('navigate_by_head');

    return Scaffold(
      appBar: AppBar(title: Text(titleText)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      tr('no_passages_found'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: _files.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final f = _files[i];
                    final subtitle =
                        f.headsCount == null ? tr('tap_to_open') : tr('heads_count', args: ['${f.headsCount}']);
                    final title = f.title?.isNotEmpty == true ? f.title! : tr('file_n', args: ['${f.fileNum}']);
                    return ListTile(
                      title: Text(title),
                      subtitle: Text(subtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openFile(f.fileNum),
                    );
                  },
                ),
    );
  }
}

class _HeadFileEntry {
  final int fileNum;
  final String? title;
  final int? headsCount;

  _HeadFileEntry({required this.fileNum, this.title, this.headsCount});
}
