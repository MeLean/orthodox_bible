import 'dart:convert';

import 'package:bulgarian.orthodox.bible/api/app_endpoints.dart';
import 'package:bulgarian.orthodox.bible/api/rest_client.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/passage_manager.dart';

import '../../api/models/passage_response.dart';

class PassagesRepo with PassageManager {
  Future<void> loadAndCachePassages() async {
    final response = await RestClient()
        .doGet(PassagesEndpoints.bgEndpoint, {'pageSize': '100'});

    Iterable iterable = json.decode(response);
    final list = List<PassageRespose>.from(
      iterable.map((model) => PassageRespose.fromMap(model)),
    );

    await savePassagesLocaly(list);
  }
}
