import 'dart:convert';

import 'package:bulgarian.orthodox.bible/app/models/passage.dart';
import 'package:flutter/material.dart';

mixin PassageLoader {
  Future<Passage> loadPassage(
    BuildContext context,
    String locale,
    int fileNum,
  ) async {
    final passageJson = await DefaultAssetBundle.of(context)
        .loadString('assets/json/$locale/p_$fileNum.json');

    return Passage.fromJson(passageJson);
  }

  Future<List<Passage>> loadAllPassages(
    BuildContext context,
    String locale,
  ) async {
    final assetsBundle = DefaultAssetBundle.of(context);
    final assetsJson = await assetsBundle.loadString('AssetManifest.json');
    final allPassagesFileNames = json
        .decode(assetsJson)
        .keys
        .where((String key) => key.startsWith('assets/json/$locale'));

    List<Passage> result = [];

    for (var passageFileName in allPassagesFileNames) {
      final passageJson = await assetsBundle.loadString(passageFileName);
      result.add(Passage.fromJson(passageJson));
    }

    return result;
  }
}
