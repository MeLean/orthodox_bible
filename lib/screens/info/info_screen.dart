import 'package:bulgarian.orthodox.bible/app/widgets/head_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:package_info_plus/package_info_plus.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('app_name')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              HeadPage(
                text: tr('info'),
                custFontSize: 16.0,
              ),
              FutureBuilder(
                future: getVersion(),
                builder: (ctx, snapshot) {
                  return SelectableText(
                    snapshot.data?.toString() ?? '',
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String debug = kDebugMode ? " - debug" : "";
    return "${packageInfo.version}$debug";
  }
}
