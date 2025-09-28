import 'package:bulgarian.orthodox.bible/app/mixins/cache.dart';
import 'package:bulgarian.orthodox.bible/app/widgets/head_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/localization.dart';
import '../../app/routes.dart';
import '../../app/widgets/app_locale_picker.dart';

class InfoScreen extends StatelessWidget with AppCache {
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
              AppLocalePicker(
                  supportedLocales: AppLocalization.getSupprotedLanguageCodes(),
                  localePickedCallback: (String languageCode) {
                    _setLocaleAndLoadPassages(languageCode, context);
                  }),
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

  void _setLocaleAndLoadPassages(String languageCode, BuildContext context) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await saveLanguageCode(languageCode);
      await saveFileNum(1);
      await saveHeadIndex(0);

      if (!context.mounted) return; // Prevents navigation on an unmounted widget

      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.splash, (route) => false);
    });
  }
}
