import 'package:bulgarian.orthodox.bible/app/widgets/head_page.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('app_name')),
      ),
      body: const SafeArea(
        child: HeadPage(
          text: 'Implement me',
          custFontSize: 16.0,
        ),
      ),
    );
  }
}
