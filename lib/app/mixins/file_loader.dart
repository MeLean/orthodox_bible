import 'dart:convert';

import 'package:bulgarian.orthodox.bible/app/models/passage.dart';
import 'package:flutter/material.dart';

mixin PassageLoader {
  static const int maxFileNum = 77;
  static const int minFileNum = 1;

  Future<Passage> loadPassage(
    BuildContext context,
    int fileNum,
  ) async {
    final passageJson = await DefaultAssetBundle.of(context)
        .loadString('assets/json/passages/p_$fileNum.json');

    return Passage.fromJson(passageJson);
  }

  Future<List<Passage>> loadAllPassages(BuildContext context) async {
    List<Passage> result = [];

    for (int i = minFileNum; i <= maxFileNum; i++) {
      result.add(await loadPassage(context, i));
    }

    return result;
  }
}
