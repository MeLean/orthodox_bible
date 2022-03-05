import 'package:bulgarian.orthodox.bible/app/widgets/head_page.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('app_name')),
      ),
      body: SafeArea(
        child: HeadPage(
          text: tr('info'),
          custFontSize: 16.0,
        ),
      ),
    );
  }
}
