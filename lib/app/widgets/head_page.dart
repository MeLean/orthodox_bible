import 'package:flutter/cupertino.dart';

class HeadPage extends StatelessWidget {
  const HeadPage({
    Key? key,
    required this.text,
    required double custFontSize,
  })  : _custFontSize = custFontSize,
        super(key: key);

  final String? text;
  final double _custFontSize;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Text(
                text ?? '',
                textAlign: TextAlign.start,
                style: TextStyle(fontSize: _custFontSize),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
