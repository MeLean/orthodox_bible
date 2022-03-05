import 'package:bulgarian.orthodox.bible/app/mixins/cache.dart';
import 'package:bulgarian.orthodox.bible/app/mixins/file_loader.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../app/mixins/loading.dart';
import '../../app/models/passage.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({Key? key}) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen>
    with PassageLoader, LoadingIndicatorProvider, AppCache {
  late bool _isLoading;
  List<Passage>? _passageList;

  @override
  void initState() {
    _isLoading = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      loadAllPhasses();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('app_name')),
      ),
      body: SafeArea(
        child: _isLoading ? getLoadingIndicator() : _createBody(),
      ),
    );
  }

  Widget _createBody() {
    int length = _passageList?.length ?? 0;

    return ListView.builder(
      itemCount: length,
      itemBuilder: (context, index) {
        return ListTile(
          onTap: () => _itemClicked(index),
          leading: Text(tr('go_to')),
          title: Text('${index + 1} ${_passageList![index].title}'),
        );
      },
    );
  }

  void loadAllPhasses() async {
    final loadedPassages = await loadAllPassages(context, '');
    setState(() {
      _passageList = loadedPassages;
      _isLoading = false;
    });
  }

  _itemClicked(int index) {
    Navigator.pop(context, index + 1);
  }
}
