import 'dart:io';

import 'package:bulgarian.orthodox.bible/app/models/passage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../api/models/passage_response.dart';

mixin PassageManager {
  static const String _pasageFolderName = 'passgaes';
  static const String _filePrefix = 'p_';
  static const int maxFileNum = 77;
  static const int minFileNum = 1;

  Future<String> get _passagesFolderPath async {
    final directory = await getApplicationDocumentsDirectory();

    return '${directory.path}${Platform.pathSeparator}$_pasageFolderName';
  }

  Future<bool> arePassagesLoaded() async =>
      File(await _createFileName(maxFileNum)).exists();

  Future<void> savePassagesLocaly(List<PassageRespose> list) async {
    for (PassageRespose resposne in list) {
      _saveAsFile(resposne);
    }
  }

  Future<Passage> loadPassage(
    BuildContext context,
    int fileNum,
  ) async {
    final passageJson =
        await File(await _createFileName(fileNum)).readAsString();

    return Passage.fromJson(passageJson);
  }

  Future<List<Passage>> loadAllPassages(BuildContext context) async {
    List<Passage> result = [];

    for (int i = minFileNum; i <= maxFileNum; i++) {
      result.add(await loadPassage(context, i));
    }

    return result;
  }

  Future<String> _createFileName(int maxFileNum) async {
    return '${await _passagesFolderPath}${Platform.pathSeparator}$_filePrefix$maxFileNum.json';
  }

  void _saveAsFile(PassageRespose resposne) async {
    final name = await _createFileName(resposne.num);
    final file = await File(name).create(recursive: true);

    file.writeAsString(Passage.fromResponse(resposne).toJson());
  }
}
