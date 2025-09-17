import 'dart:io';

import 'package:bulgarian.orthodox.bible/app/localization.dart';
import 'package:bulgarian.orthodox.bible/app/models/passage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../api/models/passage_response.dart';
import 'package:easy_localization/easy_localization.dart';

mixin PassageManager {
  static const String _pasageFolderName = 'passgaes';
  static const String _filePrefix = 'p_';

  static const int minFileNum = 1;

  Future<String> get _passagesFolderPath async {
    final directory = await getApplicationDocumentsDirectory();

    return '${directory.path}${Platform.pathSeparator}$_pasageFolderName';
  }

  int maxFileNum() {
    return int.tryParse(tr("max_file_num_str")) ?? 1;
  }

  Future<bool> arePassagesLoaded(String? cachedLanguageCode) async {
    if (cachedLanguageCode == null) {
      return false;
    }

    final fileName = await _createFileName(maxFileNum(), cachedLanguageCode);
    final result = File(fileName).exists();
    return result;
  }

  Future<void> savePassagesLocaly(List<PassageRespose> list, String localeCode) async {
    for (PassageRespose resposne in list) {
      _saveAsFile(resposne, localeCode);
    }
  }

  Future<Passage> loadPassage(BuildContext context, int fileNum, String languageCode) async {
    final passageJson = await File(await _createFileName(fileNum, languageCode)).readAsString();

    return Passage.fromJson(passageJson);
  }

  Future<List<Passage>> loadAllPassages(BuildContext context) async {
    List<Passage> result = [];
    int maxNum = maxFileNum();
    String appLocale = AppLocalization.getLanguageCode(context);

    for (int i = minFileNum; i <= maxNum; i++) {
      result.add(await loadPassage(context, i, appLocale));
    }

    return result;
  }

  Future<String> _createFileName(int maxFileNum, String localeCode) async {
    return '${await _passagesFolderPath}${Platform.pathSeparator}$localeCode$_filePrefix$maxFileNum.json';
  }

  void _saveAsFile(PassageRespose resposne, String localeCode) async {
    final name = await _createFileName(resposne.num, localeCode);
    final file = await File(name).create(recursive: true);

    file.writeAsString(Passage.fromResponse(resposne).toJson());
  }
}
