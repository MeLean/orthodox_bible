import 'dart:async';

import 'package:bulgarian.orthodox.bible/app/mixins/passage_manager.dart';

import '../../api/models/passage_response.dart';
import 'package:firebase_database/firebase_database.dart';

class PassagesRepo with PassageManager {
  Future<void> loadAndCachePassages(String localeCode) async {
    final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();
    final completer = Completer<void>();

    databaseReference.child(localeCode).once().then((DatabaseEvent event) async {
      if (event.snapshot.value != null) {
        var response = event.snapshot.value;

        if (response is List) {
          List<Map<String, dynamic>> filteredList =
              response.where((item) => item != null).map((item) => Map<String, dynamic>.from(item)).toList();

          final list = List<PassageRespose>.from(filteredList.map((model) => PassageRespose.fromMap(model)));

          await savePassagesLocaly(list, localeCode);
        } else {
          throw Exception("Error: ${response.runtimeType}!");
        }
        completer.complete();
      }
    }).catchError((error) {
      completer.completeError(error);
    });

    return completer.future;
  }
}
